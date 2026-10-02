#!/var/jb/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════
#  generate_depictions.sh v7.0 — iOS Rootless Edition (NewTerm)
#  - Shebang rootless iOS: /var/jb/usr/bin/env bash
#  - لا set -e — لمنع الخروج الصامت
#  - يعمل على Dopamine / Palera1n / XinaA15
#  - متوافق مع Procursus و Sileo
# ═══════════════════════════════════════════════════════════════════════

set -u

PACKAGES_FILE="Packages"
OUT_DIR="depictions"
CONFIG_FILE="config.json"
IMAGES_FILE="images.json"
TEMPLATE_FILE="template.json"
EDIT_PACKAGE=""
BASE_URL=""
FORCE=0
ASK_IMAGES=0
DRY_RUN=0
VERBOSE=0
UPDATE_PACKAGES=0

STAT_TOTAL=0; STAT_OK=0; STAT_FAIL=0; STAT_SKIP=0

if [ -t 1 ]; then
    RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[0;33m'
    CYAN=$'\033[0;36m'; BOLD=$'\033[1m';   RESET=$'\033[0m'
else
    RED=''; GREEN=''; YELLOW=''; CYAN=''; BOLD=''; RESET=''
fi

log()  { printf '%s[*]%s %s\n' "$CYAN"   "$RESET" "$*"; }
ok()   { printf '%s[+]%s %s\n' "$GREEN"  "$RESET" "$*"; }
warn() { printf '%s[!]%s %s\n' "$YELLOW" "$RESET" "$*"; }
err()  { printf '%s[x]%s %s\n' "$RED"    "$RESET" "$*" >&2; }
dbg()  { if [ "$VERBOSE" = "1" ]; then printf '[.] %s\n' "$*"; fi; return 0; }

wait_for_enter() {
    if [ ! -t 1 ]; then
        echo ""
        printf 'اضغط Enter للإغلاق... '
        read -r _ < /dev/tty 2>/dev/null || true
    fi
}

die() { err "$*"; wait_for_enter; exit 1; }

usage() {
    cat <<EOF
الاستخدام: bash $0 [OPTIONS]

  -p, --packages FILE     مسار Packages (افتراضي: Packages)
  -o, --out-dir DIR       مجلد الإخراج (افتراضي: depictions)
  -c, --config FILE       ملف الإعدادات (افتراضي: config.json)
      --images FILE       ملف الصور (افتراضي: images.json)
  -e, --edit PKG          توليد لحزمة واحدة فقط
  -i, --ask-images        سؤال تفاعلي لصورة كل أداة
  -f, --force             إعادة توليد حتى الموجود
      --update-packages   إضافة حقول Depiction/SileoDepiction لـ Packages
      --base-url URL      رابط أساسي (مع --update-packages)
  -n, --dry-run           معاينة بدون كتابة
  -v, --verbose           سجل تفصيلي
  -h, --help              هذه الرسالة
  -V, --version           الإصدار
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        -p|--packages)     PACKAGES_FILE="${2:-}"; shift 2 ;;
        -o|--out-dir)      OUT_DIR="${2:-}";       shift 2 ;;
        -c|--config)       CONFIG_FILE="${2:-}";   shift 2 ;;
        --images)          IMAGES_FILE="${2:-}";   shift 2 ;;
        -e|--edit)         EDIT_PACKAGE="${2:-}";  shift 2 ;;
        --base-url)        BASE_URL="${2:-}";      shift 2 ;;
        -i|--ask-images)   ASK_IMAGES=1;           shift ;;
        -f|--force)        FORCE=1;                shift ;;
        --update-packages) UPDATE_PACKAGES=1;      shift ;;
        -n|--dry-run)      DRY_RUN=1;              shift ;;
        -v|--verbose)      VERBOSE=1;              shift ;;
        -h|--help)         usage; exit 0 ;;
        -V|--version)      echo "7.0.0"; exit 0 ;;
        --) shift; break ;;
        *) die "خيار غير معروف: $1 (استخدم --help)" ;;
    esac
done

printf '%s════════════════════════════════════════════════════%s\n' "$CYAN" "$RESET"
printf '%s   generate_depictions.sh v7.0 (iOS Rootless)%s\n' "$BOLD" "$RESET"
printf '%s════════════════════════════════════════════════════%s\n' "$CYAN" "$RESET"
echo ""
log "التاريخ: $(date '+%Y-%m-%d %H:%M:%S')"
log "المجلد: $(pwd)"
log "Bash: $BASH_VERSION"
echo ""

# ─── فحص المتطلبات ───
log "فحص المتطلبات..."
MISSING=""
for cmd in jq awk sed grep mktemp mv mkdir cat; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        MISSING="$MISSING $cmd"
    fi
done

if [ -n "$MISSING" ]; then
    err "أدوات مفقودة:$MISSING"
    err "ثبّتها من Sileo: jq coreutils gawk"
    wait_for_enter; exit 1
fi
JQ_VER="$(jq --version 2>/dev/null | sed 's/^jq-//')"
ok "jq $JQ_VER — awk — sed — grep — mktemp"

# تحقق أن walk() متوفرة (jq 1.6+)
if ! echo 'null' | jq 'walk(.)' >/dev/null 2>&1; then
    die "jq قديم ($JQ_VER). يتطلب 1.6+ لدعم walk(). ثبّت jq الأحدث من Sileo."
fi
ok "jq يدعم walk() بنجاح"

# ─── فحص ملف Packages ───
if [ ! -f "$PACKAGES_FILE" ]; then
    err "ملف Packages غير موجود: $(pwd)/$PACKAGES_FILE"
    err "تأكد أنك في مجلد المستودع، أو استخدم: -p /path/to/Packages"
    wait_for_enter; exit 1
fi
ok "ملف Packages موجود"

# ─── الملفات الافتراضية ───
if [ ! -f "$CONFIG_FILE" ]; then
    warn "إنشاء $CONFIG_FILE (عدّله لاحقاً بحساباتك)"
    cat > "$CONFIG_FILE" << 'CFG_EOF'
{
  "headerImage": "",
  "twitter":     "",
  "discord":     "",
  "github":      "",
  "youtube":     "",
  "reddit":      "",
  "paypal":      "",
  "website":     "",
  "email":       ""
}
CFG_EOF
    ok "تم إنشاء $CONFIG_FILE"
fi

if [ ! -f "$IMAGES_FILE" ]; then
    echo '{}' > "$IMAGES_FILE"
    dbg "تم إنشاء $IMAGES_FILE"
fi

if [ ! -f "$TEMPLATE_FILE" ]; then
    warn "إنشاء $TEMPLATE_FILE"
    cat > "$TEMPLATE_FILE" << 'TPL_EOF'
{
  "minVersion": "0.1",
  "class": "DepictionTabView",
  "tintColor": "#2cb1be",
  "headerImage": "__HEADER_IMAGE__",
  "tabs": [
    {
      "tabname": "Details",
      "class": "DepictionStackView",
      "views": [
        { "class": "DepictionImageView", "url": "__ICON__", "width": 100, "height": 100, "alignment": 2, "cornerRadius": 22 },
        { "class": "DepictionHeaderView", "title": "__NAME__", "subtitle": "Version __VERSION__" },
        { "class": "DepictionMarkdownView", "markdown": "__DESCRIPTION__", "useRawFormat": true },
        { "class": "DepictionSeparatorView" },
        { "title": "Developer", "text": "__AUTHOR__",  "class": "DepictionTableTextView" },
        { "title": "Package",   "text": "__PACKAGE__", "class": "DepictionTableTextView" },
        { "title": "Section",   "text": "__SECTION__", "class": "DepictionTableTextView" },
        { "title": "Depends",   "text": "__DEPENDS__", "class": "DepictionTableTextView" }
      ]
    },
    {
      "tabname": "Links",
      "class": "DepictionStackView",
      "views": [
        { "title": "Twitter",  "action": "https://twitter.com/__TWITTER__",   "class": "DepictionTableButtonView", "openExternal": true },
        { "title": "Discord",  "action": "__DISCORD__",                        "class": "DepictionTableButtonView", "openExternal": true },
        { "title": "GitHub",   "action": "https://github.com/__GITHUB__",      "class": "DepictionTableButtonView", "openExternal": true },
        { "title": "YouTube",  "action": "https://youtube.com/__YOUTUBE__",    "class": "DepictionTableButtonView", "openExternal": true },
        { "title": "Reddit",   "action": "https://reddit.com/user/__REDDIT__", "class": "DepictionTableButtonView", "openExternal": true },
        { "title": "PayPal",   "action": "https://paypal.me/__PAYPAL__",       "class": "DepictionTableButtonView", "openExternal": true },
        { "title": "Website",  "action": "__WEBSITE__",                        "class": "DepictionTableButtonView", "openExternal": true },
        { "title": "Email",    "action": "mailto:__EMAIL__",                   "class": "DepictionTableButtonView", "openExternal": true }
      ]
    }
  ]
}
TPL_EOF
    ok "تم إنشاء $TEMPLATE_FILE"
fi

# تحقق من صلاحية JSON
for f in "$CONFIG_FILE" "$IMAGES_FILE" "$TEMPLATE_FILE"; do
    if ! jq empty "$f" >/dev/null 2>&1; then
        die "الملف ليس JSON صالحاً: $f"
    fi
done
ok "ملفات JSON صالحة"

# ─── قراءة الإعدادات ───
get_cfg() {
    jq -r --arg k "$1" '.[$k] // ""' "$CONFIG_FILE" 2>/dev/null || printf ''
}

get_image_for() {
    jq -r --arg p "$1" '.[$p] // ""' "$IMAGES_FILE" 2>/dev/null || printf ''
}

# ─── سؤال تفاعلي للصورة ───
ask_image_for() {
    local pkg="$1"
    local existing
    existing="$(get_image_for "$pkg")"

    if [ ! -c /dev/tty ]; then
        return 0
    fi

    local answer=""
    if [ -n "$existing" ]; then
        printf '%s[?]%s %s لديها صورة محفوظة\n' "$YELLOW" "$RESET" "$pkg"
        printf '%s[?]%s هل تريد تغييرها؟ [y/N] ' "$YELLOW" "$RESET"
    else
        printf '%s[?]%s هل تريد إضافة صورة للأداة %s؟ [y/N] ' "$YELLOW" "$RESET" "$pkg"
    fi
    read -r answer < /dev/tty 2>/dev/null || answer=""

    case "$answer" in
        y|Y|yes|YES|Yes) ;;
        *) return 0 ;;
    esac

    printf '%s[?]%s أدخل رابط الصورة: ' "$YELLOW" "$RESET"
    local url=""
    read -r url < /dev/tty 2>/dev/null || url=""

    url="${url#"${url%%[![:space:]]*}"}"
    url="${url%"${url##*[![:space:]]}"}"

    if [ -z "$url" ]; then
        warn "لم يتم إدخال رابط — تخطي"
        return 0
    fi

    local tmp
    tmp="$(mktemp)"
    if jq --arg p "$pkg" --arg u "$url" '. + {($p): $u}' "$IMAGES_FILE" > "$tmp" 2>/dev/null; then
        mv -f "$tmp" "$IMAGES_FILE"
        ok "تم حفظ الصورة لـ $pkg"
    else
        rm -f "$tmp"
        warn "فشل حفظ الصورة"
    fi
    return 0
}

# ─── استخراج حقل من فقرة Packages ───
extract_field() {
    local block="$1"
    local key="$2"
    printf '%s' "$block" | awk -v key="$key" '
        BEGIN { found = 0; result = "" }
        {
            gsub(/\r/, "")
            if ($0 ~ "^" key ":") {
                sub("^" key ":[ \t]*", "")
                result = $0
                found = 1
                next
            }
            if (found && $0 ~ /^[ \t]/) {
                line = $0
                sub(/^[ \t]+/, "", line)
                if (line == ".") line = ""
                result = result "\n" line
                next
            }
            if (found) exit
        }
        END {
            sub(/\n$/, "", result)
            printf "%s", result
        }
    '
}

# ─── توليد JSON للـ depiction ───
generate_json() {
    local pkg="$1" name="$2" version="$3" author="$4"
    local description="$5" section="$6" depends="$7" icon="$8"

    local header twitter discord github youtube reddit paypal website email
    header="$(get_cfg headerImage)"
    twitter="$(get_cfg twitter)"
    discord="$(get_cfg discord)"
    github="$(get_cfg github)"
    youtube="$(get_cfg youtube)"
    reddit="$(get_cfg reddit)"
    paypal="$(get_cfg paypal)"
    website="$(get_cfg website)"
    email="$(get_cfg email)"

    jq -n \
        --arg pkg "$pkg" \
        --arg name "$name" \
        --arg version "$version" \
        --arg author "$author" \
        --arg description "$description" \
        --arg section "$section" \
        --arg depends "$depends" \
        --arg icon "$icon" \
        --arg header "$header" \
        --arg twitter "$twitter" \
        --arg discord "$discord" \
        --arg github "$github" \
        --arg youtube "$youtube" \
        --arg reddit "$reddit" \
        --arg paypal "$paypal" \
        --arg website "$website" \
        --arg email "$email" \
        --slurpfile tpl "$TEMPLATE_FILE" '
        def rp:
            gsub("__PACKAGE__";      $pkg)         |
            gsub("__NAME__";         $name)        |
            gsub("__VERSION__";      $version)     |
            gsub("__AUTHOR__";       $author)      |
            gsub("__DESCRIPTION__";  $description) |
            gsub("__SECTION__";      $section)     |
            gsub("__DEPENDS__";      $depends)     |
            gsub("__ICON__";         $icon)        |
            gsub("__HEADER_IMAGE__"; $header)      |
            gsub("__TWITTER__";      $twitter)     |
            gsub("__DISCORD__";      $discord)     |
            gsub("__GITHUB__";       $github)      |
            gsub("__YOUTUBE__";      $youtube)     |
            gsub("__REDDIT__";       $reddit)      |
            gsub("__PAYPAL__";       $paypal)      |
            gsub("__WEBSITE__";      $website)     |
            gsub("__EMAIL__";        $email);

        def is_valid_action:
            if test("^mailto:") then
                test("^mailto:.+@.+")
            else
                (test("://.+/") and (test("://[^/]*/?$") | not))
            end;

        ($tpl[0] | walk(if type == "string" then rp else . end))
        | walk(
            if type == "array" then
                map(
                    if (type == "object" and .class == "DepictionImageView" and ((.url // "") == "")) then
                        { "class": "DepictionSpacerView", "spacing": 1 }
                    elif (type == "object" and has("action")) then
                        select(.action | is_valid_action)
                    else . end
                )
            else . end
        )
    '
}

# ─── معالجة حزمة واحدة ───
process_package() {
    local block="$1"
    local pkg="$2"

    local name version author maintainer section depends description
    name="$(extract_field "$block" "Name")"
    version="$(extract_field "$block" "Version")"
    author="$(extract_field "$block" "Author")"
    maintainer="$(extract_field "$block" "Maintainer")"
    section="$(extract_field "$block" "Section")"
    depends="$(extract_field "$block" "Depends")"
    description="$(extract_field "$block" "Description")"

    [ -z "$name" ]    && name="$pkg"
    [ -z "$author" ]  && author="${maintainer:-Unknown}"
    [ -z "$version" ] && version="0.0.0"
    [ -z "$section" ] && section="Tweaks"
    [ -z "$description" ] && description="No description available."

    if [ "$ASK_IMAGES" = "1" ]; then
        ask_image_for "$pkg"
    fi

    local icon
    icon="$(get_image_for "$pkg")"

    local bundle_dir="$OUT_DIR/$pkg"
    local depiction_file="$bundle_dir/depiction.json"

    if [ "$DRY_RUN" = "1" ]; then
        log "DRY: $depiction_file"
        return 0
    fi

    if ! mkdir -p "$bundle_dir"; then
        err "فشل إنشاء المجلد: $bundle_dir"
        return 1
    fi

    local tmp
    tmp="$(mktemp "$bundle_dir/.tmp.XXXXXX" 2>/dev/null)" || {
        tmp="$bundle_dir/.tmp.$$"
    }

    local errf="${tmp}.err"

    if ! generate_json "$pkg" "$name" "$version" "$author" \
                       "$description" "$section" "$depends" "$icon" \
                       > "$tmp" 2> "$errf"; then
        err "فشل توليد JSON: $pkg"
        if [ -s "$errf" ]; then
            sed 's/^/    jq> /' "$errf" >&2
        fi
        rm -f "$tmp" "$errf"
        return 1
    fi
    rm -f "$errf"

    if ! jq empty "$tmp" >/dev/null 2>&1; then
        err "JSON الناتج غير صالح: $pkg"
        head -5 "$tmp" | sed 's/^/    > /' >&2
        rm -f "$tmp"
        return 1
    fi

    if ! mv -f "$tmp" "$depiction_file"; then
        err "فشل النقل إلى: $depiction_file"
        rm -f "$tmp"
        return 1
    fi

    jq -n \
        --arg pkg "$pkg" \
        --arg name "$name" \
        --arg version "$version" \
        --arg generated "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        '{ package: $pkg, name: $name, version: $version, generated: $generated }' \
        > "$bundle_dir/.bundle-meta.json" 2>/dev/null || true

    return 0
}

# ─── تحديث ملف Packages بحقول Depiction ───
update_packages_file() {
    local base="${BASE_URL%/}"
    if [ -z "$base" ]; then
        warn "تجاهل --update-packages بلا --base-url"
        return 0
    fi
    if [ "$DRY_RUN" = "1" ]; then
        log "DRY: تحديث $PACKAGES_FILE"
        return 0
    fi

    log "تحديث $PACKAGES_FILE"
    local tmp
    tmp="$(mktemp 2>/dev/null)" || tmp="/tmp/pkg.$$"

    awk -v base="$base" '
        function flush() {
            if (pkg_name == "") return
            printf "%s", pkg
            if (!has_dep)  printf "Depiction: %s/%s/depiction.json\n", base, pkg_name
            if (!has_sdep) printf "SileoDepiction: %s/%s/depiction.json\n", base, pkg_name
        }
        /^[ \t]*$/ {
            flush()
            print ""
            pkg=""; pkg_name=""; has_dep=0; has_sdep=0
            next
        }
        /^Package:/ {
            if (pkg_name != "") flush()
            pkg_name = $0
            sub(/^Package:[ \t]*/, "", pkg_name)
        }
        /^Depiction:/      { has_dep  = 1 }
        /^SileoDepiction:/ { has_sdep = 1 }
        { gsub(/\r/, ""); pkg = pkg $0 "\n" }
        END { flush() }
    ' "$PACKAGES_FILE" > "$tmp"

    mv -f "$tmp" "$PACKAGES_FILE"
    ok "تم تحديث $PACKAGES_FILE"
}

# ─── التنفيذ ───
mkdir -p "$OUT_DIR" || die "فشل إنشاء $OUT_DIR"
ok "مجلد الإخراج: $OUT_DIR"

echo ""
log "بدء قراءة الحزم من $PACKAGES_FILE..."
echo ""

while IFS= read -r -d '' block; do
    stripped="${block//[[:space:]]/}"
    if [ -z "$stripped" ]; then
        continue
    fi

    pkg="$(extract_field "$block" "Package")"
    if [ -z "$pkg" ]; then
        continue
    fi

    STAT_TOTAL=$((STAT_TOTAL + 1))

    if [ -n "$EDIT_PACKAGE" ] && [ "$pkg" != "$EDIT_PACKAGE" ]; then
        continue
    fi

    df="$OUT_DIR/$pkg/depiction.json"
    if [ -f "$df" ] && [ "$FORCE" = "0" ] && [ "$DRY_RUN" = "0" ] && [ "$ASK_IMAGES" = "0" ]; then
        dbg "تخطي (موجود): $pkg"
        STAT_SKIP=$((STAT_SKIP + 1))
        continue
    fi

    log "معالجة: $pkg"

    if process_package "$block" "$pkg"; then
        ok "تم: $pkg"
        STAT_OK=$((STAT_OK + 1))
    else
        err "فشل: $pkg"
        STAT_FAIL=$((STAT_FAIL + 1))
    fi
done < <(awk -v RS='' -v ORS='\0' 'NF { gsub(/\r/, ""); print }' "$PACKAGES_FILE")

echo ""

if [ "$UPDATE_PACKAGES" = "1" ]; then
    update_packages_file
fi

printf '%s════════════════════════════════════════════════════%s\n' "$CYAN" "$RESET"
printf '  إجمالي الحزم : %d\n' "$STAT_TOTAL"
printf '  تم توليدها   : %d\n' "$STAT_OK"
printf '  تم تخطيها    : %d\n' "$STAT_SKIP"
printf '  فشل          : %d\n' "$STAT_FAIL"
printf '%s════════════════════════════════════════════════════%s\n' "$CYAN" "$RESET"

wait_for_enter
if [ "$STAT_FAIL" -gt 0 ]; then
    exit 1
fi
exit 0
