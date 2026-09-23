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

const inlineImageSources = html =>
  html.replace(/(<img\b[^>]*?\bsrc=")([^"]*)(")/gi, (match, before, source, after) => before + resolveImage(source) + after);

function renderMarkdown(source) {
  return inlineImageSources(marked.parse(source));
}
