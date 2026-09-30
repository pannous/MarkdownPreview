// Collapsible heading sections. foldDeepest() collapses every visible section of the deepest still-open level,
// unfoldShallowest() reopens the shallowest collapsed level; clicking a heading toggles just that section.
// Folds are remembered by heading id so they survive live reloads (call refreshFolds() after swapping the content).
(() => {
  const collapsedKeys = new Set();
  const content = () => document.getElementById('content');
  const headingLevel = element => (/^H([1-6])$/.exec(element.tagName) || [])[1] | 0;
  const foldKey = heading => heading.id || heading.textContent;
  const isCollapsed = heading => collapsedKeys.has(foldKey(heading));
  const headings = () => [...content().children].filter(headingLevel);
  const tableOfContents = document.createElement('details');
  tableOfContents.id = 'table-of-contents';
  const summary = document.createElement('summary');
  summary.textContent = 'Contents';
  const navigation = document.createElement('nav');
  navigation.setAttribute('aria-label', 'Table of contents');
  tableOfContents.append(summary, navigation);
  document.body.appendChild(tableOfContents);

  const style = document.createElement('style');
  style.textContent = `
    .folded-away { display: none !important; }
    .foldable { cursor: pointer; position: relative; }
    .foldable::before { content: '▾'; position: absolute; left: -1.1em; width: 1em; color: var(--muted, gray); font-size: 0.8em; line-height: 1.6; }
    .foldable.collapsed::before { content: '▸'; }
    .foldable.collapsed::after { content: ' …'; color: var(--muted, gray); font-weight: normal; }`;
  document.head.appendChild(style);

  // One pass over the top-level blocks: a heading is foldable when anything follows it before the next heading
  // of the same or a higher level; blocks below a collapsed heading are hidden.
  function refreshFolds() {
    const openHeadings = [];
    for (const element of content().children) {
      const level = headingLevel(element);
      while (level && openHeadings.length && headingLevel(openHeadings.at(-1)) >= level) openHeadings.pop();
      openHeadings.forEach(heading => heading.classList.add('foldable'));
      element.classList.toggle('folded-away', openHeadings.some(isCollapsed));
      if (level) {
        element.classList.remove('foldable');
        element.classList.toggle('collapsed', isCollapsed(element));
        openHeadings.push(element);
      }
    }
    refreshTableOfContents();
  }

  const visibleFoldable = () => headings().filter(h => h.classList.contains('foldable') && !h.classList.contains('folded-away'));

  function revealHeading(target) {
    const ancestors = [];
    for (const heading of headings()) {
      while (ancestors.length && headingLevel(ancestors.at(-1)) >= headingLevel(heading)) ancestors.pop();
      ancestors.push(heading);
      if (heading === target) break;
    }
    ancestors.forEach(heading => setCollapsed(heading, false));
    refreshFolds();
    target.setAttribute('tabindex', '-1');
    target.focus({ preventScroll: true });
    target.scrollIntoView({ block: 'start' });
  }

  function refreshTableOfContents() {
    const documentHeadings = headings();
    const firstLevel = Math.min(...documentHeadings.map(headingLevel));
    tableOfContents.hidden = !documentHeadings.length;
    navigation.replaceChildren(...documentHeadings.map(heading => {
      const link = document.createElement('a');
      link.textContent = heading.textContent;
      link.href = `#${encodeURIComponent(heading.id)}`;
      link.style.setProperty('--heading-depth', headingLevel(heading) - firstLevel);
      link.addEventListener('click', event => {
        event.preventDefault();
        revealHeading(heading);
      });
      return link;
    }));
  }

  function setCollapsed(heading, collapsed) {
    collapsed ? collapsedKeys.add(foldKey(heading)) : collapsedKeys.delete(foldKey(heading));
  }

  function foldLevel(pickLevel, isCandidate, collapse) {
    const candidates = visibleFoldable().filter(isCandidate);
    if (!candidates.length) return;
    const level = pickLevel(...candidates.map(headingLevel));
    for (const heading of candidates) if (headingLevel(heading) === level) setCollapsed(heading, collapse);
    refreshFolds();
  }

  window.foldDeepest = () => foldLevel(Math.max, h => !isCollapsed(h), true);
  window.unfoldShallowest = () => foldLevel(Math.min, isCollapsed, false);
  window.refreshFolds = refreshFolds;

  document.addEventListener('click', event => {
    const heading = event.target.closest('.foldable');
    if (!heading || event.target.closest('a')) return;
    setCollapsed(heading, !isCollapsed(heading));
    refreshFolds();
  });

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', refreshFolds);
  else refreshFolds();
})();
