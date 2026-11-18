/* ═══════════════════════════════════════════════
   SITE CHROME — counters, scorecard, reveal, bars
   ═══════════════════════════════════════════════ */
(function () {
  'use strict';

  var reduceMotion = window.matchMedia &&
    window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  // ── COUNTERS ──────────────────────────────────────────────
  function countTo(id, target) {
    var el = document.getElementById(id);
    if (!el) return;
    if (reduceMotion) { el.textContent = target; return; }
    var v = 0, step = target / 40;
    var t = setInterval(function () {
      v = Math.min(v + step, target);
      el.textContent = Math.round(v);
      if (v >= target) clearInterval(t);
    }, 20);
  }

  // ── BAR ANIMATION ─────────────────────────────────────────
  function animateBars() {
    document.querySelectorAll('.bar-fill[data-w]').forEach(function (bar) {
      bar.style.width = bar.dataset.w;
    });
  }

  // ── SCORECARD (computed from the record set) ──────────────
  function buildScorecard(entries) {
    var scored = entries.filter(function (e) { return e.enacted; });
    var policy = scored.filter(function (e) { return e.level === 'federal' || e.level === 'state'; });
    var pick = function (lvl, stance) {
      return scored.filter(function (e) { return e.level === lvl && e.stance === stance; });
    };
    var fedAdv = pick('federal', 'advancing'), fedOpp = pick('federal', 'opposing');
    var stAdv  = pick('state',   'advancing'), stOpp  = pick('state',   'opposing');

    var isB = function (e) { return !!e.bipartisan; };
    var isD = function (e) { return e.actorD && !e.actorR && !isB(e); };
    var isR = function (e) { return e.actorR && !e.actorD && !isB(e); };
    var n   = function (arr, fn) { return arr.filter(fn).length; };
    var gov = function (arr, p) { return arr.filter(function (e) { return e.govParty === p; }).length; };

    var fAdvD = n(fedAdv, isD), fAdvR = n(fedAdv, isR), fAdvB = n(fedAdv, isB);
    var fOppR = n(fedOpp, isR), fOppD = n(fedOpp, isD);
    var sAdvD = gov(stAdv, 'D'), sAdvR = gov(stAdv, 'R');
    var sOppR = gov(stOpp, 'R'), sOppD = gov(stOpp, 'D');

    countTo('st-adv', fedAdv.length + stAdv.length);
    countTo('st-opp', fedOpp.length + stOpp.length);
    countTo('st-bip', n(policy, isB));

    function bar(label, cls, count, total) {
      if (!count || !total) return '';
      var pct = Math.round(count / total * 100);
      return '<div class="bar-wrap">' +
               '<div class="bar-lbl">' +
                 '<span class="bar-name ' + cls + '">' + label + '</span>' +
                 '<span class="bar-count">' + count + ' ' + (count === 1 ? 'action' : 'actions') + '</span>' +
               '</div>' +
               '<div class="bar-track"><div class="bar-fill ' + cls + '" data-w="' + pct + '%" style="width:0"></div></div>' +
             '</div>';
    }

    var sep = '<p class="bar-level-lbl" style="margin-top:1.2rem">State</p>';
    var adv = document.getElementById('bars-adv');
    var opp = document.getElementById('bars-opp');
    if (adv) {
      adv.innerHTML = '<p class="bar-level-lbl">Federal</p>' +
        bar('Democratic Administration', 'd', fAdvD, fedAdv.length) +
        bar('Republican Administration', 'r', fAdvR, fedAdv.length) +
        bar('Bipartisan / Transition',   'b', fAdvB, fedAdv.length) +
        sep +
        bar('Democratic Governor', 'd', sAdvD, stAdv.length) +
        bar('Republican Governor', 'r', sAdvR, stAdv.length);
    }
    if (opp) {
      opp.innerHTML = '<p class="bar-level-lbl">Federal</p>' +
        bar('Republican Administration', 'r', fOppR, fedOpp.length) +
        bar('Democratic Administration', 'd', fOppD, fedOpp.length) +
        sep +
        bar('Republican Governor', 'r', sOppR, stOpp.length) +
        bar('Democratic Governor', 'd', sOppD, stOpp.length);
    }
    requestAnimationFrame(animateBars);
  }

  // ── HERO STAGGER ──────────────────────────────────────────
  window.addEventListener('load', function () {
    if (reduceMotion) return;
    ['.hero-eyebrow', '.hero-h1', '.hero-sub', '.hero-note', '.hero-visual']
      .map(function (s) { return document.querySelector(s); })
      .filter(Boolean)
      .forEach(function (el, i) {
        el.style.opacity = '0';
        el.style.transform = 'translateY(18px)';
        el.style.transition = 'opacity .7s ease ' + (i * 0.13) + 's, transform .7s ease ' + (i * 0.13) + 's';
        requestAnimationFrame(function () {
          setTimeout(function () { el.style.opacity = '1'; el.style.transform = 'translateY(0)'; }, 80);
        });
      });
  });

  // ── SCROLL REVEAL ─────────────────────────────────────────
  var revealObs = new IntersectionObserver(function (entries) {
    entries.forEach(function (e, i) {
      if (e.isIntersecting) {
        setTimeout(function () { e.target.classList.add('in'); }, i * 80);
        revealObs.unobserve(e.target);
      }
    });
  }, { threshold: 0, rootMargin: '0px 0px -60px 0px' });
  document.querySelectorAll('.reveal').forEach(function (el) { revealObs.observe(el); });

  // ── ANIMATE BARS WHEN SCORECARD SCROLLS IN ────────────────
  var scoreObs = new IntersectionObserver(function (entries) {
    entries.forEach(function (e) {
      if (e.isIntersecting) { setTimeout(animateBars, 250); scoreObs.unobserve(e.target); }
    });
  }, { threshold: 0.15 });
  var sc = document.getElementById('scorecard');
  if (sc) scoreObs.observe(sc);

  window.MT = { buildScorecard: buildScorecard, animateBars: animateBars };
})();

/* ═══════════════════════════════════════════════
   THE INDEX — one record set, many views
   ═══════════════════════════════════════════════ */
(function () {
  'use strict';

  var LABEL = {
    stance:   { advancing: 'Advancing health', opposing: 'Opposing health', neutral: 'Neutral / contested' },
    level:    { federal: 'Federal', state: 'State', movement: 'Movement' },
    category: { policy: 'Policy', politics: 'Politics', media: 'Media', event: 'Event' },
    themes:   {
      pesticides: 'Pesticides & herbicides', toxics: 'Toxic chemicals & pollution',
      food: 'Food, nutrition & additives', foodaccess: 'Food access & assistance',
      healthcare: 'Healthcare access & funding', medication: 'Medication & mental health',
      vaccines: 'Vaccines', vectors: 'Ticks & vector-borne illness',
      illness: 'Chronic disease & cancer'
    }
  };
  var MARK  = { advancing: '▲', opposing: '▼', neutral: '■' };
  var ORDER = {
    stance:   ['advancing', 'opposing', 'neutral'],
    level:    ['federal', 'state', 'movement'],
    category: ['policy', 'politics', 'media', 'event'],
    themes:   ['pesticides', 'toxics', 'food', 'foodaccess', 'healthcare', 'medication',
               'vaccines', 'vectors', 'illness']
  };

  function esc(s) {
    return String(s == null ? '' : s)
      .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
  }
  function label(facet, v) { return (LABEL[facet] && LABEL[facet][v]) || v; }

  /* Descriptions are written in Typst and arrive already rendered as HTML
     (see load below), so they go in as they are. Typst cannot emit raw
     markup, which leaves nothing in them to sanitise. Everything else on a
     card is still escaped. */

  /* Enacted government policy, as opposed to the movement's own record.
     Written out rather than testing `e.stance`, which happens to divide the
     same way today but is a presentation field and could drift. */
  function isGovPolicy(e) {
    return e.category === 'policy' && (e.level === 'federal' || e.level === 'state');
  }

  /* ═══ one index per screen ═══
     Two live on this page - enacted policy under the scorecard, the movement
     record on its own - so state, selectors and handlers are all scoped to a
     root element rather than to the document. Each gets the half of the data
     its scope names, and never sees the other half. */
  function createIndex(root, opts) {
    if (!root) return { load: function () {}, fail: function () {} };

    var all = [], scoped = [];
    var query = '', stateFilter = '', yearFilter = '';
    var groupBy = 'year';
    var active = { stance: [], level: [], category: [], themes: [] };

    var $  = function (s) { return root.querySelector(s); };
    var $$ = function (s) { return root.querySelectorAll(s); };

    function inScope(e) { return opts.scope === 'policy' ? isGovPolicy(e) : !isGovPolicy(e); }

    /* ---------- filtering ---------- */
    function matches(e) {
      for (var f in active) {
        if (!active[f].length) continue;
        var v = e[f];
        if (Object.prototype.toString.call(v) === '[object Array]') {
          var hit = false;
          for (var j = 0; j < active[f].length; j++) {
            if (v.indexOf(active[f][j]) !== -1) { hit = true; break; }
          }
          if (!hit) return false;
        } else if (active[f].indexOf(v) === -1) return false;
      }
      if (opts.state && stateFilter && e.state !== stateFilter) return false;
      if (yearFilter && (e.date || '').slice(0, 4) !== yearFilter) return false;
      if (query) {
        var hay = (e.title + ' ' + e.descriptionText + ' ' + (e.state || '') + ' ' +
                   (e.tags || []).join(' ') + ' ' + e.dateLabel).toLowerCase();
        var terms = query.toLowerCase().split(/\s+/).filter(Boolean);
        for (var i = 0; i < terms.length; i++) if (hay.indexOf(terms[i]) === -1) return false;
      }
      return true;
    }

    /* ---------- grouping ---------- */
    function keyOf(e)      { return (e.date || '').slice(0, 4) || 'Undated'; }
    function groupLabel(k) { return k; }
    function sortKeys(ks)  { return ks.sort().reverse(); }

    /* ---------- rendering ---------- */
    function recordHTML(e) {
      var tags = (e.stance
                   ? '<span class="ix-tag stance ' + e.stance + '">' +
                       MARK[e.stance] + ' ' + esc(label('stance', e.stance)) + '</span>'
                   : '') +
                 '<span class="ix-tag lvl">' + esc(label('level', e.level)) + '</span>' +
                 '<span class="ix-tag">' + esc(label('category', e.category)) + '</span>' +
                 (e.state ? '<span class="ix-tag">' + esc(e.state) +
                   (e.govParty ? ' · Gov. ' + esc(e.govParty) : '') + '</span>' : '') +
                 (e.themes || []).map(function (t) {
                   return '<span class="ix-tag theme">' + esc(label('themes', t)) + '</span>'; }).join('') +
                 e.html.tags;

      return '<details class="ix-rec" data-stance="' + esc(e.stance) + '" id="' + esc(e.id) + '">' +
               '<summary>' +
                 '<span class="ix-rail-bar" aria-hidden="true"></span>' +
                 '<span class="ix-date">' + e.html.dateLabel + '</span>' +
                 '<span class="ix-main">' +
                   '<span class="ix-title">' + e.html.title + '</span>' +
                   '<span class="ix-meta">' + tags + '</span>' +
                   '<span class="ix-more">Read summary and sources</span>' +
                 '</span>' +
                 '<span class="ix-chev" aria-hidden="true">❯</span>' +
               '</summary>' +
               '<div class="ix-body">' +
                 '<div class="ix-desc">' + e.html.description + '</div>' +
                 (e.html.sources
                   ? '<p class="ix-sources"><span>Sources</span> ' + e.html.sources + '</p>' : '') +
               '</div>' +
             '</details>';
    }

    function render() {
      var rows = scoped.filter(matches);
      var out  = $('.ix-out');

      $('.ix-count').innerHTML = rows.length === scoped.length
        ? '<b>' + scoped.length + '</b> records'
        : '<b>' + rows.length + '</b> of ' + scoped.length + ' records';

      renderChips();

      if (!rows.length) {
        out.className = 'ix-out';
        out.innerHTML = '<div class="ix-empty"><strong>No records match.</strong>' +
          'Try removing a filter or searching for a different term.</div>';
        return;
      }

      var buckets = {}, html = '';
      rows.forEach(function (e) { var k = keyOf(e); (buckets[k] = buckets[k] || []).push(e); });
      sortKeys(Object.keys(buckets)).forEach(function (k) {
        var n = buckets[k].length;
        html += '<div class="ix-gh"><h3>' + esc(groupLabel(k)) + '</h3>' +
                '<span class="ix-gn">' + n + ' record' + (n === 1 ? '' : 's') + '</span></div>' +
                '<div class="ix-recs">' + buckets[k].map(recordHTML).join('') + '</div>';
      });
      out.className = 'ix-out' + (opts.rail ? ' ix-tl' : '');
      out.innerHTML = html;
    }

    function renderChips() {
      var chips = [];
      ['stance', 'level', 'category', 'themes'].forEach(function (f) {
        active[f].forEach(function (v) {
          chips.push('<span class="ix-chip">' + esc(label(f, v)) +
            '<button type="button" data-rm-facet="' + f + '" data-rm-val="' + esc(v) +
            '" aria-label="Remove filter ' + esc(label(f, v)) + '">×</button></span>');
        });
      });
      if (opts.state && stateFilter) {
        chips.push('<span class="ix-chip">' + esc(stateFilter) +
          '<button type="button" data-rm-state="1" aria-label="Remove state filter">×</button></span>');
      }
      if (yearFilter) {
        chips.push('<span class="ix-chip">' + esc(yearFilter) +
          '<button type="button" data-rm-year="1" aria-label="Remove year filter">×</button></span>');
      }
      if (query) {
        chips.push('<span class="ix-chip">“' + esc(query) + '”' +
          '<button type="button" data-rm-q="1" aria-label="Clear search">×</button></span>');
      }
      if (chips.length > 1) {
        chips.push('<button class="ix-clear ix-clearall" type="button">Clear all</button>');
      }
      $('.ix-chips').innerHTML = chips.join('');
    }

    /* ---------- facets ---------- */
    function buildFacets() {
      $$('.ix-opts').forEach(function (box) {
        var facet = box.dataset.facet, counts = {};
        scoped.forEach(function (e) {
          var v = e[facet];
          (Object.prototype.toString.call(v) === '[object Array]' ? v : [v]).forEach(function (k) {
            if (k) counts[k] = (counts[k] || 0) + 1;
          });
        });
        var keys = (ORDER[facet] || Object.keys(counts).sort()).filter(function (k) { return counts[k]; });
        box.innerHTML = keys.map(function (k) {
          var mark = facet === 'stance'
            ? '<span class="ix-mark ' + k + '" aria-hidden="true">' + MARK[k] + '</span>' : '';
          return '<button type="button" class="ix-opt" data-facet="' + facet + '" data-val="' + esc(k) + '" aria-pressed="false">' +
                   '<span class="ix-box" aria-hidden="true"></span>' + mark +
                   '<span>' + esc(label(facet, k)) + '</span>' +
                   '<span class="ix-n">' + counts[k] + '</span>' +
                 '</button>';
        }).join('');
        /* A facet that cannot narrow anything is noise, so it does not appear:
           the movement half has no positions on health at all, and on the
           policy half every record is a policy, so Record type offers the one
           option. Hiding rather than deleting means either group returns on
           its own if the data ever gives it a second option. */
        var grp = box.closest('.ix-group');
        if (grp) grp.hidden = keys.length < 2;
      });

      if (opts.state) {
        var states = {}, sel = $('.ix-state');
        scoped.forEach(function (e) { if (e.state) states[e.state] = (states[e.state] || 0) + 1; });
        Object.keys(states).sort().forEach(function (s) {
          var o = document.createElement('option');
          o.value = s; o.textContent = s + ' (' + states[s] + ')';
          sel.appendChild(o);
        });
      }

      var years = {}, ysel = $('.ix-year');
      scoped.forEach(function (e) { var y = (e.date || '').slice(0, 4); if (y) years[y] = (years[y] || 0) + 1; });
      Object.keys(years).sort().reverse().forEach(function (y) {
        var o = document.createElement('option');
        o.value = y; o.textContent = y + ' (' + years[y] + ')';
        ysel.appendChild(o);
      });
    }

    /* ---------- events ---------- */
    function wire() {
      root.addEventListener('click', function (ev) {
        var opt = ev.target.closest('.ix-opt');
        if (opt) {
          var f = opt.dataset.facet, v = opt.dataset.val, i = active[f].indexOf(v);
          if (i === -1) active[f].push(v); else active[f].splice(i, 1);
          opt.setAttribute('aria-pressed', i === -1 ? 'true' : 'false');
          syncOpts();
          return render();
        }
        var rm = ev.target.closest('[data-rm-facet]');
        if (rm) {
          var ff = rm.dataset.rmFacet, vv = rm.dataset.rmVal;
          active[ff] = active[ff].filter(function (x) { return x !== vv; });
          syncOpts();
          return render();
        }
        if (ev.target.closest('[data-rm-state]') && opts.state) {
          stateFilter = ''; $('.ix-state').value = ''; return render();
        }
        if (ev.target.closest('[data-rm-year]')) { yearFilter = ''; $('.ix-year').value = ''; return render(); }
        if (ev.target.closest('[data-rm-q]'))    { query = ''; $('.ix-search').value = '';   return render(); }
        if (ev.target.closest('.ix-clearall')) {
          active = { stance: [], level: [], category: [], themes: [] };
          query = ''; yearFilter = '';
          $('.ix-search').value = ''; $('.ix-year').value = '';
          if (opts.state) { stateFilter = ''; $('.ix-state').value = ''; }
          syncOpts();
          return render();
        }
        var tog = ev.target.closest('.ix-filtoggle');
        if (tog) {
          var open = $('.ix-railbox').classList.toggle('open');
          tog.setAttribute('aria-expanded', String(open));
        }
      });

      var t;
      $('.ix-search').addEventListener('input', function (e) {
        clearTimeout(t);
        var val = e.target.value;
        t = setTimeout(function () { query = val.trim(); render(); }, 160);
      });
      if (opts.state) {
        $('.ix-state').addEventListener('change', function (e) { stateFilter = e.target.value; render(); });
      }
      $('.ix-year').addEventListener('change', function (e) { yearFilter = e.target.value; render(); });
    }

    function syncOpts() {
      $$('.ix-opt').forEach(function (o) {
        o.setAttribute('aria-pressed', String(active[o.dataset.facet].indexOf(o.dataset.val) !== -1));
      });
      $$('.ix-fcount').forEach(function (c) {
        var n = (active[c.dataset.countFor] || []).length;
        c.textContent = n ? String(n) : '';
      });
    }

    return {
      load: function (data) {
        all = data; scoped = data.filter(inScope);
        buildFacets(); wire(); render();
      },
      fail: function (msg) {
        var out = $('.ix-out');
        if (out) out.innerHTML = '<div class="ix-empty"><strong>The index could not be loaded.</strong>' +
          'Please refresh the page. (' + esc(msg) + ')</div>';
      }
    };
  }

  var policyIx   = createIndex(document.getElementById('policy-index'),   { scope: 'policy',   state: true,  rail: false });
  var movementIx = createIndex(document.getElementById('movement-index'), { scope: 'movement', state: false, rail: true  });

  /* site.typ writes each record's fields as JSON into #entries-data, and
     its title, date, description, sources and tags, rendered, into a hidden
     div under #entry-bodies. */
  try {
    var data = JSON.parse(document.getElementById('entries-data').textContent);
    var rendered = {};
    document.querySelectorAll('#entry-bodies > [data-id]').forEach(function (el) {
      var html = {};
      el.querySelectorAll(':scope > [data-field]').forEach(function (f) {
        html[f.getAttribute('data-field')] = f.innerHTML;
      });
      html.text = el.querySelector(':scope > [data-field="description"]').textContent;
      rendered[el.getAttribute('data-id')] = html;
    });
    data.forEach(function (e) {
      e.html = rendered[e.id];
      e.descriptionText = e.html.text;
    });
    // Sort here rather than trusting the file, so an entry added out of
    // order cannot surface in the wrong year. Array.sort is stable, so
    // entries sharing a date keep the order the file gives them.
    data.sort(function (a, b) { return a.date < b.date ? 1 : a.date > b.date ? -1 : 0; });
    policyIx.load(data);
    movementIx.load(data);
    if (window.MT && window.MT.buildScorecard) window.MT.buildScorecard(data);
  } catch (err) {
    policyIx.fail(err.message);
    movementIx.fail(err.message);
  }
})();
