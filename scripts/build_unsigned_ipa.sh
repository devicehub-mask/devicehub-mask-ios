#!/bin/bash

set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
    echo "Usage: $0 <archive-path> [output-ipa-path]" >&2
    exit 2
fi

archive_path="$1"
output_path="${2:-DeviceHubMask.ipa}"
app_name="${APP_NAME:-DeviceHubMask}"

if [[ ! -d "$archive_path" && -d "${archive_path}.xcarchive" ]]; then
    archive_path="${archive_path}.xcarchive"
fi

app_path="$archive_path/Products/Applications/$app_name.app"
if [[ ! -d "$app_path" ]]; then
    echo "Unable to find $app_name.app in $archive_path." >&2
    exit 1
fi

output_directory="$(dirname "$output_path")"
mkdir -p "$output_directory"
output_directory="$(cd "$output_directory" && pwd)"
output_path="$output_directory/$(basename "$output_path")"

work_directory="$(mktemp -d "${TMPDIR:-/tmp}/devicehub-mask-ipa.XXXXXX")"
trap 'rm -rf "$work_directory"' EXIT

mkdir -p "$work_directory/Payload"
ditto "$app_path" "$work_directory/Payload/$app_name.app"

(
    cd "$work_directory"
    /usr/bin/zip -qry "$output_path" Payload \
        -x 'Payload/._*' \
        -x 'Payload/.DS_Store' \
        -x 'Payload/**/.DS_Store' \
        -x 'Payload/**/__MACOSX/*'
)

/usr/bin/unzip -tq "$output_path"
echo "Created unsigned IPA: $output_path"
