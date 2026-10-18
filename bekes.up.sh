#!/bin/bash
# ═══════════════════════════════════════════════════════════════
#   ██████╗ ███████╗██╗  ██╗███████╗███████╗
#   ██╔══██╗██╔════╝██║ ██╔╝██╔════╝██╔════╝
#   ██████╔╝█████╗  █████╔╝ █████╗  ███████╗
#   ██╔══██╗██╔══╝  ██╔═██╗ ██╔══╝  ╚════██║
#   ██████╔╝███████╗██║  ██╗███████╗███████║
#   ╚═════╝ ╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝
#
#   bekes.up.sh  ·  Sileo Repo Auto-Builder
#   By B6_7E | بيكاس
# ═══════════════════════════════════════════════════════════════
set -euo pipefail
cd "$(dirname "$0")"

# ─────────────────────────────  COLORS  ────────────────────────
R='\033[1;31m'; G='\033[1;32m'; Y='\033[1;33m'; B='\033[1;34m'
M='\033[1;35m'; C='\033[1;36m'; W='\033[1;37m'; DIM='\033[2m'
BOLD='\033[1m'; RESET='\033[0m'
BG_M='\033[45m'; BG_C='\033[46m'; BG_G='\033[42m'; BG_R='\033[41m'

# ─────────────────────────────  BANNER  ────────────────────────
command -v clear >/dev/null && clear || true
echo -e "${M}${BOLD}"
cat <<'BANNER'
  ██████╗ ███████╗██╗  ██╗███████╗███████╗
  ██╔══██╗██╔════╝██║ ██╔╝██╔════╝██╔════╝
  ██████╔╝█████╗  █████╔╝ █████╗  ███████╗
  ██╔══██╗██╔══╝  ██╔═██╗ ██╔══╝  ╚════██║
  ██████╔╝███████╗██║  ██╗███████╗███████║
  ╚═════╝ ╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝
BANNER
echo -e "${RESET}"
echo -e "${BG_M}${W}${BOLD}        ⚡  SILEO REPO AUTO-BUILDER  ⚡        ${RESET}"
echo -e "${Y}${BOLD}              By B6_7E | بيكاس              ${RESET}"
echo -e "${DIM}  ──────────────────────────────────────────────${RESET}"
echo ""

# ═══════════════════════════════════════════════════════════════
#  CONFIG
# ═══════════════════════════════════════════════════════════════
REPO_BASE="https://bekes-505.github.io/plus"
HEADER_URL="https://raw.githubusercontent.com/BekEs-505/plus/main/header.png"

DEBS_DIR="debs"
OUTPUT_DIR="depictions"
ASSETS_DIR="assets"
DEFAULT_TINT="#5AC8FA"

TWITTER="BekEs-505"
DISCORD="https://discord.gg/yourserver"
GITHUB="BekEs-505"
YOUTUBE="https://youtube.com/@yourchannel"
TELEGRAM="yourchannel"
REDDIT="BekEs-505"
WEBSITE="https://bekes-505.github.io/plus"

C_X="1DA1F2"; C_DISCORD="5865F2"; C_GITHUB="FFFFFF"
C_YOUTUBE="FF0000"; C_TELEGRAM="26A5E4"; C_REDDIT="FF4500"; C_WEBSITE="5AC8FA"

# ═══════════════════════════════════════════════════════════════
#  CHECKS
# ═══════════════════════════════════════════════════════════════
echo -e "${C}${BOLD}▸ Checks${RESET}"
for cmd in dpkg-deb apt-ftparchive python3 git; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo -e "${BG_R}${W} MISSING ${RESET} ${R}$cmd${RESET} — ثبّته أولاً (apt install apt-utils dpkg python3 git)"
    exit 1
  fi
done
echo -e "  ${G}✓${RESET} كل الأدوات موجودة"
[ -d "$DEBS_DIR" ] || { echo -e "${R}❌ لا يوجد مجلد $DEBS_DIR/${RESET}"; exit 1; }
mkdir -p "$OUTPUT_DIR"
echo ""

# ═══════════════════════════════════════════════════════════════
#  LOOP · إنشاء depictions لكل تويك
# ═══════════════════════════════════════════════════════════════
echo -e "${C}${BOLD}▸ Generating Depictions${RESET}"
COUNT=0

for deb in "$DEBS_DIR"/*.deb; do
  [ -e "$deb" ] || { echo -e "${Y}⚠  لا توجد ملفات .deb في $DEBS_DIR/${RESET}"; exit 0; }

  PKG_ID=$(dpkg-deb -f "$deb" Package 2>/dev/null || true)
  [ -z "$PKG_ID" ] && continue

  NAME=$(dpkg-deb -f "$deb" Name 2>/dev/null || true); [ -z "$NAME" ] && NAME="$PKG_ID"
  VERSION=$(dpkg-deb -f "$deb" Version 2>/dev/null || true); [ -z "$VERSION" ] && VERSION="1.0"
  AUTHOR=$(dpkg-deb -f "$deb" Author 2>/dev/null || true); [ -z "$AUTHOR" ] && AUTHOR="B6_7E"
  DESC=$(dpkg-deb -f "$deb" Description 2>/dev/null || true); [ -z "$DESC" ] && DESC="No description provided."
  SECTION=$(dpkg-deb -f "$deb" Section 2>/dev/null || true); [ -z "$SECTION" ] && SECTION="Tweaks"
  ARCH=$(dpkg-deb -f "$deb" Architecture 2>/dev/null || true); [ -z "$ARCH" ] && ARCH="iphoneos-arm64"

  SIZE=$(stat -c%s "$deb" 2>/dev/null || stat -f%z "$deb" 2>/dev/null || echo 0)
  if   [ "$SIZE" -ge 1048576 ]; then SIZE_H=$(awk "BEGIN{printf \"%.1f MB\",$SIZE/1048576}")
  elif [ "$SIZE" -ge 1024 ];    then SIZE_H=$(awk "BEGIN{printf \"%.0f KB\",$SIZE/1024}")
  else SIZE_H="${SIZE} B"; fi

  SHOTS_ARR=()
  if [ -d "$ASSETS_DIR/screenshots/$PKG_ID" ]; then
    while IFS= read -r f; do [ -n "$f" ] && SHOTS_ARR+=("$f"); done < <(
      find "$ASSETS_DIR/screenshots/$PKG_ID" -maxdepth 1 -type f \
        \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) 2>/dev/null | sort
    )
  fi

  OUT="$OUTPUT_DIR/$PKG_ID"
  mkdir -p "$OUT"

  export PKG_ID NAME VERSION AUTHOR DESC SECTION ARCH SIZE_H HEADER_URL DEFAULT_TINT
  export REPO_BASE TWITTER DISCORD GITHUB YOUTUBE TELEGRAM REDDIT WEBSITE
  export C_X C_DISCORD C_GITHUB C_YOUTUBE C_TELEGRAM C_REDDIT C_WEBSITE ASSETS_DIR

  SHOTS_LIST=""
  for f in "${SHOTS_ARR[@]:-}"; do
    [ -n "$f" ] && SHOTS_LIST+="$REPO_BASE/assets/screenshots/$PKG_ID/$(basename "$f")"$'\n'
  done
  export SHOTS_LIST

  # ── depiction.json ──
  python3 > "$OUT/depiction.json" << 'PYEOF'
import os, json
pkg, name, version = os.environ["PKG_ID"], os.environ["NAME"], os.environ["VERSION"]
author, desc = os.environ["AUTHOR"], os.environ["DESC"].replace("\n ", "\n").strip()
section, arch, size_h = os.environ["SECTION"], os.environ["ARCH"], os.environ["SIZE_H"]
header = os.environ["HEADER_URL"]; tint = os.environ["DEFAULT_TINT"]
assets_dir = os.environ["ASSETS_DIR"]

shot_urls = [l.strip() for l in os.environ.get("SHOTS_LIST","").split("\n") if l.strip()]
screenshots = [{"url":u,"fullSizeURL":u,"accessibilityText":f"Screenshot {i+1}"}
               for i,u in enumerate(shot_urls)]

ov = {}
p = os.path.join(assets_dir, "social", f"{pkg}.json")
if os.path.isfile(p):
    try: ov = json.load(open(p, encoding="utf-8"))
    except Exception: pass

tw = ov.get("twitter",  os.environ["TWITTER"])
dc = ov.get("discord",  os.environ["DISCORD"])
gh = ov.get("github",   os.environ["GITHUB"])
yt = ov.get("youtube",  os.environ["YOUTUBE"])
tg = ov.get("telegram", os.environ["TELEGRAM"])
rd = ov.get("reddit",   os.environ["REDDIT"])
wb = ov.get("website",  os.environ["WEBSITE"])

# ── أزرار التواصل الأصلية (DepictionButtonView) ──
social_buttons = [
    {"class": "DepictionButtonView",
     "action": f"https://twitter.com/{tw}",
     "title": "X (Twitter)",
     "subtitle": f"@{tw}",
     "icon": f"https://cdn.simpleicons.org/x/{os.environ['C_X']}",
     "iconCornerRadius": 10},

    {"class": "DepictionButtonView",
     "action": dc,
     "title": "Discord",
     "subtitle": "Join the server",
     "icon": f"https://cdn.simpleicons.org/discord/{os.environ['C_DISCORD']}",
     "iconCornerRadius": 10},

    {"class": "DepictionButtonView",
     "action": f"https://github.com/{gh}",
     "title": "GitHub",
     "subtitle": f"github.com/{gh}",
     "icon": f"https://cdn.simpleicons.org/github/{os.environ['C_GITHUB']}",
     "iconCornerRadius": 10},

    {"class": "DepictionButtonView",
     "action": yt,
     "title": "YouTube",
     "subtitle": "Watch videos",
     "icon": f"https://cdn.simpleicons.org/youtube/{os.environ['C_YOUTUBE']}",
     "iconCornerRadius": 10},

    {"class": "DepictionButtonView",
     "action": f"https://t.me/{tg}",
     "title": "Telegram",
     "subtitle": f"t.me/{tg}",
     "icon": f"https://cdn.simpleicons.org/telegram/{os.environ['C_TELEGRAM']}",
     "iconCornerRadius": 10},

    {"class": "DepictionButtonView",
     "action": f"https://reddit.com/user/{rd}",
     "title": "Reddit",
     "subtitle": f"u/{rd}",
     "icon": f"https://cdn.simpleicons.org/reddit/{os.environ['C_REDDIT']}",
     "iconCornerRadius": 10},

    {"class": "DepictionButtonView",
     "action": wb,
     "title": "Website",
     "subtitle": wb.replace("https://","").replace("http://",""),
     "icon": f"https://cdn.simpleicons.org/safari/{os.environ['C_WEBSITE']}",
     "iconCornerRadius": 10},
]

views = []
if screenshots:
    views.append({"class":"DepictionScreenshotsView","itemCornerRadius":14,
                  "itemSize":"{160, 275.4}","screenshots":screenshots})

views += [
    {"class":"DepictionHeaderView","title":name,"useBoldText":True},
    {"class":"DepictionSubheaderView","title":f"Version {version} • {size_h}","useBoldText":False},
    {"class":"DepictionSeparatorView"},
    {"class":"DepictionTableTextView","title":"Package","text":pkg},
    {"class":"DepictionTableTextView","title":"Version","text":version},
    {"class":"DepictionTableTextView","title":"Author","text":author},
    {"class":"DepictionTableTextView","title":"Section","text":section},
    {"class":"DepictionTableTextView","title":"Architecture","text":arch},
    {"class":"DepictionTableTextView","title":"Size","text":size_h},
    {"class":"DepictionSeparatorView"},
    {"class":"DepictionMarkdownView","markdown":"### Description\n\n"+desc},
    {"class":"DepictionSeparatorView"},
    {"class":"DepictionSubheaderView","title":"Connect","useBoldText":True},
]

views += social_buttons

dep = {"minVersion":"0.1","class":"DepictionTabView","tintColor":tint,
       "tabs":[{"tabname":"Details","class":"DepictionStackView","views":views}]}
if header: dep["headerImage"] = header
print(json.dumps(dep, indent=2, ensure_ascii=False))
PYEOF

  # ── index.html ──
  SHOTS_HTML=""
  for f in "${SHOTS_ARR[@]:-}"; do
    [ -n "$f" ] && SHOTS_HTML+="<img src=\"$REPO_BASE/assets/screenshots/$PKG_ID/$(basename "$f")\" alt=\"screenshot\">"
  done
  [ -z "$SHOTS_HTML" ] && SHOTS_HTML="<div class=\"no-shots\">No screenshots</div>"

  TW_="$TWITTER"; DC_="$DISCORD"; GH_="$GITHUB"; YT_="$YOUTUBE"
  TG_="$TELEGRAM"; RD_="$REDDIT"; WB_="$WEBSITE"
  if [ -f "$ASSETS_DIR/social/$PKG_ID.json" ]; then
    for kv in twitter discord github youtube telegram reddit website; do
      v=$(python3 -c "import json;print(json.load(open('$ASSETS_DIR/social/$PKG_ID.json')).get('$kv',''))" 2>/dev/null || true)
      [ -z "$v" ] && continue
      case $kv in
        twitter) TW_="$v";; discord) DC_="$v";; github) GH_="$v";;
        youtube) YT_="$v";; telegram) TG_="$v";; reddit) RD_="$v";; website) WB_="$v";;
      esac
    done
  fi

  SILEO_URL="sileo://depiction?url=$REPO_BASE/depictions/$PKG_ID/depiction.json"

  cat > "$OUT/index.html" << HTMLEOF
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
<title>$NAME — Depiction</title><style>
*{margin:0;padding:0;box-sizing:border-box;-webkit-tap-highlight-color:transparent}
body{font-family:-apple-system,BlinkMacSystemFont,"SF Pro Display","Segoe UI",Roboto,sans-serif;background:#000;color:#fff;min-height:100vh;padding-bottom:80px;-webkit-font-smoothing:antialiased}
.hero{position:relative;height:260px;background-image:url('$HEADER_URL');background-size:cover;background-position:center;display:flex;align-items:flex-end;padding:28px 24px;overflow:hidden}
.hero::after{content:'';position:absolute;inset:0;background:linear-gradient(to bottom,rgba(0,0,0,0.15),rgba(0,0,0,0.9))}
.hero-content{position:relative;z-index:2;width:100%}
.hero h1{font-size:32px;font-weight:800;letter-spacing:-0.6px;line-height:1.1}
.hero p{color:rgba(255,255,255,0.72);font-size:14px;margin-top:8px;font-weight:500}
.container{max-width:680px;margin:0 auto;padding:0 20px}
.screenshots{display:flex;gap:14px;overflow-x:auto;padding:28px 0 8px;scrollbar-width:none}
.screenshots::-webkit-scrollbar{display:none}
.screenshots img{width:160px;height:275px;border-radius:14px;object-fit:cover;flex-shrink:0;box-shadow:0 6px 24px rgba(0,0,0,0.55);border:1px solid rgba(255,255,255,0.08)}
.no-shots{padding:40px;text-align:center;color:#555;background:#1c1c1e;border-radius:16px}
.section{margin-top:28px}
.section h2{font-size:12px;font-weight:700;text-transform:uppercase;letter-spacing:1.4px;color:rgba(255,255,255,0.45);margin-bottom:12px;padding-left:4px}
.card{background:#1c1c1e;border-radius:16px;overflow:hidden;border:1px solid rgba(255,255,255,0.06)}
.row{display:flex;justify-content:space-between;padding:15px 18px;font-size:15px;border-bottom:1px solid rgba(255,255,255,0.05)}
.row:last-child{border-bottom:none}
.row .label{color:rgba(255,255,255,0.6)}
.row .value{color:#fff;font-weight:600;text-align:right;max-width:62%;word-break:break-word}
.desc{background:#1c1c1e;border-radius:16px;padding:20px;font-size:15px;line-height:1.7;border:1px solid rgba(255,255,255,0.06);white-space:pre-wrap}
.social{display:flex;flex-wrap:wrap;justify-content:center;gap:16px;background:#1c1c1e;border-radius:16px;padding:26px 18px;border:1px solid rgba(255,255,255,0.06)}
.social a{width:46px;height:46px;border-radius:50%;display:flex;align-items:center;justify-content:center;background:rgba(255,255,255,0.04);text-decoration:none;transition:transform .2s,background .2s}
.social a:hover{transform:translateY(-3px);background:rgba(255,255,255,0.1)}
.social a img{width:26px;height:26px}
.cta{display:block;text-align:center;text-decoration:none;background:$DEFAULT_TINT;color:#000;font-weight:700;font-size:16px;padding:17px;border-radius:14px;margin-top:28px}
.footer{text-align:center;color:rgba(255,255,255,0.25);font-size:12px;margin-top:44px}
</style></head><body>
<div class="hero"><div class="hero-content"><h1>$NAME</h1><p>Version $VERSION · $SIZE_H · $SECTION</p></div></div>
<div class="container">
<div class="screenshots">$SHOTS_HTML</div>
<div class="section"><h2>Information</h2><div class="card">
<div class="row"><span class="label">Package</span><span class="value">$PKG_ID</span></div>
<div class="row"><span class="label">Version</span><span class="value">$VERSION</span></div>
<div class="row"><span class="label">Author</span><span class="value">$AUTHOR</span></div>
<div class="row"><span class="label">Section</span><span class="value">$SECTION</span></div>
<div class="row"><span class="label">Architecture</span><span class="value">$ARCH</span></div>
<div class="row"><span class="label">Size</span><span class="value">$SIZE_H</span></div>
</div></div>
<div class="section"><h2>Description</h2><div class="desc">$DESC</div></div>
<div class="section"><h2>Connect</h2><div class="social">
<a href="https://twitter.com/$TW_" title="X"><img src="https://cdn.simpleicons.org/x/$C_X"></a>
<a href="$DC_" title="Discord"><img src="https://cdn.simpleicons.org/discord/$C_DISCORD"></a>
<a href="https://github.com/$GH_" title="GitHub"><img src="https://cdn.simpleicons.org/github/$C_GITHUB"></a>
<a href="$YT_" title="YouTube"><img src="https://cdn.simpleicons.org/youtube/$C_YOUTUBE"></a>
<a href="https://t.me/$TG_" title="Telegram"><img src="https://cdn.simpleicons.org/telegram/$C_TELEGRAM"></a>
<a href="https://reddit.com/user/$RD_" title="Reddit"><img src="https://cdn.simpleicons.org/reddit/$C_REDDIT"></a>
<a href="$WB_" title="Website"><img src="https://cdn.simpleicons.org/safari/$C_WEBSITE"></a>
</div></div>
<a class="cta" href="$SILEO_URL">Open in Sileo</a>
<div class="footer">$NAME · $VERSION · $PKG_ID</div>
</div></body></html>
HTMLEOF

  COUNT=$((COUNT+1))
  echo -e "  ${G}✓${RESET} ${W}$PKG_ID${RESET} ${DIM}→${RESET} ${C}$OUT/${RESET}"
done

echo -e "  ${BG_G}${W} TOTAL ${RESET} ${G}$COUNT${RESET} ${DIM}tweak(s) depicted${RESET}"
echo ""

# ═══════════════════════════════════════════════════════════════
#  BUILD PACKAGES  (apt-ftparchive as-is)
# ═══════════════════════════════════════════════════════════════
echo -e "${C}${BOLD}▸ Building Packages${RESET}"
apt-ftparchive packages ./debs > Packages
echo -e "  ${G}✓${RESET} ${W}Packages${RESET} ${DIM}generated by apt-ftparchive${RESET}"
echo ""

# ═══════════════════════════════════════════════════════════════
#  INJECT SileoDepiction + Depiction
# ═══════════════════════════════════════════════════════════════
echo -e "${C}${BOLD}▸ Injecting SileoDepiction${RESET}"
REPO_BASE="$REPO_BASE" python3 << 'PYEOF'
import os, re
repo_base = os.environ["REPO_BASE"]
with open("Packages", "r", encoding="utf-8") as f:
    content = f.read()

stanzas = re.split(r"\n\s*\n", content.strip())
out = []
for s in stanzas:
    s = s.strip()
    if not s: continue
    m = re.search(r"^Package:\s*(\S+)", s, re.MULTILINE)
    if not m:
        out.append(s); continue
    pkg = m.group(1).strip()
    lines = [l for l in s.split("\n")
             if not l.startswith("SileoDepiction:") and not l.startswith("Depiction:")]
    lines.append(f"SileoDepiction: {repo_base}/depictions/{pkg}/depiction.json")
    lines.append(f"Depiction: {repo_base}/depictions/{pkg}/index.html")
    out.append("\n".join(lines))
    print(f"  \033[1;32m✓\033[0m {pkg} \033[2m→\033[0m SileoDepiction + Depiction")

with open("Packages", "w", encoding="utf-8") as f:
    f.write("\n\n".join(out) + "\n")
PYEOF
echo ""

# ═══════════════════════════════════════════════════════════════
#  GIT PUSH
# ═══════════════════════════════════════════════════════════════
echo -e "${C}${BOLD}▸ Publishing to GitHub${RESET}"
git add --all
if git diff --cached --quiet; then
  echo -e "  ${Y}ℹ${RESET} لا توجد تغييرات جديدة"
else
  git commit -m "Init"
  git push
  echo -e "  ${BG_G}${W} PUSHED ${RESET} ${G}$REPO_BASE${RESET}"
fi

echo ""
echo -e "${M}${BOLD}╔══════════════════════════════════════════════════════════╗${RESET}"
echo -e "${M}${BOLD}║${RESET}  ${BG_G}${W}${BOLD}  ✅  DONE  ✅  ${RESET}                                    ${M}${BOLD}║${RESET}"
echo -e "${M}${BOLD}║${RESET}  ${DIM}$REPO_BASE${RESET}                       ${M}${BOLD}║${RESET}"
echo -e "${M}${BOLD}╚══════════════════════════════════════════════════════════╝${RESET}"
echo -e "${Y}${BOLD}              By B6_7E | بيكاس${RESET}"