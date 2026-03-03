#let config_path = sys.inputs.at("config", default: "")
#let config = if config_path == "" { (:) } else { yaml(config_path) }

#let setting(key, default) = {
  let from_cli = sys.inputs.at(key, default: none)
  if from_cli != none {
    from_cli
  } else {
    config.at(key, default: default)
  }
}

#let pdf_path = str(setting("pdf", "main.pdf"))
#let total_pages = int(setting("total_pages", 18))
#let interval_spec = str(setting("intervals", "1-4,5-7"))
#let min_number = int(setting("min_number", 1))
#let max_number = int(setting("max_number", total_pages))
#let label_template = str(setting("label_template", "{n} of {p}"))
#let pill_hex = str(setting("pill_color", "#ffffff"))
#let page_width_pt = float(setting("page_width_pt", 960))
#let page_height_pt = float(setting("page_height_pt", 540))

#let parse_intervals(spec) = {
  let cleaned = spec.trim()
  if cleaned == "" {
    ()
  } else {
    cleaned
      .split(",")
      .map(part => part.trim())
      .filter(part => part != "")
      .map(part => {
        if part.contains("-") {
          let bounds = part.split("-").map(value => int(value.trim()))
          assert(bounds.len() == 2, message: "Invalid interval: " + part)
          let start = bounds.at(0)
          let end = bounds.at(1)
          (calc.min(start, end), calc.max(start, end))
        } else {
          let page = int(part)
          (page, page)
        }
      })
  }
}

#let in_intervals(page, intervals) = {
  if intervals.len() == 0 {
    return true
  }
  for interval in intervals {
    if page >= interval.at(0) and page <= interval.at(1) {
      return true
    }
  }
  false
}

#let should_number(page, intervals, min_number, max_number) = {
  page >= min_number and page <= max_number and in_intervals(page, intervals)
}

#let assert_between(name, value, lower, upper) = {
  assert(
    value >= lower and value <= upper,
    message: name + " must be in [" + str(lower) + ", " + str(upper) + "], got " + str(value),
  )
}

#let is_hex_color(value) = {
  if not value.starts-with("#") {
    return false
  }
  if value.len() != 7 and value.len() != 9 {
    return false
  }
  let digits = "0123456789abcdefABCDEF"
  for idx in range(1, value.len()) {
    let char = value.slice(idx, idx + 1)
    if not digits.contains(char) {
      return false
    }
  }
  true
}

#let render_label(page, total_pages, template) = {
  template.replace("{n}", str(page)).replace("{p}", str(total_pages))
}

#let ranges = parse_intervals(interval_spec)
#let pill_color_valid = is_hex_color(pill_hex)

#assert(total_pages >= 1, message: "total_pages must be >= 1")
#assert(min_number <= max_number, message: "min_number must be <= max_number")
#assert_between("min_number", min_number, 1, total_pages)
#assert_between("max_number", max_number, 1, total_pages)
#assert(page_width_pt > 0, message: "page_width_pt must be > 0")
#assert(page_height_pt > 0, message: "page_height_pt must be > 0")
#assert(
  pill_color_valid,
  message: "pill_color must be a hex color in RRGGBB or RRGGBBAA form prefixed by hash",
)

#for interval in ranges {
  assert_between("interval start", interval.at(0), 1, total_pages)
  assert_between("interval end", interval.at(1), 1, total_pages)
}

#let pill_color = rgb(pill_hex)

#set page(width: page_width_pt * 1pt, height: page_height_pt * 1pt, margin: 0pt)

#for page_index in range(1, total_pages + 1) [
  #block(width: 100%, height: 100%)[
    #image(pdf_path, page: page_index, width: 100%, height: 100%)
    #if should_number(page_index, ranges, min_number, max_number) [
      #place(bottom + right, float: true, scope: "parent", dx: -20pt, dy: -14pt)[
        #box(
          fill: pill_color,
          radius: 999pt,
          inset: (x: 10pt, y: 4pt),
        )[
          #text(fill: black, weight: "semibold", size: 10pt, font: "Fira Sans")[
            #render_label(page_index, total_pages, label_template)
          ]
        ]
      ]
    ]
  ]
]
