#!/usr/bin/env bash
#
# Coding Challenge Markdown Format Validator (Linux + macOS compatible)
#
# Validates coding challenge projects for proper CHECKLIST.md and README.md format:
#
# README.md expected structure:
#   1. YAML frontmatter with: difficulty, tags, openFiles
#   2. H1 title (# Challenge Title)
#   3. Time limit line (**Time Limit: XX minutes**)
#   4. # Challenge Description section
#   5. ## Requirements section with ### Part N subsections
#   6. ## Files to Create/Modify section
#   7. ## Getting Started section with code block
#   8. ## Running Tests section with code block
#   9. ## Tips section (optional)
#
# CHECKLIST.md expected structure:
#   - Valid YAML array (parsed by Symfony Yaml::parse in certificates-api)
#   - Each top-level item starts with '- '
#   - Nested items allowed (YAML sub-arrays)
#   - No metadata/frontmatter
#   - Last item should mention running tests
#
# REVIEWER.md (optional):
#   - If present, must be valid markdown
#   - Converted to HTML by parser
#
# Parser-aligned rules (from certificates-api ParseCodingChallengeData):
#   - README.md frontmatter parsed for: difficulty, tags, chapter, training,
#     freebie, category, openFiles
#   - CHECKLIST.md parsed as YAML array via Yaml::parse()
#   - REVIEWER.md is optional, converted to HTML
#   - All frontmatter fields are optional with defaults
#
# Usage: ./validate-coding-challenge.sh <project_directory_or_parent>
#

set -uo pipefail

# ── Help ──
show_help() {
    cat <<'HELP'
Coding Challenge Markdown Format Validator
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

USAGE:
  ./validate-coding-challenge.sh <project_or_parent_directory>
  ./validate-coding-challenge.sh --help | -h

ARGUMENTS:
  <project_or_parent_directory>
      Path to either:
        • A single project directory (must contain README.md + CHECKLIST.md)
        • A parent directory containing multiple project subdirectories
      Defaults to current directory (.) if omitted.

WHAT IT CHECKS:
  README.md     — Frontmatter (difficulty, tags, openFiles), title, time limit,
                  required sections (Challenge Description, Requirements, Parts,
                  Files to Create/Modify, Getting Started, Running Tests),
                  code block balance, YAML validity
  CHECKLIST.md  — Valid YAML array, item format, empty items, test reference
  REVIEWER.md   — Optional; if present checks for empty content, frontmatter,
                  code block balance

EXAMPLES:
  # Validate a single coding challenge project
  ./validate-coding-challenge.sh laravel-level-4-trial-exam-coding-challenge

  # Validate all projects under a parent directory
  ./validate-coding-challenge.sh angular

  # Validate all coding challenge projects in current directory
  ./validate-coding-challenge.sh .

  # Validate a specific Angular training challenge
  ./validate-coding-challenge.sh angular/l3-training-code-challenge-chapter1

OUTPUT LEVELS:
  ERROR   Must fix — causes validation failure (exit code 1)
  WARN    Should fix — does not fail validation
  INFO    Informational — YAML item counts, REVIEWER.md status, etc.

PROJECT DETECTION:
  A directory is recognized as a coding challenge project if it contains
  both README.md and CHECKLIST.md. Other directories are skipped.
HELP
    exit 0
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    show_help
fi

# ── Required binary checks ──
check_binary() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Error: required command '$1' not found. Please install it and try again." >&2
        exit 1
    fi
}

check_binary grep
check_binary sed
check_binary awk
check_binary find
check_binary head
check_binary wc

if ! command -v python3 >/dev/null 2>&1; then
    echo "Warning: 'python3' not found — YAML validation will be skipped." >&2
    echo "  Install Python 3 with PyYAML (pip3 install pyyaml) for full validation." >&2
    echo ""
fi

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

ERRORS=0
WARNINGS=0
INFO_COUNT=0
PROJECTS_CHECKED=0

TARGET="${1:-.}"

# Accumulate findings for the PR summary comment (see maybe_post_pr_comment).
SUMMARY_ROWS_FILE="$(mktemp 2>/dev/null || echo "/tmp/cc_rows.$$")"
: > "$SUMMARY_ROWS_FILE"
CURRENT_PROJECT=""
record_row() {
    # $1=level emoji, $2=file label, $3=message. Escape pipes/newlines for the md table.
    local lvl="$1" f="$2" m="$3"
    [ -n "$CURRENT_PROJECT" ] && f="$CURRENT_PROJECT/$f"
    f=$(printf '%s' "$f" | tr '\n' ' ' | sed 's/|/\\|/g')
    m=$(printf '%s' "$m" | tr '\n' ' ' | sed 's/|/\\|/g')
    printf '| %s | %s | %s |\n' "$lvl" "$f" "$m" >> "$SUMMARY_ROWS_FILE"
}

error() {
    local file="$1" msg="$2"
    echo -e "  ${RED}ERROR${NC} [$file]: $msg"
    record_row "❌" "$file" "$msg"
    ERRORS=$((ERRORS + 1))
}

warn() {
    local file="$1" msg="$2"
    echo -e "  ${YELLOW}WARN${NC}  [$file]: $msg"
    record_row "⚠️" "$file" "$msg"
    WARNINGS=$((WARNINGS + 1))
}

info() {
    local file="$1" msg="$2"
    echo -e "  ${BLUE}INFO${NC}  [$file]: $msg"
    INFO_COUNT=$((INFO_COUNT + 1))
}

ok() {
    local msg="$1"
    echo -e "  ${GREEN}OK${NC}:    $msg"
}

count_matches() {
    local pattern="$1" file="$2"
    grep -cE "$pattern" "$file" 2>/dev/null | tr -d '[:space:]' || echo "0"
}

validate_readme() {
    local file="$1"
    local project="$2"
    local has_error=false

    if [ ! -f "$file" ]; then
        error "README.md" "File not found in $project"
        return
    fi

    # ── 0. File must not be empty (parser-aligned) ──
    local file_size
    file_size=$(wc -c < "$file" | tr -d '[:space:]')
    if [ "$file_size" -eq 0 ]; then
        error "README.md" "File is empty (parser requires non-empty content)"
        return
    fi

    # ── 1. Frontmatter ──
    local first_line
    first_line=$(head -n 1 "$file")
    if [ "$first_line" != "---" ]; then
        error "README.md" "Must start with frontmatter delimiter '---'"
        has_error=true
        return
    fi

    local fm_close
    fm_close=$(awk 'NR>1 && /^---$/ { print NR; exit }' "$file")
    if [ -z "$fm_close" ]; then
        error "README.md" "Missing closing frontmatter delimiter '---'"
        has_error=true
        return
    fi

    local frontmatter
    frontmatter=$(sed -n "2,$((fm_close - 1))p" "$file")

    # ── 1b. Validate YAML frontmatter is parseable (parser-aligned) ──
    if command -v python3 >/dev/null 2>&1; then
        if ! echo "$frontmatter" | python3 -c "import sys, yaml; yaml.safe_load(sys.stdin)" 2>/dev/null; then
            error "README.md" "Frontmatter YAML is not parseable (invalid YAML syntax)"
            has_error=true
        fi
    fi

    # ── 2. Metadata fields (parser-aligned: all optional with defaults → WARN only) ──
    if ! echo "$frontmatter" | grep -qE '^difficulty:\s+[0-9]+'; then
        warn "README.md" "Missing or invalid 'difficulty' in frontmatter (expected: difficulty: <number>) — parser defaults to 1"
    else
        local difficulty
        difficulty=$(echo "$frontmatter" | grep -oE '^difficulty:\s+[0-9]+' | grep -oE '[0-9]+')
        if [ "$difficulty" -lt 1 ] || [ "$difficulty" -gt 4 ]; then
            warn "README.md" "Unusual difficulty value: $difficulty (expected 1-4)"
        fi
    fi

    if ! echo "$frontmatter" | grep -qE '^tags:\s+.+'; then
        warn "README.md" "Missing 'tags' in frontmatter — parser defaults to empty tags"
    fi

    if ! echo "$frontmatter" | grep -qE '^openFiles:\s+.+'; then
        warn "README.md" "Missing 'openFiles' in frontmatter (should list files to open in editor) — parser defaults to null"
    fi

    # ── 2b. Known frontmatter field types (parser casts with defaults → WARN only) ──
    if echo "$frontmatter" | grep -qE '^difficulty:'; then
        if ! echo "$frontmatter" | grep -qE '^difficulty:\s+[0-9]+\s*$'; then
            warn "README.md" "Field 'difficulty' should be an integer"
        fi
    fi
    if echo "$frontmatter" | grep -qE '^freebie:'; then
        if ! echo "$frontmatter" | grep -qE '^freebie:\s+(true|false)\s*$'; then
            warn "README.md" "Field 'freebie' should be a boolean (true/false)"
        fi
    fi
    if echo "$frontmatter" | grep -qE '^training:'; then
        if ! echo "$frontmatter" | grep -qE '^training:\s+(true|false)\s*$'; then
            warn "README.md" "Field 'training' should be a boolean (true/false)"
        fi
    fi

    # ── 2c. Check training-specific fields ──
    if echo "$frontmatter" | grep -qE '^training:\s+true'; then
        if ! echo "$frontmatter" | grep -qE '^chapter:\s+'; then
            warn "README.md" "Training challenge missing 'chapter' field in frontmatter"
        fi
    fi

    # ── 2d. Check for unknown frontmatter fields (parser-aligned) ──
    local known_fields="difficulty|tags|chapter|training|freebie|category|openFiles"
    local unknown_fields
    unknown_fields=$(echo "$frontmatter" | grep -vE "^($known_fields):" | grep -E '^[a-zA-Z_]+:' || true)
    if [ -n "$unknown_fields" ]; then
        warn "README.md" "Unknown frontmatter field(s) (may be ignored by parser): $(echo "$unknown_fields" | tr '\n' ', ')"
    fi

    # ── 3. Blank line after frontmatter ──
    local line_after_fm
    line_after_fm=$(sed -n "$((fm_close + 1))p" "$file")
    if [ -n "$line_after_fm" ]; then
        warn "README.md" "Expected blank line after frontmatter (line $((fm_close + 1)))"
    fi

    # ── 3b. No stray '---' line in the body (parser-breaking) ──
    # splitMarkdown() splits on /^---\s*$/m and requires exactly 2 parts; a '---' in the
    # body produces a 3rd part and the parser throws.
    local stray_fm
    stray_fm=$(awk -v c="$fm_close" 'NR>c && /^---[[:space:]]*$/ { print NR; exit }' "$file")
    if [ -n "$stray_fm" ]; then
        error "README.md" "Stray '---' line in body at line $stray_fm (parser splits on '---' and will fail — escape or remove it)"
        has_error=true
    fi

    # ── 4. H1 Title (parser takes first non-empty line → missing is WARN; >255 breaks DB) ──
    local h1_title
    h1_title=$(grep -n '^# ' "$file" | head -1 || true)
    if [ -z "$h1_title" ]; then
        warn "README.md" "Missing H1 title (# Challenge Title) — parser uses the first non-empty body line"
    else
        local h1_text="${h1_title#*:}"
        h1_text="${h1_text#\# }"
        if [ "${#h1_text}" -gt 255 ]; then
            error "README.md" "H1 title exceeds 255 characters (${#h1_text} chars)"
            has_error=true
        fi
    fi

    # ── 5-10. Documentation conventions (not parsed by certificates-api → WARN only) ──
    # The parser stores the whole body as HTML; no specific section is required to import.
    if ! grep -qE '^\*\*Time Limit:\s+[0-9]+\s+minutes\*\*' "$file"; then
        warn "README.md" "Missing time limit line (expected: **Time Limit: XX minutes**)"
    fi

    if ! grep -qE '^# Challenge Description' "$file"; then
        warn "README.md" "Missing '# Challenge Description' section"
    fi

    if ! grep -qE '^## Requirements' "$file"; then
        warn "README.md" "Missing '## Requirements' section"
    fi

    local part_count
    part_count=$(count_matches '^### Part [0-9]+' "$file")
    if [ "$part_count" -eq 0 ]; then
        warn "README.md" "No '### Part N:' subsections found under Requirements"
    fi

    if ! grep -qE '^## Files to (Create/Modify|Modify|Create)' "$file"; then
        warn "README.md" "Missing '## Files to Create/Modify' section"
    fi

    if ! grep -qE '^## Getting Started' "$file"; then
        warn "README.md" "Missing '## Getting Started' section"
    else
        if ! grep -qE 'composer install|npm install|yarn install|pnpm install' "$file"; then
            warn "README.md" "Getting Started section may be missing dependency install instruction"
        fi
    fi

    if ! grep -qE '^## Running Tests' "$file"; then
        warn "README.md" "Missing '## Running Tests' section"
    else
        if ! grep -qE 'vendor/bin/pest|vendor/bin/phpunit|php artisan test|npm test|npx jest|ng test|cypress|vitest' "$file"; then
            warn "README.md" "Running Tests section may be missing test command"
        fi
    fi

    # ── 11. Code blocks balance (rendering quality, not a parser throw → WARN) ──
    local open_blocks
    open_blocks=$(count_matches '^\x60\x60\x60' "$file")
    if [ "$((open_blocks % 2))" -ne 0 ]; then
        warn "README.md" "Unclosed code block (odd number of \`\`\` delimiters: $open_blocks)"
    fi

    # ── 12. Other Considerations section (recommended) ──
    if ! grep -qE '^## Other Considerations' "$file"; then
        info "README.md" "No '## Other Considerations' section (recommended for data-test attributes, linting notes)"
    fi

    if ! $has_error; then
        ok "README.md format is valid"
    fi
}

validate_checklist() {
    local file="$1"
    local project="$2"
    local has_error=false

    if [ ! -f "$file" ]; then
        error "CHECKLIST.md" "File not found in $project"
        return
    fi

    local line_count
    line_count=$(wc -l < "$file" | tr -d '[:space:]')

    # NOTE: certificates-api parseChecklist() is regex line-filtering (matches `^\s*-\s+`,
    # strips `[ x]` checkboxes), NOT Yaml::parse(). It silently ignores any non-matching
    # line and drops empties — so nothing here breaks import. All checks below are WARN.
    if [ "$line_count" -eq 0 ]; then
        warn "CHECKLIST.md" "File is empty — challenge imports with an empty checklist"
        return
    fi

    # ── 1. Frontmatter is non-standard (parser ignores it) ──
    local first_line
    first_line=$(head -n 1 "$file")
    if [ "$first_line" = "---" ]; then
        warn "CHECKLIST.md" "Should not contain frontmatter (found '---' on line 1) — parser ignores non-'- ' lines"
    fi

    # ── 1b. YAML shape (informational only — parser does not Yaml::parse this file) ──
    if command -v python3 >/dev/null 2>&1; then
        local yaml_result
        yaml_result=$(python3 -c "
import sys, yaml
try:
    data = yaml.safe_load(sys.stdin)
    if data is None:
        print('EMPTY')
    elif not isinstance(data, list):
        print('NOT_LIST')
    else:
        print('OK:' + str(len(data)))
except yaml.YAMLError as e:
    print('ERROR:' + str(e))
" < "$file" 2>&1)
        case "$yaml_result" in
            OK:*)
                local yaml_count="${yaml_result#OK:}"
                info "CHECKLIST.md" "Valid YAML array with $yaml_count top-level items"
                ;;
            EMPTY)
                warn "CHECKLIST.md" "YAML parses as empty (null) — no checklist items"
                ;;
            NOT_LIST)
                warn "CHECKLIST.md" "Not a YAML array/list — parser only reads '- ' lines, the rest is ignored"
                ;;
            ERROR:*)
                warn "CHECKLIST.md" "Invalid YAML syntax (parser does not Yaml::parse this file, but fix for clarity): ${yaml_result#ERROR:}"
                ;;
        esac
    fi

    # ── 2. Lines that aren't '- ' items are ignored by the parser ──
    local item_count=0
    local line_num=0
    while IFS= read -r line || [ -n "$line" ]; do
        line_num=$((line_num + 1))
        # Skip empty lines
        if [ -z "$line" ]; then
            continue
        fi
        case "$line" in
            '- '*)
                item_count=$((item_count + 1))
                ;;
            '  '*)
                # Indented lines are valid YAML continuation (nested items, multiline strings)
                ;;
            *)
                warn "CHECKLIST.md" "Line $line_num is not a '- ' checklist item and will be ignored by the parser: '$line'"
                ;;
        esac
    done < "$file"

    if [ "$item_count" -eq 0 ]; then
        warn "CHECKLIST.md" "No '- ' checklist items found — challenge imports with an empty checklist"
    elif [ "$item_count" -lt 3 ]; then
        warn "CHECKLIST.md" "Only $item_count checklist items found (expected at least 3)"
    fi

    # ── 3. No consecutive blank lines ──
    local double_blanks
    double_blanks=$(awk 'prev_blank && /^$/ { count++ } END { print count+0 }' "$file")
    if [ "$double_blanks" -gt 0 ]; then
        warn "CHECKLIST.md" "Found consecutive blank lines"
    fi

    # ── 4. Last item should reference running tests ──
    local last_item
    last_item=$(grep '^- ' "$file" | tail -1)
    if ! echo "$last_item" | grep -qiE 'test|pest|phpunit|cypress|jest|vitest|ng test'; then
        warn "CHECKLIST.md" "Last checklist item should reference running tests"
    fi

    # ── 5. Check for empty checklist items ──
    local empty_items
    empty_items=$(count_matches '^- $' "$file")
    if [ "$empty_items" -gt 0 ]; then
        warn "CHECKLIST.md" "Found $empty_items empty checklist item(s) ('- ' with no text) — parser drops empties"
    fi

    if ! $has_error; then
        ok "CHECKLIST.md format is valid"
    fi
}

validate_reviewer() {
    local file="$1"
    local project="$2"

    if [ ! -f "$file" ]; then
        info "REVIEWER.md" "Not present (optional file — reviewer checklist for code review)"
        return
    fi

    local has_error=false

    # ── 1. Empty (parser → Str::markdown('') = '', no break → WARN) ──
    local file_size
    file_size=$(wc -c < "$file" | tr -d '[:space:]')
    if [ "$file_size" -eq 0 ]; then
        warn "REVIEWER.md" "File exists but is empty"
        return
    fi

    # ── 2. Should NOT have frontmatter (parser converts to HTML directly) ──
    local first_line
    first_line=$(head -n 1 "$file")
    if [ "$first_line" = "---" ]; then
        warn "REVIEWER.md" "Contains frontmatter — parser converts raw markdown to HTML, frontmatter may appear in output"
    fi

    # ── 3. Code blocks balance (rendering quality, not a parser throw → WARN) ──
    local open_blocks
    open_blocks=$(count_matches '^\x60\x60\x60' "$file")
    if [ "$((open_blocks % 2))" -ne 0 ]; then
        warn "REVIEWER.md" "Unclosed code block (odd number of \`\`\` delimiters: $open_blocks)"
    fi

    if ! $has_error; then
        ok "REVIEWER.md format is valid"
    fi
}

validate_project() {
    local project_dir="$1"
    local project_name
    project_name=$(basename "$project_dir")
    # Qualify summary rows with the project name, except for single-repo (".") runs.
    if [ "$project_name" = "." ] || [ "$project_dir" = "$TARGET" ]; then
        CURRENT_PROJECT=""
    else
        CURRENT_PROJECT="$project_name"
    fi

    echo ""
    echo -e "${CYAN}━━━ Project: $project_name ━━━${NC}"

    validate_readme "$project_dir/README.md" "$project_name"
    validate_checklist "$project_dir/CHECKLIST.md" "$project_name"
    validate_reviewer "$project_dir/REVIEWER.md" "$project_name"

    PROJECTS_CHECKED=$((PROJECTS_CHECKED + 1))
}

# ── Detect project(s) ──
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Coding Challenge Markdown Format Validator"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -f "$TARGET/README.md" ] && [ -f "$TARGET/CHECKLIST.md" ]; then
    # Single project directory
    validate_project "$TARGET"
elif [ -d "$TARGET" ]; then
    # Parent directory containing multiple projects
    found_projects=false
    for dir in "$TARGET"/*/; do
        if [ -f "${dir}README.md" ] && [ -f "${dir}CHECKLIST.md" ]; then
            validate_project "${dir%/}"
            found_projects=true
        fi
    done
    if ! $found_projects; then
        echo -e "\n${RED}No coding challenge projects found in '$TARGET'${NC}"
        echo "Expected directories containing both README.md and CHECKLIST.md"
        exit 1
    fi
else
    echo -e "\n${RED}Error${NC}: '$TARGET' is not a valid directory"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e " Projects checked: ${CYAN}$PROJECTS_CHECKED${NC}"
echo -e " Errors:           ${RED}$ERRORS${NC}"
echo -e " Warnings:         ${YELLOW}$WARNINGS${NC}"
echo -e " Info:             ${BLUE}$INFO_COUNT${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── Post / update a sticky summary comment on the PR (GitHub Actions only) ──
maybe_post_pr_comment() {
    [ "${GITHUB_ACTIONS:-}" = "true" ] || return 0
    [ "${GITHUB_EVENT_NAME:-}" = "pull_request" ] || return 0
    command -v gh >/dev/null 2>&1 || return 0
    command -v jq >/dev/null 2>&1 || return 0
    local repo="${GITHUB_REPOSITORY:-}" pr
    pr=$(jq -r '.pull_request.number // empty' "${GITHUB_EVENT_PATH:-/dev/null}" 2>/dev/null)
    [ -n "$repo" ] && [ -n "$pr" ] || return 0

    local marker="<!-- markdown-validation-summary -->" status body rows
    if [ "$ERRORS" -gt 0 ]; then
        status="❌ **$ERRORS error(s)**, $WARNINGS warning(s) — errors **break the certificates import** and fail this check."
    elif [ "$WARNINGS" -gt 0 ]; then
        status="✅ Passing with **$WARNINGS warning(s)** — non-critical; the content still imports into certificates."
    else
        status="✅ All checks passed — no issues."
    fi
    body="${marker}"$'\n'"### Coding challenge validation"$'\n\n'"${status}"
    rows=$(cat "$SUMMARY_ROWS_FILE")
    if [ -n "$rows" ]; then
        body="${body}"$'\n\n'"| Level | File | Issue |"$'\n'"|:--|:--|:--|"$'\n'"${rows}"
    fi

    local cid
    cid=$(gh api --paginate "repos/$repo/issues/$pr/comments" \
            --jq ".[] | select(.body != null and (.body | contains(\"$marker\"))) | .id" 2>/dev/null | head -1)
    if [ -n "$cid" ]; then
        gh api -X PATCH "repos/$repo/issues/comments/$cid" -f body="$body" >/dev/null 2>&1 || true
    else
        gh api -X POST "repos/$repo/issues/$pr/comments" -f body="$body" >/dev/null 2>&1 || true
    fi
}

maybe_post_pr_comment
rm -f "$SUMMARY_ROWS_FILE" 2>/dev/null || true

if [ "$ERRORS" -gt 0 ]; then
    echo -e "${RED}VALIDATION FAILED${NC}"
    exit 1
else
    echo -e "${GREEN}ALL CHECKS PASSED${NC}"
    exit 0
fi
