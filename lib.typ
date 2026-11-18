// Helpers shared by site.typ and the files under content/.
//
// Typst's HTML export has no way to paste raw HTML, so every tag the page
// needs is built with `el`. A named argument becomes an attribute, and one
// whose value is none is left off.
#let el(tag, ..args) = html.elem(
  tag,
  attrs: args.named().pairs().filter(p => p.at(1) != none).to-dict(),
  ..args.pos(),
)

// A <label for=…>. `for` is a keyword in Typst, so it cannot be a named
// argument to el.
#let label-for(target, ..args) = el("label", ..("for": target), ..args)

// ── Records ────────────────────────────────────────────────────────────

// The words in a piece of content with the markup stripped, for checks and
// for the search box.
#let plain(c) = {
  if c == none { "" }
  else if type(c) == str { c }
  else if c.has("text") { plain(c.text) }
  else if c.has("children") { c.children.map(plain).sum(default: "") }
  else if c.has("body") { plain(c.body) }
  else if c.func() == smartquote { if c.double { "\"" } else { "'" } }
  else if c == [ ] { " " }
  else { "" }
}

// One source an entry draws on. Leave the url off only for something that
// can be named but genuinely not linked; it then renders as plain text.
#let source(label, ..url) = (label: label, url: url.pos().at(0, default: ""))

// A video at the top of an entry. Takes the player's embed URL, from Vimeo
// (https://player.vimeo.com/video/…) or YouTube
// (https://www.youtube-nocookie.com/embed/…).
#let video(src) = el("div", class: "ix-video", el(
  "iframe",
  src: src,
  allow: if src.contains("vimeo") { "autoplay; fullscreen; picture-in-picture" } else {
    "accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
  },
  allowfullscreen: "",
))

// One record. Federal and state records with category "policy" appear under
// the Scorecard; everything else appears on the Movement Timeline.
//
//   id          e042 - the letter e and three digits, never reused
//   date        2026-11-08, 2026-11 or 2026, whatever the source supports
//   dateLabel   what a reader sees, e.g. [Spring 2024]; the year must match
//   dateApprox  true when the date is approximate
//   title       clicking it on the site reveals the description
//   category    policy, politics, media or event
//   level       federal, state or movement
//   stance      advancing, opposing or neutral - enacted policy only
//   themes      one or more of pesticides, toxics, food, foodaccess,
//               healthcare, medication, vaccines, vectors, illness
//   tags        free text, e.g. ([Trump administration], [Sen. Booker]);
//               reuse an existing spelling where one fits
//   state       full name, e.g. "West Virginia" - state records only
//   stateCode   two lowercase letters, e.g. "wv", agreeing with state
//   govParty    "D" or "R" - state policy records only
//   enacted, actorD, actorR, bipartisan
//               true or false - policy records only
//
// title, dateLabel, tags and source labels are content in [ ], like the
// description, so they take the same markup. The rest are fixed values the
// filters and the scorecard match on, so they stay strings in " ".
//
// Then any number of source(...) lines, and the description in [ ].
//
// A field outside these values fails the build rather than going quietly
// onto the page.
#let entry(
  id: none,
  date: none,
  dateLabel: none,
  dateApprox: false,
  title: none,
  category: none,
  level: none,
  stance: "",
  themes: (),
  tags: (),
  state: "",
  stateCode: "",
  govParty: "",
  enacted: none,
  actorD: none,
  actorR: none,
  bipartisan: none,
  ..rest,
) = {
  let who = if id == none { "an entry with no id" } else { id }
  assert(rest.named().len() == 0, message: who + ": unknown field(s) " + rest.named().keys().join(", "))
  let pos = rest.pos()
  assert(pos.len() > 0 and type(pos.last()) == content, message: who + ": no description in [ ] after the fields")
  for (k, v) in (id: id, date: date) {
    assert(type(v) == str, message: who + ": missing " + k)
  }
  for (k, v) in (title: title, dateLabel: dateLabel) {
    assert(v != none and plain(v).trim() != "", message: who + ": missing " + k)
  }
  let tags = if type(tags) == array { tags } else { (tags,) }
  assert(date.match(regex("^\d{4}(-\d{2}(-\d{2})?)?$")) != none, message: who + ": date must be YYYY, YYYY-MM or YYYY-MM-DD")
  let allowed = (
    category: ("policy", "politics", "media", "event"),
    level: ("federal", "state", "movement"),
    stance: ("advancing", "opposing", "neutral", ""),
    govParty: ("D", "R", ""),
  )
  for (k, v) in (category: category, level: level, stance: stance, govParty: govParty) {
    assert(v in allowed.at(k), message: who + ": " + k + " must be one of " + allowed.at(k).filter(x => x != "").join(", "))
  }
  let THEMES = ("pesticides", "toxics", "food", "foodaccess", "healthcare", "medication", "vaccines", "vectors", "illness")
  for t in (if type(themes) == str { (themes,) } else { themes }) {
    assert(t in THEMES, message: who + ": unknown theme " + t)
  }
  assert(id.match(regex("^e\d{3}$")) != none, message: who + ": id must be the letter e and three digits, e.g. e042")
  let year = plain(dateLabel).find(regex("\d{4}"))
  assert(year == none or year == date.slice(0, 4), message: who + ": date " + date + " and dateLabel \"" + plain(dateLabel) + "\" disagree on the year")
  assert(stateCode.match(regex("^([a-z]{2})?$")) != none, message: who + ": stateCode must be two lowercase letters, e.g. wv")
  // The two halves of the site: enacted policy is scored, everything else is not.
  if category == "policy" and level in ("federal", "state") {
    assert(stance != "", message: who + ": enacted policy with no stance on health")
  } else {
    assert(stance == "", message: who + ": not policy, but carries stance " + stance)
    for (k, v) in (enacted: enacted, actorD: actorD, actorR: actorR, bipartisan: bipartisan) {
      assert(v == none, message: who + ": not policy, but carries " + k)
    }
  }
  let sources = pos.slice(0, -1)
  for s in sources {
    assert(type(s) == dictionary, message: who + ": write each source as source(\"Label\", \"https://…\")")
    assert(plain(s.label).trim() != "", message: who + ": a source has no label")
  }

  // The fields as plain values: the JSON site.js reads, and what the checks
  // and the search box see. The content fields go in as their bare text.
  let record = (
    id: id,
    date: date,
    dateLabel: plain(dateLabel),
    dateApprox: dateApprox,
    title: plain(title),
    category: category,
    level: level,
    stance: stance,
    themes: if type(themes) == str { (themes,) } else { themes },
    tags: tags.map(plain),
    state: state,
    stateCode: stateCode,
    govParty: govParty,
    sources: sources.map(s => (label: plain(s.label), url: s.url)),
  )
  for (k, v) in (enacted: enacted, actorD: actorD, actorR: actorR, bipartisan: bipartisan) {
    if v != none { record.insert(k, v) }
  }

  [#metadata(record) <entry>]
  // Rendered, for site.js to drop into the record's card.
  el("div", data-id: id, {
    el("div", data-field: "title", title)
    el("div", data-field: "dateLabel", dateLabel)
    el("div", data-field: "description", pos.last())
    el("div", data-field: "sources", sources.map(s => if s.url != "" { link(s.url, s.label) } else { s.label }).join(" · "))
    el("div", data-field: "tags", tags.map(t => el("span", class: "ix-tag", t)).join())
  })
}

// ── Page furniture ─────────────────────────────────────────────────────

// A full-screen view. `screen` names the nav tab it belongs to; see nav.js.
#let screen(id, screen, on: false, body) = el(
  "section",
  id: id,
  data-screen: screen,
  class: if on { "view-on" },
  body,
)

// The eyebrow, heading and lead paragraph at the top of a section. Dark
// sections pass light: true.
#let section-head(eyebrow: none, title: none, lead: none, light: false) = {
  if eyebrow != none {
    el("p", class: if light { "eyebrow teal-dim" } else { "eyebrow teal" }, eyebrow)
  }
  el("h2", class: if light { "section-h2 light" } else { "section-h2" }, title)
  if lead != none {
    el("p", class: if light { "section-lead light" } else { "section-lead" }, lead)
  }
}

#let hero(eyebrow: none, title: none, sub: none, note: none, stats: ()) = screen(
  "hero",
  "overview",
  on: true,
  {
    el("div", class: "hero-dot-grid")
    el("div", class: "hero-glow-a")
    el("div", class: "hero-glow-b")
    el("div", class: "hero-body", {
      el("div", class: "hero-left", {
        el("p", class: "hero-eyebrow", eyebrow)
        el("h1", class: "hero-h1", title)
        el("p", class: "hero-sub", sub)
        el("div", class: "hero-note", el("p", note))
      })
      el("div", class: "hero-visual", {
        // Typst cannot paste raw markup, so the SVG is parsed and rebuilt
        // element by element. Comments come back with no tag and are dropped.
        let svg(n) = if type(n) == str { n.trim() } else if n.tag != "" {
          html.elem(n.tag, attrs: n.attrs, n.children.map(svg).join())
        }
        let root = xml("assets/hero.svg").first()
        root.attrs.insert("class", "hero-svg")
        root.attrs.insert("aria-hidden", "true")
        root.attrs.insert("focusable", "false")
        svg(root)
      })
    })
    // The counts are filled in by site.js from the records.
    el("div", class: "stats-bar", for (id, colour, label) in stats {
      el("div", class: "stat-cell", {
        el("span", class: "stat-num " + colour, id: id, "0")
        el("span", class: "stat-lbl", label)
      })
    })
  },
)

// A card linking to another screen, beside the Primer.
#let nav-card(href, label, aria: none, body) = el("a", class: "section-nav-card", href: href, aria-label: aria, {
  el("span", class: "snc-label", label)
  el("p", body)
  el("span", class: "snc-arrow", aria-hidden: "true", "→")
})

// One of the three Pew figures above the Scorecard.
#let pew-stat(figure, colour, body) = el("div", class: "pew-stat", {
  el("div", class: "pew-num", style: "color:var(--" + colour + ")", figure)
  el("div", class: "pew-lbl", body)
})

// Half of the Scorecard. site.js draws the bars into the empty div.
#let score-half(bars, title, extra) = el("div", class: "score-half", {
  el("h3", title)
  el("div", id: bars)
  extra
})

#let principle(num, title, body) = el("div", class: "principle-block", {
  el("div", class: "principle-num", num)
  el("div", class: "principle-body", {
    el("strong", title)
    el("p", body)
  })
})

#let milestone(year, title, body) = el("div", class: "tl-item", {
  el("span", class: "tl-year", year)
  el("div", class: "tl-content", {
    el("h5", title)
    el("p", body)
  })
})

// The search box, filter rail and results list for one half of the records.
// site.js fills it from the entries in content/entries.typ. `p` prefixes the
// element ids so two of these can share a page.
#let records(p, id: none, placeholder: none, facets: (), states: false) = {
  let FACET-LABEL = (themes: "Theme", stance: "Position on health", level: "Arena", category: "Record type")
  el("div", class: "ix-layout", id: id, {
    el("div", class: "ix-rail", {
      el("button", class: "ix-filtoggle", aria-expanded: "false", aria-controls: p + "-railbox", "Filters & search")
      el("div", class: "ix-railbox", id: p + "-railbox", {
        label-for(p + "-search", class: "sr-only", "Search records")
        el("input", type: "search", id: p + "-search", class: "ix-search", placeholder: placeholder, autocomplete: "off")
        for f in facets {
          el("details", class: "ix-group ix-fgroup", {
            el("summary", class: "ix-glabel", id: p + "-lbl-" + f, {
              FACET-LABEL.at(f)
              el("span", class: "ix-fcount", data-count-for: f)
            })
            el("div", class: "ix-opts", role: "group", aria-labelledby: p + "-lbl-" + f, data-facet: f)
          })
        }
      })
    })
    el("div", class: "ix-results", {
      el("div", class: "ix-bar", {
        el("p", class: "ix-count", role: "status", aria-live: "polite")
        el("span", class: "ix-spacer")
        if states {
          label-for(p + "-state", class: "sr-only", "State")
          el("select", id: p + "-state", class: "ix-barsel ix-state", el("option", value: "", "All states"))
        }
        label-for(p + "-year", class: "sr-only", "Year")
        el("select", id: p + "-year", class: "ix-barsel ix-year", el("option", value: "", "All years"))
      })
      el("div", class: "ix-chips")
      el("div", class: "ix-out")
    })
  })
}

// ── Checks across all the records ──────────────────────────────────────

// Mistakes that fail the build but need every record to see. site.typ calls
// this on the full set.
#let check-records(records) = {
  let seen = (:)
  for r in records {
    assert(r.id not in seen, message: r.id + ": duplicate id")
    seen.insert(r.id, true)
  }
}

// Things worth a look that should not stop the site going up. Typst cannot
// print a warning of its own, so `just check` prints this list instead.
#let warnings(records) = {
  let out = ()
  let norm(s) = lower(s).replace(regex("[^a-z0-9 ]"), " ").replace(regex("\s+"), " ").trim()
  let openings = (:)
  let prev = none
  for r in records {
    if r.sources.len() == 0 { out.push(r.id + ": no sources") }
    let unlinked = r.sources.filter(s => s.url == "").map(s => s.label)
    if unlinked.len() > 0 { out.push(r.id + ": source named but not linked: " + unlinked.join(", ")) }
    // A near-duplicate is how the five merged pairs got in.
    let k = norm(r.title.clusters().slice(0, calc.min(46, r.title.clusters().len())).join())
    openings.insert(k, openings.at(k, default: ()) + (r.id,))
    // Newest first. site.js sorts anyway; this keeps the file readable.
    if prev != none and r.date > prev { out.push(r.id + ": out of file order, " + r.date + " follows " + prev) }
    prev = r.date
  }
  for (k, ids) in openings {
    if ids.len() > 1 { out.push("possible duplicate: " + ids.join(", ") + " share a title opening") }
  }
  out
}
