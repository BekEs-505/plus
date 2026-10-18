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

R='\033[1;31m'; G='\033[1;32m'; Y='\033[1;33m'; B='\033[1;34m'
M='\033[1;35m'; C='\033[1;36m'; W='\033[1;37m'; DIM='\033[2m'
BOLD='\033[1m'; RESET='\033[0m'
BG_M='\033[45m'; BG_G='\033[42m'; BG_R='\033[41m'

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

# ── الترجمة التلقائية ──
AUTO_TRANSLATE=true
TRANSLATE_TIMEOUT=25
TRANSLATE_DELAY=1

# يوزراتك (بدون @)
X_HANDLE="B6_7E"
SNAPCHAT="B6_7E"
TELEGRAM="B6_7E"
INSTAGRAM="B6_7E"
TIKTOK="B6_7E"

# ألوان المنصات
C_X="1DA1F2"; C_SNAPCHAT="FFCC00"; C_TELEGRAM="26A5E4"
C_INSTAGRAM="E4405F"; C_TIKTOK="FE2C55"

# ═══════════════════════════════════════════════════════════════
#  CHECKS
# ═══════════════════════════════════════════════════════════════
echo -e "${C}${BOLD}▸ Checks${RESET}"
for cmd in dpkg-deb apt-ftparchive python3 git curl; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo -e "${BG_R}${W} MISSING ${RESET} ${R}$cmd${RESET} — ثبّته أولاً"
    exit 1
  fi
done
echo -e "  ${G}✓${RESET} كل الأدوات موجودة"
[ -d "$DEBS_DIR" ] || { echo -e "${R}❌ لا يوجد مجلد $DEBS_DIR/${RESET}"; exit 1; }
mkdir -p "$OUTPUT_DIR"
echo ""

# ═══════════════════════════════════════════════════════════════
#  TRANSLATE FUNCTION
# ═══════════════════════════════════════════════════════════════
translate_text() {
  local text="$1" from="$2" to="$3"
  [ -z "$text" ] && { printf ''; return 0; }
  [ "$from" = "$to" ] && { printf '%s' "$text"; return 0; }
  curl -s --max-time "$TRANSLATE_TIMEOUT" \
    -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15" \
    -G "https://translate.googleapis.com/translate_a/single" \
    --data-urlencode "client=gtx" \
    --data-urlencode "sl=$from" --data-urlencode "tl=$to" \
    --data-urlencode "dt=t" --data-urlencode "q=$text" 2>/dev/null \
  | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    sys.stdout.write(''.join(seg[0] for seg in d[0] if seg and seg[0]))
except Exception:
    pass
" 2>/dev/null || true
}

# ═══════════════════════════════════════════════════════════════
#  LOOP
# ═══════════════════════════════════════════════════════════════
echo -e "${C}${BOLD}▸ Generating Depictions${RESET}"
COUNT=0

for deb in "$DEBS_DIR"/*.deb; do
  [ -e "$deb" ] || { echo -e "${Y}⚠  لا توجد ملفات .deb${RESET}"; exit 0; }

  PKG_ID=$(dpkg-deb -f "$deb" Package 2>/dev/null || true)
  [ -z "$PKG_ID" ] && continue

  NAME=$(dpkg-deb -f "$deb" Name 2>/dev/null || true); [ -z "$NAME" ] && NAME="$PKG_ID"
  VERSION=$(dpkg-deb -f "$deb" Version 2>/dev/null || true); [ -z "$VERSION" ] && VERSION="1.0"
  AUTHOR=$(dpkg-deb -f "$deb" Author 2>/dev/null || true); [ -z "$AUTHOR" ] && AUTHOR="B6_7E | بيكاس"
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

  # ═══════════════════════════════════════════════════════════
  #  الوصف + الترجمة التلقائية (عربي أساسي)
  # ═══════════════════════════════════════════════════════════
  DESC_AR=""; DESC_EN=""
  if [ -f "$ASSETS_DIR/descriptions/$PKG_ID.json" ]; then
    DESC_AR=$(python3 -c "import json;print(json.load(open('$ASSETS_DIR/descriptions/$PKG_ID.json')).get('ar',''))" 2>/dev/null || true)
    DESC_EN=$(python3 -c "import json;print(json.load(open('$ASSETS_DIR/descriptions/$PKG_ID.json')).get('en',''))" 2>/dev/null || true)
  fi

  if [ "$AUTO_TRANSLATE" = "true" ]; then
    if [ -n "$DESC_AR" ] && [ -z "$DESC_EN" ]; then
      echo -e "    ${Y}↻${RESET} ${DIM}AR → EN...${RESET}"
      T=$(translate_text "$DESC_AR" "ar" "en")
      [ -n "$T" ] && DESC_EN="$T" || DESC_EN=""
      sleep "$TRANSLATE_DELAY"
    elif [ -n "$DESC_EN" ] && [ -z "$DESC_AR" ]; then
      echo -e "    ${Y}↻${RESET} ${DIM}EN → AR...${RESET}"
      T=$(translate_text "$DESC_EN" "en" "ar")
      [ -n "$T" ] && DESC_AR="$T" || DESC_AR=""
      sleep "$TRANSLATE_DELAY"
    fi
  fi

  # احتياط: إذا كلاهما فارغ → استخدم وصف deb في الاثنين
  if [ -z "$DESC_AR" ] && [ -z "$DESC_EN" ]; then
    DESC_AR="$DESC"; DESC_EN="$DESC"
  fi

  export PKG_ID NAME VERSION AUTHOR DESC SECTION ARCH SIZE_H HEADER_URL DEFAULT_TINT
  export REPO_BASE ASSETS_DIR DESC_AR DESC_EN
  export X_HANDLE SNAPCHAT TELEGRAM INSTAGRAM TIKTOK
  export C_X C_SNAPCHAT C_TELEGRAM C_INSTAGRAM C_TIKTOK

  SHOTS_LIST=""
  for f in "${SHOTS_ARR[@]:-}"; do
    [ -n "$f" ] && SHOTS_LIST+="$REPO_BASE/assets/screenshots/$PKG_ID/$(basename "$f")"$'\n'
  done
  export SHOTS_LIST

  # ═══════════════════════════════════════════════════════════
  #  depiction.json — تصميم احترافي جدًا
  # ═══════════════════════════════════════════════════════════
  python3 > "$OUT/depiction.json" << 'PYEOF'
import os, json

pkg, name, version = os.environ["PKG_ID"], os.environ["NAME"], os.environ["VERSION"]
author = os.environ["AUTHOR"]
section, arch, size_h = os.environ["SECTION"], os.environ["ARCH"], os.environ["SIZE_H"]
header = os.environ["HEADER_URL"]; tint = os.environ["DEFAULT_TINT"]
assets_dir = os.environ["ASSETS_DIR"]
desc_ar = os.environ.get("DESC_AR", "").replace("\n ", "\n").strip()
desc_en = os.environ.get("DESC_EN", "").replace("\n ", "\n").strip()

shot_urls = [l.strip() for l in os.environ.get("SHOTS_LIST","").split("\n") if l.strip()]
screenshots = [{"url":u,"fullSizeURL":u,"accessibilityText":f"Screenshot {i+1}"}
               for i,u in enumerate(shot_urls)]

ov = {}
p = os.path.join(assets_dir, "social", f"{pkg}.json")
if os.path.isfile(p):
    try: ov = json.load(open(p, encoding="utf-8"))
    except Exception: pass

x_h  = ov.get("x",         os.environ["X_HANDLE"])
snap = ov.get("snapchat",  os.environ["SNAPCHAT"])
tg   = ov.get("telegram",  os.environ["TELEGRAM"])
ig   = ov.get("instagram", os.environ["INSTAGRAM"])
tt   = ov.get("tiktok",    os.environ["TIKTOK"])

# ══════════════════════════════════════════════════════════════
#  وصف مدمج واحد — عربي أولًا ثم إنجليزي
# ══════════════════════════════════════════════════════════════
desc_parts = []
if desc_ar:
    desc_parts.append(f"### 🇸🇦 الوصف بالعربية\n\n{desc_ar}")
if desc_en:
    desc_parts.append(f"### 🇬🇧 English Description\n\n{desc_en}")
merged_desc = "\n\n---\n\n".join(desc_parts) if desc_parts else "لا يوجد وصف / No description."

# ══════════════════════════════════════════════════════════════
#  TAB 1 — Details (تصميم احترافي كامل)
# ══════════════════════════════════════════════════════════════
details_views = []

# ① Screenshots
if screenshots:
    details_views.append({
        "class": "DepictionScreenshotsView",
        "itemCornerRadius": 16,
        "itemSize": "{160, 275.4}",
        "screenshots": screenshots
    })
    details_views.append({"class": "DepictionSpacerView", "spacing": 10})

# ② Title block
details_views += [
    {"class": "DepictionHeaderView", "title": name, "useBoldText": True},
    {"class": "DepictionSubheaderView",
     "title": f"v{version}  •  {size_h}  •  {section}",
     "useBoldText": False},
    {"class": "DepictionSeparatorView"},
]

# ③ Information section
details_views += [
    {"class": "DepictionHeaderView", "title": "📋  Information", "useBoldText": True},
    {"class": "DepictionTableTextView", "title": "📦  Package",       "text": pkg},
    {"class": "DepictionTableTextView", "title": "🔢  Version",       "text": version},
    {"class": "DepictionTableTextView", "title": "💾  Size",          "text": size_h},
    {"class": "DepictionTableTextView", "title": "🏗️  Architecture",  "text": arch},
    {"class": "DepictionTableTextView", "title": "🗂️  Section",       "text": section},
    {"class": "DepictionTableTextView", "title": "👨‍💻  Author",        "text": author},
    {"class": "DepictionTableTextView", "title": "📱  Compatibility", "text": "iOS 14.0 – iOS 18.x"},
    {"class": "DepictionSeparatorView"},
]

# ④ Description section (وصف واحد مدمج)
details_views += [
    {"class": "DepictionHeaderView", "title": "📝  Description", "useBoldText": True},
    {"class": "DepictionMarkdownView", "markdown": merged_desc},
    {"class": "DepictionSeparatorView"},
]

# ⑤ Footer
details_views += [
    {"class": "DepictionSpacerView", "spacing": 8},
    {"class": "DepictionMarkdownView",
     "markdown": "<div align='center'>\n\n**❤️ Made with love by B6_7E | بيكاس**\n\n</div>"},
    {"class": "DepictionSpacerView", "spacing": 8},
]

# ══════════════════════════════════════════════════════════════
#  TAB 2 — Social Media (بدون تغيير)
# ══════════════════════════════════════════════════════════════
social_views = [
    {"class": "DepictionSubheaderView", "title": "🌐  Follow & Connect", "useBoldText": True},
    {"class": "DepictionMarkdownView", "markdown": "اضفني على التواصل الاجتماعي تحت — Follow me on social media."},
    {"class": "DepictionSeparatorView"},
    {"class": "DepictionTableButtonView", "title": "X (Twitter)",
     "action": f"https://twitter.com/{x_h}",
     "icon": f"https://cdn.simpleicons.org/x/{os.environ['C_X']}",
     "iconCornerRadius": 8, "chevron": True},
    {"class": "DepictionTableButtonView", "title": "Snapchat",
     "action": f"https://snapchat.com/add/{snap}",
     "icon": f"https://cdn.simpleicons.org/snapchat/{os.environ['C_SNAPCHAT']}",
     "iconCornerRadius": 8, "chevron": True},
    {"class": "DepictionTableButtonView", "title": "Telegram",
     "action": f"https://t.me/{tg}",
     "icon": f"https://cdn.simpleicons.org/telegram/{os.environ['C_TELEGRAM']}",
     "iconCornerRadius": 8, "chevron": True},
    {"class": "DepictionTableButtonView", "title": "Instagram",
     "action": f"https://instagram.com/{ig}",
     "icon": f"https://cdn.simpleicons.org/instagram/{os.environ['C_INSTAGRAM']}",
     "iconCornerRadius": 8, "chevron": True},
    {"class": "DepictionTableButtonView", "title": "TikTok",
     "action": f"https://tiktok.com/@{tt}",
     "icon": f"https://cdn.simpleicons.org/tiktok/{os.environ['C_TIKTOK']}",
     "iconCornerRadius": 8, "chevron": True},
    {"class": "DepictionSeparatorView"},
    {"class": "DepictionMarkdownView", "markdown": "*لبى براطمها ❤️  —  Thanks for your support*"},
]

dep = {
    "minVersion": "0.1",
    "class": "DepictionTabView",
    "tintColor": tint,
    "tabs": [
        {"tabname": "Details", "class": "DepictionStackView", "views": details_views},
        {"tabname": "Social Media", "class": "DepictionStackView", "views": social_views},
    ]
}
if header: dep["headerImage"] = header
print(json.dumps(dep, indent=2, ensure_ascii=False))
PYEOF

  # ═══════════════════════════════════════════════════════════
  #  index.html — بدون تغيير (نفس السابق)
  # ═══════════════════════════════════════════════════════════
  SHOTS_HTML=""
  for f in "${SHOTS_ARR[@]:-}"; do
    [ -n "$f" ] && SHOTS_HTML+="<img src=\"$REPO_BASE/assets/screenshots/$PKG_ID/$(basename "$f")\" alt=\"screenshot\">"
  done
  [ -z "$SHOTS_HTML" ] && SHOTS_HTML="<div class=\"no-shots\">No screenshots</div>"

  X_="$X_HANDLE"; SN_="$SNAPCHAT"; TG_="$TELEGRAM"; IG_="$INSTAGRAM"; TT_="$TIKTOK"
  if [ -f "$ASSETS_DIR/social/$PKG_ID.json" ]; then
    for kv in x snapchat telegram instagram tiktok; do
      v=$(python3 -c "import json;print(json.load(open('$ASSETS_DIR/social/$PKG_ID.json')).get('$kv',''))" 2>/dev/null || true)
      [ -z "$v" ] && continue
      case $kv in
        x) X_="$v";; snapchat) SN_="$v";; telegram) TG_="$v";;
        instagram) IG_="$v";; tiktok) TT_="$v";;
      esac
    done
  fi

  SILEO_URL="sileo://depiction?url=$REPO_BASE/depictions/$PKG_ID/depiction.json"

  cat > "$OUT/index.html" << HTMLEOF
<!DOCTYPE html><html lang="ar" dir="rtl"><head><meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
<title>$NAME — Depiction</title><style>
*{margin:0;padding:0;box-sizing:border-box;-webkit-tap-highlight-color:transparent}
body{font-family:-apple-system,BlinkMacSystemFont,"SF Arabic","SF Pro Display","Segoe UI",Roboto,sans-serif;background:#000;color:#fff;min-height:100vh;padding-bottom:80px;-webkit-font-smoothing:antialiased}
.hero{position:relative;height:260px;background-image:url('$HEADER_URL');background-size:cover;background-position:center;display:flex;align-items:flex-end;padding:28px 24px;overflow:hidden}
.hero::after{content:'';position:absolute;inset:0;background:linear-gradient(to bottom,rgba(0,0,0,0.15),rgba(0,0,0,0.9))}
.hero-content{position:relative;z-index:2;width:100%}
.hero h1{font-size:32px;font-weight:800;letter-spacing:-0.6px;line-height:1.1}
.hero p{color:rgba(255,255,255,0.72);font-size:14px;margin-top:8px;font-weight:500}
.container{max-width:680px;margin:0 auto;padding:0 20px}
.screenshots{display:flex;gap:14px;overflow-x:auto;padding:28px 0 8px;scrollbar-width:none}
.screenshots::-webkit-scrollbar{display:none}
.screenshots img{width:160px;height:275px;border-radius:14px;object-fit:cover;flex-shrink:0;box-shadow:0 6px 24px rgba(0,0,0,0.55);border:1px solid rgba(255,255,255,0.08)}
.no-shots{padding:40px;text-align:center;color:#555;background:#1c1c1e;border-radius:16px;width:100%}
.section{margin-top:28px}
.section h2{font-size:12px;font-weight:700;text-transform:uppercase;letter-spacing:1.4px;color:rgba(255,255,255,0.45);margin-bottom:12px;padding:0 4px}
.card{background:#1c1c1e;border-radius:16px;overflow:hidden;border:1px solid rgba(255,255,255,0.06)}
.row{display:flex;justify-content:space-between;padding:15px 18px;font-size:15px;border-bottom:1px solid rgba(255,255,255,0.05)}
.row:last-child{border-bottom:none}
.row .label{color:rgba(255,255,255,0.6)}
.row .value{color:#fff;font-weight:600;text-align:left;direction:ltr;max-width:62%;word-break:break-word}
.desc{background:#1c1c1e;border-radius:16px;padding:20px;font-size:15px;line-height:1.8;border:1px solid rgba(255,255,255,0.06);white-space:pre-wrap;word-wrap:break-word}
.desc.en{direction:ltr;text-align:left;font-family:-apple-system,BlinkMacSystemFont,"SF Pro Display",sans-serif}
.social{display:flex;flex-direction:column;gap:10px;background:#1c1c1e;border-radius:16px;padding:14px;border:1px solid rgba(255,255,255,0.06)}
.social a{display:flex;align-items:center;gap:14px;text-decoration:none;color:#fff;padding:12px 14px;border-radius:12px;transition:background .2s;font-size:16px;font-weight:500}
.social a:hover{background:rgba(255,255,255,0.06)}
.social a img{width:32px;height:32px;border-radius:8px;flex-shrink:0}
.social a span{flex:1;text-align:right}
.social a.en span{text-align:left;direction:ltr}
.social a .arrow{color:rgba(255,255,255,0.35);font-weight:400;direction:ltr}
.cta{display:block;text-align:center;text-decoration:none;background:$DEFAULT_TINT;color:#000;font-weight:700;font-size:16px;padding:17px;border-radius:14px;margin-top:28px}
.footer{text-align:center;color:rgba(255,255,255,0.25);font-size:12px;margin-top:44px}
</style></head><body>
<div class="hero"><div class="hero-content"><h1>$NAME</h1><p>Version $VERSION · $SIZE_H · $SECTION</p></div></div>
<div class="container">
<div class="screenshots">$SHOTS_HTML</div>
<div class="section"><h2>المعلومات · Information</h2><div class="card">
<div class="row"><span class="label">Package</span><span class="value">$PKG_ID</span></div>
<div class="row"><span class="label">Version</span><span class="value">$VERSION</span></div>
<div class="row"><span class="label">Author</span><span class="value">$AUTHOR</span></div>
<div class="row"><span class="label">Section</span><span class="value">$SECTION</span></div>
<div class="row"><span class="label">Architecture</span><span class="value">$ARCH</span></div>
<div class="row"><span class="label">Size</span><span class="value">$SIZE_H</span></div>
</div></div>
<div class="section"><h2>🇸🇦 الوصف بالعربية</h2><div class="desc">$DESC_AR</div></div>
<div class="section"><h2>🇬🇧 English Description</h2><div class="desc en">$DESC_EN</div></div>
<div class="section"><h2>🌐 Social Media</h2><div class="social">
<a href="https://twitter.com/$X_" target="_blank"><img src="https://cdn.simpleicons.org/x/$C_X" alt="X"><span class="en">X (Twitter)</span><span class="arrow">‹</span></a>
<a href="https://snapchat.com/add/$SN_" target="_blank"><img src="https://cdn.simpleicons.org/snapchat/$C_SNAPCHAT" alt="Snapchat"><span class="en">Snapchat</span><span class="arrow">‹</span></a>
<a href="https://t.me/$TG_" target="_blank"><img src="https://cdn.simpleicons.org/telegram/$C_TELEGRAM" alt="Telegram"><span class="en">Telegram</span><span class="arrow">‹</span></a>
<a href="https://instagram.com/$IG_" target="_blank"><img src="https://cdn.simpleicons.org/instagram/$C_INSTAGRAM" alt="Instagram"><span class="en">Instagram</span><span class="arrow">‹</span></a>
<a href="https://tiktok.com/@$TT_" target="_blank"><img src="https://cdn.simpleicons.org/tiktok/$C_TIKTOK" alt="TikTok"><span class="en">TikTok</span><span class="arrow">‹</span></a>
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
#  BUILD PACKAGES
# ═══════════════════════════════════════════════════════════════
echo -e "${C}${BOLD}▸ Building Packages${RESET}"
apt-ftparchive packages ./debs > Packages
echo -e "  ${G}✓${RESET} ${W}Packages${RESET} ${DIM}generated${RESET}"
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