#import "../lib.typ": *

#section-head(
  light: true,
  eyebrow: [By the numbers],
  title: [Partisan Scorecard],
  lead: [Who is actually advancing food and environmental health policy, and who is blocking it? Federal and state enacted laws and regulations, 2022–2026.],
)

#el("a", class: "pew-block", target: "_blank", rel: "noopener", href: "https://www.pew.org/en/research-and-analysis/articles/2026/02/26/americans-are-concerned-about-harmful-chemicals-in-food-water-and-everyday-products")[
  #el("div", class: "pew-stats")[
    #pew-stat([70%+], "teal")[of Americans very or somewhat concerned about chemicals in food & water]
    #pew-stat([5 in 6], "amber")[say government and business should do more on chemical safety]
    #pew-stat([8 in 10], "rep-light")[Republicans share this concern; the political opening is _not_ partisan]
  ]
]
#el("p", class: "pew-src")[Source: *Pew Research Center* — "Americans Are Concerned About Harmful Chemicals in Food, Water, and Everyday Products," February 2026 ↗]

// The bars are counted from the entries by site.js.
#el("div", class: "score-grid reveal")[
  #score-half("bars-adv", [Advancing Health: Who Signs It], none)
  #score-half("bars-opp", [Opposing Health: Who Signs It], el("div", class: "score-callout")[
    #el("p", class: "callout-lbl")[Key Finding]
    #el("blockquote")["State-level Democrats are doing more on food and environmental health than the movement that made 'healthy' a campaign slogan — but federal Democrats have largely failed to challenge corporate power. 'Better than Republicans' is not a health agenda."]
    #el("cite")[— Based on enacted federal legislation and regulations, 2020–2026.]
  ])
]
