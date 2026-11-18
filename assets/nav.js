/* Each tab is a view, not a section you scroll past. The Index needs the full
   height of the window for its filter rail, and the Alt Path is an argument in
   its own right rather than the tail of the Primer, so it gets its own screen.
   Hash-driven, so existing links and bookmarks still land where they did. */
var VIEW_OF = { primer: 'overview', alternative: 'alternative', scorecard: 'scorecard', index: 'movement' };
function setView(view, scrollTo) {
  document.querySelectorAll('[data-screen]').forEach(function (s) {
    s.classList.toggle('view-on', s.getAttribute('data-screen') === view);
  });
  document.querySelectorAll('#nav-links a').forEach(function (a) {
    var t = (a.getAttribute('href') || '').slice(1);
    a.classList.toggle('active', VIEW_OF[t] === view);
  });
  if (scrollTo) {
    var el = document.getElementById(scrollTo);
    if (el) el.scrollIntoView({ behavior: 'smooth', block: 'start' });
  } else { window.scrollTo(0, 0); }
}
function viewFromHash() {
  var h = (location.hash || '').slice(1);
  var v = VIEW_OF[h] || 'overview';
  setView(v, (h && v === 'overview') ? h : null);
}
window.addEventListener('hashchange', viewFromHash);
document.addEventListener('DOMContentLoaded', viewFromHash);

function toggleNav(btn) {
  const links = document.getElementById('nav-links');
  const isOpen = btn.classList.toggle('open');
  links.classList.toggle('open');
  btn.setAttribute('aria-expanded', isOpen);
}
document.addEventListener('DOMContentLoaded', () => {
  document.querySelectorAll('#nav-links a').forEach(a => {
    a.addEventListener('click', () => {
      const btn = document.querySelector('.nav-toggle');
      const links = document.getElementById('nav-links');
      if (btn && btn.classList.contains('open')) {
        btn.classList.remove('open');
        links.classList.remove('open');
        btn.setAttribute('aria-expanded', 'false');
      }
    });
  });
});
