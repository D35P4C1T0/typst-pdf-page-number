# typst_numbers

Add customizable page numbers to an existing PDF with Typst.

## Features

- Numbering format template with placeholders: `{n}` (current page) and `{p}` (total pages)
- Selective numbering via interval ranges (example: `2-13,15-17`)
- Global min/max page bounds
- Configurable pill color via hex (`#RRGGBB` or `#RRGGBBAA`)
- Modern label font (`Fira Sans`)
- Auto-detect PDF page count and page size through a wrapper script

## Preview

![Preview](assets/preview-numbered.png)

## Requirements

- `typst`
- `pdfinfo` (from poppler utils)
- `pdftoppm` (only needed to regenerate preview image)

## Quick Start

1. Edit the config file (example: `numbering-config-example.yaml`).
2. Run:

```bash
./render.sh numbering-config-example.yaml numbered.pdf
```

This command automatically reads page count and page dimensions from the source PDF and passes them to Typst.

## Direct Typst Compile

You can still compile directly:

```bash
typst compile add_page_numbers.typ numbered.pdf --input config=numbering-config-example.yaml
```

## Configuration

YAML keys:

- `pdf`: input PDF path
- `total_pages`: total page count (usually auto-filled by `render.sh`)
- `intervals`: comma-separated intervals (example: `"1-4,6,8-10"`)
- `min_number`: lower page bound for numbering
- `max_number`: upper page bound for numbering
- `label_template`: custom label template, using `{n}` and `{p}`
- `pill_color`: hex color for the pill background
- `page_width_pt`: page width in points (usually auto-filled by `render.sh`)
- `page_height_pt`: page height in points (usually auto-filled by `render.sh`)

## Validation

`add_page_numbers.typ` validates:

- page bounds and total page consistency
- interval bounds inside `[1, total_pages]`
- `min_number <= max_number`
- positive page width and height
- valid hex pill color format
