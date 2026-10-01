// Glue between Swift (JavaScriptCore) and marked + highlight.js. resolveImage is injected by Swift.
const escapeHtml = text => text.replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' })[c]);

const slugify = text => text.toLowerCase().replace(/<[^>]+>/g, '').replace(/[^\p{L}\p{N}\s-]/gu, '').trim().replace(/\s/g, '-');

function highlightCode(code, language) {
  if (uniscriptLanguages.has(language)) return uniscriptHtml(code);
  if (language && hljs.getLanguage(language)) return hljs.highlight(code, { language, ignoreIllegals: true }).value;
  return escapeHtml(code);
}

marked.use({
  gfm: true,
  renderer: {
    code({ text, lang }) {
      const language = (lang || '').trim().split(/\s+/)[0];
      return `<pre><code class="hljs language-${escapeHtml(language)}">${highlightCode(text, language)}</code></pre>\n`;
    },
    heading({ tokens, depth }) {
      const html = this.parser.parseInline(tokens);
      return `<h${depth} id="${slugify(html)}">${html}</h${depth}>\n`;
    },
  },
});

// Uniscript (<:alpha> → α, \:infinity → ∞) in prose of files that opt in by starting with the marker "<:",
// and in code blocks of the languages that have it built in, in every file. Other code spans and code blocks never
// reach inline extensions. convertUniscript is injected by Swift.
const uniscriptMarker = '<:';
const uniscriptLanguages = new Set(['wasp', 'warp']);
const uniscriptElementStart = /<:|\\:/;
const uniscriptTag = /^\\:[A-Za-z0-9_-]*|^<:[^>]*>|^<:/;
const uniscriptBlockOpener = /^<:[^\/>][^>]*>$/;
const uniscriptBlockCloser = /<:(\/[^>]*)?>/;
let uniscriptEnabled = false;

// One tag, or a whole block `<:greek> a b <:/greek>`: an opener converts to nothing and runs to its closer
function uniscriptElement(src) {
  const tag = uniscriptTag.exec(src)[0];
  if (!uniscriptBlockOpener.test(tag) || convertUniscript(tag).html !== '') return tag;
  const closer = uniscriptBlockCloser.exec(src.slice(tag.length));
  return closer ? src.slice(0, tag.length + closer.index + closer[0].length) : src;
}

const uniscriptMarkedHtml = (className, message, html) => `<span class="${className}" title="${escapeHtml(message)}">${html}</span>`;
const uniscriptMarked = (className, message, text) => uniscriptMarkedHtml(className, message, escapeHtml(text));

// an unknown entity stays visible as written, an unsupported character plain; both marked, the message as tooltip.
// html carries meta (<:color red 𓀀>) as CSS spans
function uniscriptElementHtml(raw) {
  const { html, error, warning } = convertUniscript(raw);
  return error !== undefined ? uniscriptMarked('uniscript-error', error, raw)
    : warning !== undefined ? uniscriptMarkedHtml('uniscript-warning', warning, html) : html;
}

// Every uniscript element of a plain text converted, the rest escaped
function uniscriptHtml(text) {
  let html = '';
  for (let rest = text; rest; ) {
    const start = rest.match(uniscriptElementStart)?.index ?? rest.length;
    html += escapeHtml(rest.slice(0, start));
    rest = rest.slice(start);
    if (!rest) break;
    const raw = uniscriptElement(rest);
    html += uniscriptElementHtml(raw);
    rest = rest.slice(raw.length);
  }
  return html;
}

const uniscriptExtension = {
  name: 'uniscript',
  level: 'inline',
  start: src => uniscriptEnabled ? src.match(uniscriptElementStart)?.index : undefined,
  tokenizer(src) {
    if (uniscriptEnabled && uniscriptTag.test(src)) return { type: 'uniscript', raw: uniscriptElement(src) };
  },
  renderer: ({ raw }) => uniscriptElementHtml(raw),
};
marked.use({ extensions: [uniscriptExtension] });

// [[page]], [[dir/page.md]], [[page#heading]], [[page|label]]: a relative link, ".md" implied when the page has no extension
const wikiLink = /^\[\[([^\]|#]+)(#[^\]|]*)?(?:\|([^\]]+))?\]\]/;
const withMarkdownExtension = page => /\.[A-Za-z0-9]+$/.test(page) ? page : `${page}.md`;
marked.use({ extensions: [{
  name: 'wikiLink',
  level: 'inline',
  start: src => src.indexOf('[['),
  tokenizer(src) {
    const match = wikiLink.exec(src);
    if (!match) return;
    const [raw, page, heading = '', label] = match;
    return { type: 'wikiLink', raw, href: encodeURI(withMarkdownExtension(page.trim())) + heading, text: label ?? page + heading };
  },
  renderer: ({ href, text }) => `<a href="${escapeHtml(href)}">${escapeHtml(text.trim())}</a>`,
}] });

// WebKit measures every ideograph of a line on its own, as a possible line break; a composed ideographic description
// sequence (⿰讠尤) then keeps an em per component and leaves a wide gap behind it, unless it is kept in one piece
const descriptionSequence = /[\u2FF0-\u2FFF][\u2E80-\u2FFF\u3000-\u9FFF\uF900-\uFAFF\u{20000}-\u{3FFFF}]*/gu;
const textBetweenTags = />[^<]+</g;
const keepDescriptionSequencesTogether = html => html.replace(textBetweenTags,
  text => text.replace(descriptionSequence, sequence => `<span class="description-sequence">${sequence}</span>`));

const inlineImageSources = html =>
  html.replace(/(<img\b[^>]*?\bsrc=")([^"]*)(")/gi, (match, before, source, after) => before + resolveImage(source) + after);

// hasUniscriptHeader: Swift removed a leading uniscript header, which switches uniscript on
function renderMarkdown(source, hasUniscriptHeader = false, versionWarning = null) {
  uniscriptEnabled = hasUniscriptHeader || source.startsWith(uniscriptMarker);
  const warning = versionWarning ? `<p>${uniscriptMarked('uniscript-warning', versionWarning, versionWarning)}</p>\n` : '';
  return warning + keepDescriptionSequencesTogether(inlineImageSources(marked.parse(source)));
}
