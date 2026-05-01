#!/usr/bin/env bash
# update-elavon-usage.sh
#
# Cross-references TSPI fields in input-data.csv against the find-tspi-field-usages
# lookup CSV and stamps ElavonUsage (USED/NOT_USED) + UsageComments columns.
#
# Usage:
#   ./update-elavon-usage.sh [INPUT_CSV] [LOOKUP_CSV] [OUTPUT_CSV]
#
# Defaults:
#   INPUT_CSV  — ../input-data.csv  (relative to this script)
#   LOOKUP_CSV — latest *.csv in ../logs/
#   OUTPUT_CSV — overwrites INPUT_CSV in-place
#
# Matching logic:
#   EXACT  — lookup FieldName == normalised Field Name
#   PREFIX — lookup FieldName starts with normalised Field Name + "."
#             (child field accessed → parent is implicitly used)

set -euo pipefail

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
INPUT_CSV="${1:-${SCRIPT_DIR}/../input-data.csv}"
LOOKUP_CSV="${2:-}"
OUTPUT_CSV="${3:-$INPUT_CSV}"

# ---------------------------------------------------------------------------
# Resolve latest lookup CSV if not specified
# ---------------------------------------------------------------------------
if [ -z "$LOOKUP_CSV" ]; then
    LOGS_DIR="${SCRIPT_DIR}/../logs"
    LOOKUP_CSV=$(ls -t "${LOGS_DIR}"/*.csv 2>/dev/null | head -1 || true)
    if [ -z "$LOOKUP_CSV" ]; then
        echo "ERROR: No CSV files found in ${LOGS_DIR}. Run find-tspi-field-usages.sh first." >&2
        exit 1
    fi
fi

if [ ! -f "$INPUT_CSV" ];  then echo "ERROR: InputCsv not found: $INPUT_CSV" >&2;  exit 1; fi
if [ ! -f "$LOOKUP_CSV" ]; then echo "ERROR: LookupCsv not found: $LOOKUP_CSV" >&2; exit 1; fi

echo "=== Update ElavonUsage ==="
echo "  Input:  $INPUT_CSV"
echo "  Lookup: $LOOKUP_CSV"
echo "  Output: $OUTPUT_CSV"
echo ""

# ---------------------------------------------------------------------------
# Use awk to:
#   1. Load lookup CSV into memory (indexed by FieldName)
#   2. Read input-data.csv row by row
#   3. For each Field Name → exact + prefix match against lookup index
#   4. Write updated rows with ElavonUsage + UsageComments columns
# ---------------------------------------------------------------------------
awk -v lookup="$LOOKUP_CSV" '
BEGIN {
    FS = ","
    OFS = ","

    # ---------- Load lookup CSV ----------
    row_idx = 0
    while ((getline lline < lookup) > 0) {
        row_idx++
        if (row_idx == 1) continue  # skip header

        # Parse quoted CSV: "FieldName","ValidationStatus","ClassName","LineContent","LineNo","FilePath","RepoName"
        n = parse_csv(lline, lf)
        if (n < 7) continue

        fn       = lf[1]   # FieldName (already lowercase dot-notation)
        vstatus  = lf[2]
        cname    = lf[3]   # ClassName (source file class)
        lcontent = lf[4]   # LineContent
        lineno   = lf[5]
        fpath    = lf[6]
        reponame = lf[7]

        if (fn == "" || fn == "UNKNOWN") continue

        # Store in lookup arrays keyed by field name
        # Use array of records per field name
        key = fn
        lcount[key]++
        k = lcount[key]
        lclasses[key][k]  = cname
        llinenos[key][k]  = lineno
        lcontents[key][k] = lcontent
        lfpaths[key][k]   = fpath

        # Track unique classes per field
        ckey = key SUBSEP cname
        if (!(ckey in seen_class)) {
            seen_class[ckey] = 1
            uclasses[key] = (uclasses[key] == "") ? cname : uclasses[key] "; " cname
        }
    }
    close(lookup)
}

# ---------- Parse a single CSV line into array f[] (1-indexed), return count ----------
function parse_csv(line, f,    i, c, in_q, field, nc) {
    nc = 0; field = ""; in_q = 0
    for (i = 1; i <= length(line); i++) {
        c = substr(line, i, 1)
        if (in_q) {
            if (c == "\"") {
                if (substr(line, i+1, 1) == "\"") { field = field "\""; i++ }
                else in_q = 0
            } else field = field c
        } else {
            if (c == "\"") { in_q = 1 }
            else if (c == ",") { f[++nc] = field; field = "" }
            else field = field c
        }
    }
    f[++nc] = field
    return nc
}

function csv_esc(s) { gsub(/"/, "\"\"", s); return "\"" s "\"" }

function find_matches(norm_name,    usage, comments, hits, k, sample, dup_key, cls_list, sub_fields, sf_key) {
    usage = "NOT_USED"; comments = ""; hits = 0; cls_list = ""; sub_fields = ""

    # Check all lookup field names for exact or prefix match
    for (fn in lcount) {
        matched = 0
        is_prefix = 0
        if (fn == norm_name) matched = 1                      # exact
        else if (index(fn, norm_name ".") == 1) { matched = 1; is_prefix = 1 }  # prefix (child field)

        if (matched) {
            # Track specific sub-fields accessed (prefix matches only)
            if (is_prefix) {
                sf_key = substr(fn, length(norm_name) + 2)  # strip "normname." prefix
                if (sf_key != "" && !(sf_key in seen_sf)) {
                    seen_sf[sf_key] = 1
                    sub_fields = (sub_fields == "") ? sf_key : sub_fields "; " sf_key
                }
            }

            for (k = 1; k <= lcount[fn]; k++) {
                dup_key = lfpaths[fn][k] "|" llinenos[fn][k]
                if (!(dup_key in seen_hit)) {
                    seen_hit[dup_key] = 1
                    hits++
                    if (hits == 1) sample = "[" lclasses[fn][k] "] L" llinenos[fn][k] ": " lcontents[fn][k]
                }
            }
            # merge unique classes
            split(uclasses[fn], ca, "; ")
            for (ci in ca) {
                ckey2 = norm_name SUBSEP ca[ci]
                if (!(ckey2 in seen_cls)) {
                    seen_cls[ckey2] = 1
                    cls_list = (cls_list == "") ? ca[ci] : cls_list "; " ca[ci]
                }
            }
        }
    }

    # Reset per-field dedup
    delete seen_hit
    delete seen_cls
    delete seen_sf

    if (hits > 0) {
        usage = "USED"
        if (length(sample) > 200) sample = substr(sample, 1, 200) "..."
        comments = "count=" hits " classes=[" cls_list "]"
        if (sub_fields != "") comments = comments " sub-fields=[" sub_fields "]"
        comments = comments " samples: " sample
    }
    return usage SUBSEP comments
}

# ---------- Process input-data.csv ----------
NR == 1 {
    # Parse header; track indices of ElavonUsage, UsageComments, and blank cols to skip them
    eu_idx = 0; uc_idx = 0
    n = parse_csv($0, hf)
    for (i = 1; i <= n; i++) {
        if (hf[i] == "ElavonUsage")   eu_idx = i
        if (hf[i] == "UsageComments") uc_idx = i
        if (hf[i] == "")              blank_col[i] = 1   # skip orphaned blank-header cols
    }
    ncols = n
    # Write clean header: skip old ElavonUsage, UsageComments, and blank cols; append fresh
    first = 1
    for (i = 1; i <= n; i++) {
        if (i == eu_idx || i == uc_idx || (i in blank_col)) continue
        printf "%s", (first ? "" : ",") csv_esc(hf[i])
        first = 0
    }
    printf ",%s,%s\n", csv_esc("ElavonUsage"), csv_esc("UsageComments")
    next
}

{
    n = parse_csv($0, f)
    raw_name = f[1]   # Field Name is always column 1
    norm_name = tolower(raw_name)
    gsub(/ /, "", norm_name)

    result = find_matches(norm_name)
    split(result, res, SUBSEP)
    eu = res[1]; uc = res[2]

    # Write: original cols except old ElavonUsage, UsageComments, and blank-header cols
    first = 1
    for (i = 1; i <= n; i++) {
        if (i == eu_idx || i == uc_idx || (i in blank_col)) continue
        printf "%s", (first ? "" : ",") csv_esc(f[i])
        first = 0
    }
    printf ",%s,%s\n", csv_esc(eu), csv_esc(uc)
}
' "$INPUT_CSV" > "${OUTPUT_CSV}.tmp" && mv "${OUTPUT_CSV}.tmp" "$OUTPUT_CSV"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
USED_COUNT=$(grep -c '"USED"' "$OUTPUT_CSV" 2>/dev/null || true)
NOT_USED_COUNT=$(grep -c '"NOT_USED"' "$OUTPUT_CSV" 2>/dev/null || true)
# grep -c counts lines matching "USED" which also matches "NOT_USED" — subtract
USED_ONLY=$(grep -c '"USED",' "$OUTPUT_CSV" 2>/dev/null || true)
NOT_USED_ONLY=$(grep -c '"NOT_USED"' "$OUTPUT_CSV" 2>/dev/null || true)
USED_COUNT=${USED_ONLY:-0}
NOT_USED_COUNT=${NOT_USED_ONLY:-0}
TOTAL=$(( ${USED_COUNT:-0} + ${NOT_USED_COUNT:-0} ))

echo "  Results:"
echo "    Total fields : $TOTAL"
echo "    USED         : $USED_COUNT"
echo "    NOT_USED     : $NOT_USED_COUNT"
echo ""
echo "  Output: $OUTPUT_CSV"
