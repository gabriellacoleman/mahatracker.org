#import "../lib.typ": *

#section-head(
  eyebrow: [The record behind the scorecard],
  title: [Federal & State Policy],
  lead: [Every enacted federal and state action counted in the scorecard above, searchable and filterable. Each is marked *advancing*, *opposing* or *neutral* on health.],
)

#records(
  "pol",
  id: "policy-index",
  placeholder: "Search policy records…",
  facets: ("themes", "stance", "level", "category"),
  states: true,
)
