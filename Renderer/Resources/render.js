// Glue between Swift (JavaScriptCore) and marked + highlight.js. resolveImage is injected by Swift.
const escapeHtml = text => text.replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' })[c]);

const slugify = text => text.toLowerCase().replace(/<[^>]+>/g, '').replace(/[^\p{L}\p{N}\s-]/gu, '').trim().replace(/\s/g, '-');

function highlightCode(code, language) {
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

// Uniscript (<:alpha> → α, \:infinity → ∞) in prose of files that opt in by starting with the marker "<:".
// Code spans and code blocks never reach inline extensions. convertUniscript is injected by Swift.
const uniscriptMarker = '<:';
const uniscriptElementStart = /<:|\\:/;
const uniscriptTag = /^\\:[A-Za-z0-9_-]*|^<:[^>]*>|^<:/;
const uniscriptBlockOpener = /^<:[^\/>][^>]*>$/;
const uniscriptBlockCloser = /<:(\/[^>]*)?>/;
let uniscriptEnabled = false;

// One tag, or a whole block `<:greek> a b <:/greek>`: an opener converts to nothing and runs to its closer
function uniscriptElement(src) {
  const tag = uniscriptTag.exec(src)[0];
  if (!uniscriptBlockOpener.test(tag) || convertUniscript(tag).text !== '') return tag;
  const closer = uniscriptBlockCloser.exec(src.slice(tag.length));
  return closer ? src.slice(0, tag.length + closer.index + closer[0].length) : src;
}

const uniscriptMarked = (className, message, text) => `<span class="${className}" title="${escapeHtml(message)}">${escapeHtml(text)}</span>`;

const uniscriptExtension = {
  name: 'uniscript',
  level: 'inline',
  start: src => uniscriptEnabled ? src.match(uniscriptElementStart)?.index : undefined,
  tokenizer(src) {
    if (!uniscriptEnabled || !uniscriptTag.test(src)) return;
    const raw = uniscriptElement(src);
    return { type: 'uniscript', raw, converted: convertUniscript(raw) };
  },
  // an unknown entity stays visible as written, an unsupported character plain; both marked, the message as tooltip
  renderer: ({ raw, converted: { text, error, warning } }) =>
    error !== undefined ? uniscriptMarked('uniscript-error', error, raw)
      : warning !== undefined ? uniscriptMarked('uniscript-warning', warning, text) : escapeHtml(text),
};
marked.use({ extensions: [uniscriptExtension] });

const inlineImageSources = html =>
  html.replace(/(<img\b[^>]*?\bsrc=")([^"]*)(")/gi, (match, before, source, after) => before + resolveImage(source) + after);

function renderMarkdown(source) {
  uniscriptEnabled = source.startsWith(uniscriptMarker);
  return inlineImageSources(marked.parse(source));
}
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

