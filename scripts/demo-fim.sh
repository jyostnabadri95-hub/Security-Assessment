#!/usr/bin/env sh
set -eu
base=services/demo/data/finance
file="$base/demo-$(date +%s).txt"
printf 'Account,Amount\nDEMO-001,100\n' > "$file"
sleep 3
printf 'DEMO-002,250\n' >> "$file"
sleep 3
rm "$file"
echo 'Generated FIM create/modify/delete events (allow about one minute for indexing).'

