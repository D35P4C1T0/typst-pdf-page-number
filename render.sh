#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
typst_file="${script_dir}/add_page_numbers.typ"
config_file="${1:-${script_dir}/numbering-config.yaml}"
output_file="${2:-${script_dir}/numbered.pdf}"

if ! command -v typst >/dev/null 2>&1; then
  echo "typst is required but was not found in PATH." >&2
  exit 1
fi

if ! command -v pdfinfo >/dev/null 2>&1; then
  echo "pdfinfo is required but was not found in PATH." >&2
  exit 1
fi

if [[ ! -f "${config_file}" ]]; then
  echo "Config file not found: ${config_file}" >&2
  exit 1
fi

pdf_value="$(
  sed -nE 's/^pdf:[[:space:]]*(.+)$/\1/p' "${config_file}" \
    | head -n 1 \
    | sed -E 's/^[[:space:]]+|[[:space:]]+$//g' \
    | sed -E "s/^'(.*)'$/\1/" \
    | sed -E 's/^"(.*)"$/\1/'
)"

if [[ -z "${pdf_value}" ]]; then
  echo "Missing 'pdf' key in config: ${config_file}" >&2
  exit 1
fi

config_dir="$(cd -- "$(dirname -- "${config_file}")" && pwd)"
if [[ "${pdf_value}" = /* ]]; then
  pdf_path="${pdf_value}"
else
  pdf_path="${config_dir}/${pdf_value}"
fi

if [[ ! -f "${pdf_path}" ]]; then
  echo "Input PDF not found: ${pdf_path}" >&2
  exit 1
fi

pdfinfo_output="$(pdfinfo "${pdf_path}")"
total_pages="$(awk '/^Pages:/ {print $2; exit}' <<<"${pdfinfo_output}")"
page_width_pt="$(awk '/^Page size:/ {print $3; exit}' <<<"${pdfinfo_output}")"
page_height_pt="$(awk '/^Page size:/ {print $5; exit}' <<<"${pdfinfo_output}")"

if [[ -z "${total_pages}" || -z "${page_width_pt}" || -z "${page_height_pt}" ]]; then
  echo "Unable to extract page metadata from: ${pdf_path}" >&2
  exit 1
fi

pdf_for_typst="$(realpath --relative-to="${script_dir}" "${pdf_path}")"
config_for_typst="$(realpath --relative-to="${script_dir}" "${config_file}")"
output_for_typst="$(realpath --relative-to="${script_dir}" "${output_file}")"

(
  cd "${script_dir}"
  typst compile "${typst_file##*/}" "${output_for_typst}" \
    --input config="${config_for_typst}" \
    --input pdf="${pdf_for_typst}" \
    --input total_pages="${total_pages}" \
    --input page_width_pt="${page_width_pt}" \
    --input page_height_pt="${page_height_pt}"
)
