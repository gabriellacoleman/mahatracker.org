// The whole site. Build it with `just build`, which writes _site/index.html.
//
// The words live under content/: one file per screen, and every record in
// content/entries.typ. This file only arranges them on the page.

#import "lib.typ": *

#set smartquote(enabled: false)
#show link: it => if type(it.dest) == str and it.dest.starts-with("http") {
  el("a", href: it.dest, target: "_blank", rel: "noopener", it.body)
} else { it }

#html.html(lang: "en", {
  html.head({
    html.meta(charset: "utf-8")
    html.meta(name: "viewport", content: "width=device-width, initial-scale=1.0")
    html.title("MAHA Tracker — Food & Environmental Health Policy")
    html.link(rel: "preconnect", href: "https://fonts.googleapis.com")
    el("link", rel: "preconnect", href: "https://fonts.gstatic.com", crossorigin: "")
    html.link(rel: "stylesheet", href: "https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,700;0,900;1,400&family=DM+Mono:ital,wght@0,400;0,500;1,400&family=Source+Serif+4:opsz,wght@8..60,300;8..60,400;8..60,600&display=swap")
    html.style(read("assets/style.css"))
  })

  html.body({
    el("a", href: "#hero", class: "skip-link", "Skip to main content")

    // Password gate
    el("div", id: "pw-gate", {
      el("h2", { "MAHA"; el("span", "TRACKER") })
      el("p", "Preview access — enter password to continue")
      el("div", id: "pw-form", {
        label-for("pw-input", class: "sr-only", "Password")
        el("input", id: "pw-input", type: "password", placeholder: "password", autocomplete: "off", aria-label: "Preview password")
        el("button", id: "pw-btn", onclick: "checkPw()", "Enter")
      })
      el("div", id: "pw-error", "Incorrect password")
    })
    html.script(read("assets/gate.js"))

    el("nav", {
      el("span", class: "nav-logo", "MAHA TRACKER")
      el("button", class: "nav-toggle", aria-label: "Toggle navigation menu", aria-expanded: "false", onclick: "toggleNav(this)", {
        for _ in range(3) { el("span", class: "nav-toggle-bar") }
      })
      el("ul", class: "nav-links", id: "nav-links", {
        el("li", el("a", href: "#primer", "Primer"))
        el("li", el("a", href: "#scorecard", "Policy & Scorecard"))
        el("li", el("a", href: "#index", "Movement Timeline"))
        el("li", el("a", href: "#alternative", "Alt. Path"))
      })
    })
    html.script(read("assets/nav.js"))

    include "content/hero.typ"
    screen("primer", "overview", on: true, el("div", class: "inner", include "content/primer.typ"))
    screen("scorecard", "scorecard", el("div", class: "inner", include "content/scorecard.typ"))
    screen("policy", "scorecard", el("div", class: "inner", include "content/policy.typ"))
    screen("index", "movement", el("div", class: "inner", include "content/timeline.typ"))
    screen("alternative", "alternative", el("div", class: "inner", include "content/alternative.typ"))

    el("footer", include "content/footer.typ")

    // The records. Their descriptions sit here, hidden, and their fields go
    // into the script tag below as JSON; site.js joins the two by id and
    // renders both indexes and the scorecard from them.
    el("div", id: "entry-bodies", hidden: "", include "content/entries.typ")
    context {
      let records = query(<entry>).map(m => m.value)
      check-records(records)
      el("script", type: "application/json", id: "entries-data", json.encode(records, pretty: false))
    }

    html.script(read("assets/site.js"))
  })
})
