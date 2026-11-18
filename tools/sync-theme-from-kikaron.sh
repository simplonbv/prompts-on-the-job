#!/usr/bin/env bash
# SPDX-License-Identifier: EUPL-1.2
# Bring theme/vng/ level with the VNG theme Kik-OS's own installation runs
# (kik-os.cornae.com: every hub there has vng-potj as its only theme), which
# is Kikaron's static/themes/vng-potj/ — at a ref of a Kikaron checkout.
#
#   tools/sync-theme-from-kikaron.sh /path/to/kikaron [<ref>]   # default: origin/main
#
# Records the commit in theme/vng/SYNC.md. Change the theme in Kikaron first,
# then sync; never edit theme/vng/style/all.css here by hand.
set -euo pipefail
KIKARON=${1:?usage: $0 /path/to/kikaron [<ref>]}
REF=${2:-origin/main}
HERE=$(cd "$(dirname "$0")/.." && pwd)

git -C "$KIKARON" fetch -q origin
SHA=$(git -C "$KIKARON" rev-parse "$REF")
DATE=$(git -C "$KIKARON" log -1 --format=%ad --date=short "$SHA")
git -C "$KIKARON" show "$SHA:static/themes/vng-potj/style/all.css" > "$HERE/theme/vng/style/all.css"
cat > "$HERE/theme/vng/SYNC.md" <<EOF
# Where theme/vng comes from

\`style/all.css\` is Kikaron's \`static/themes/vng-potj/style/all.css\` — the VNG
theme every hub on kik-os.cornae.com runs — at \`$SHA\` ($DATE), brought
over with \`tools/sync-theme-from-kikaron.sh\`. Change it in Kikaron, then sync.
EOF
echo "theme/vng is now kikaron $SHA ($DATE)"
