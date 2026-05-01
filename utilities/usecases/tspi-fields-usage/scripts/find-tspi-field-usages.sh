#!/usr/bin/env bash
# find-tspi-field-usages.sh
#
# Scans a Java repo for TSPI TransactionRequest / TransactionResponse field usages
# using grep/egrep and outputs a consolidated CSV lookup file.
#
# Usage:
#   ./find-tspi-field-usages.sh <REPO_PATH> [OUTPUT_DIR] [CONVENTIONS_FILE]
#
# Output CSV columns:
#   FieldName, ValidationStatus, ClassName, LineContent, LineNo, FilePath, RepoName
#
# Example:
#   ./find-tspi-field-usages.sh /c/Users/e135408/IdeaProjects/MODERNIZATION/acqelavons2aservice

set -euo pipefail

REPO_PATH="${1:?Usage: ./find-tspi-field-usages.sh <REPO_PATH> [OUTPUT_DIR] [CONVENTIONS_FILE]}"
OUTPUT_DIR="${2:-$(dirname "$(realpath "$0")")/../logs}"
CONVENTIONS_FILE="${3:-$(dirname "$(realpath "$0")")/field-naming-conventions.txt}"

mkdir -p "$OUTPUT_DIR"

REPO_NAME=$(basename "$REPO_PATH" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g; s/__*/_/g; s/_$//')
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_CSV="${OUTPUT_DIR}/${REPO_NAME}_${TIMESTAMP}.csv"

echo "=== TSPI Field Usage Scanner (shell) ==="
echo "  Repo:         $REPO_PATH"
echo "  Output:       $OUTPUT_CSV"
echo "  Conventions:  $CONVENTIONS_FILE"
echo ""

# ---------------------------------------------------------------------------
# Combined egrep pattern — all TSPI classes, 3 variations each:
#   ClassName::  |  camelName().  |  camelName.
# Ordered longest-first to reduce false prefix matches.
# ---------------------------------------------------------------------------
TXN_RESP_PATTERN="TransactionResponse::|transactionResponse\(\)\.|transactionResponse\."
TXN_RESP_PATTERN="${TXN_RESP_PATTERN}|AcquirerAdditionalResponseData::|acquirerAdditionalResponseData\(\)\.|acquirerAdditionalResponseData\."
TXN_RESP_PATTERN="${TXN_RESP_PATTERN}|AcquirerSpecificResponseFields::|acquirerSpecificResponseFields\(\)\.|acquirerSpecificResponseFields\."
TXN_RESP_PATTERN="${TXN_RESP_PATTERN}|EBTBalances::|eBTBalances\(\)\.|eBTBalances\."
TXN_RESP_PATTERN="${TXN_RESP_PATTERN}|EmvResponse::|emvResponse\(\)\.|emvResponse\."
TXN_RESP_PATTERN="${TXN_RESP_PATTERN}|PreMapped::|preMapped\(\)\.|preMapped\."

TXN_REQ_PATTERN="Transaction::|transaction\(\)\.|transaction\."
TXN_REQ_PATTERN="${TXN_REQ_PATTERN}|AgreementData::|agreementData\(\)\.|agreementData\."
TXN_REQ_PATTERN="${TXN_REQ_PATTERN}|Airline::|airline\(\)\.|airline\."
TXN_REQ_PATTERN="${TXN_REQ_PATTERN}|AssociatedTransaction::|associatedTransaction\(\)\.|associatedTransaction\."
TXN_REQ_PATTERN="${TXN_REQ_PATTERN}|BillingAddress::|billingAddress\(\)\.|billingAddress\."
TXN_REQ_PATTERN="${TXN_REQ_PATTERN}|CSC::|csc\(\)\.|csc\."
TXN_REQ_PATTERN="${TXN_REQ_PATTERN}|Cruise::|cruise\(\)\.|cruise\."
TXN_REQ_PATTERN="${TXN_REQ_PATTERN}|EMVTrack2::|eMVTrack2\(\)\.|eMVTrack2\."
TXN_REQ_PATTERN="${TXN_REQ_PATTERN}|EmvRequest::|emvRequest\(\)\.|emvRequest\."
TXN_REQ_PATTERN="${TXN_REQ_PATTERN}|InvoiceData::|invoiceData\(\)\.|invoiceData\."
TXN_REQ_PATTERN="${TXN_REQ_PATTERN}|LineItems::|lineItems\(\)\.|lineItems\."
TXN_REQ_PATTERN="${TXN_REQ_PATTERN}|MobileWallet::|mobileWallet\(\)\.|mobileWallet\."
TXN_REQ_PATTERN="${TXN_REQ_PATTERN}|OrderCustomFields::|orderCustomFields\(\)\.|orderCustomFields\."
TXN_REQ_PATTERN="${TXN_REQ_PATTERN}|PAN::|pan\(\)\.|pan\."
TXN_REQ_PATTERN="${TXN_REQ_PATTERN}|PlaceHolder::|placeHolder\(\)\.|placeHolder\."
TXN_REQ_PATTERN="${TXN_REQ_PATTERN}|PosTerminalAddress::|posTerminalAddress\(\)\.|posTerminalAddress\."
TXN_REQ_PATTERN="${TXN_REQ_PATTERN}|RelatedTransaction::|relatedTransaction\(\)\.|relatedTransaction\."
TXN_REQ_PATTERN="${TXN_REQ_PATTERN}|ShippingAddress::|shippingAddress\(\)\.|shippingAddress\."
TXN_REQ_PATTERN="${TXN_REQ_PATTERN}|Taxes::|taxes\(\)\.|taxes\."
TXN_REQ_PATTERN="${TXN_REQ_PATTERN}|TransactionsForThisOrder::|transactionsForThisOrder\(\)\.|transactionsForThisOrder\."
TXN_REQ_PATTERN="${TXN_REQ_PATTERN}|Transit::|transit\(\)\.|transit\."

MERCHANT_PATTERN="MerchantContext::|merchantContext\(\)\.|merchantContext\."
MERCHANT_PATTERN="${MERCHANT_PATTERN}|MerchantAcquirerRelationship::|merchantAcquirerRelationship\(\)\.|merchantAcquirerRelationship\."
MERCHANT_PATTERN="${MERCHANT_PATTERN}|MerchantAcquirerCustomFields::|merchantAcquirerCustomFields\(\)\.|merchantAcquirerCustomFields\."
MERCHANT_PATTERN="${MERCHANT_PATTERN}|Acquirer::|acquirer\(\)\.|acquirer\."
MERCHANT_PATTERN="${MERCHANT_PATTERN}|AcquirerCustomFields::|acquirerCustomFields\(\)\.|acquirerCustomFields\."
MERCHANT_PATTERN="${MERCHANT_PATTERN}|Merchant::|merchant\(\)\.|merchant\."
MERCHANT_PATTERN="${MERCHANT_PATTERN}|SubMerchant::|subMerchant\(\)\.|subMerchant\."
MERCHANT_PATTERN="${MERCHANT_PATTERN}|SupportedEMV3DSSchemes::|supportedEMV3DSSchemes\(\)\.|supportedEMV3DSSchemes\.|SupportedEMV3DSSchemes|supportedEMV3DSSchemes\("

FULL_PATTERN="(${TXN_RESP_PATTERN}|${TXN_REQ_PATTERN}|${MERCHANT_PATTERN})"

# ---------------------------------------------------------------------------
# Write CSV header
# ---------------------------------------------------------------------------
printf '"FieldName","ValidationStatus","ClassName","LineContent","LineNo","FilePath","RepoName"\n' > "$OUTPUT_CSV"

# ---------------------------------------------------------------------------
# Run egrep — include all .java, exclude test/integration/test-data paths
# pipe to awk for CSV formatting
# ---------------------------------------------------------------------------
echo "  Scanning Java files (excluding test/integration/test-data)..."

egrep -rn --include="*.java" "$FULL_PATTERN" "$REPO_PATH" 2>/dev/null \
    | grep -v "/src/test/" \
    | grep -v "/src/it/" \
    | grep -Ev "/(integration[-_]tests?|test[-_]data|testdata)/" \
    | grep -v "@Property" \
    | awk -v repo="$REPO_NAME" -v conv_file="$CONVENTIONS_FILE" '

# ---------------------------------------------------------------------------
# Load conventions into a lookup set
# ---------------------------------------------------------------------------
BEGIN {
    conv_count = 0
    while ((getline line < conv_file) > 0) {
        gsub(/^[ \t]+|[ \t]+$/, "", line)
        if (line != "") conv_set[line] = 1
    }
    close(conv_file)

    # Roots ordered longest-first to avoid prefix-match bugs
    ROOTS = "transactionResponse acquirerAdditionalResponseData acquirerSpecificResponseFields eBTBalances emvResponse preMapped merchantAcquirerRelationship merchantAcquirerCustomFields merchantContext associatedTransaction transactionsForThisOrder supportedEMV3DSSchemes posTerminalAddress relatedTransaction mobileWallet orderCustomFields billingAddress shippingAddress invoiceData lineItems emvRequest eMVTrack2 placeHolder agreementData transaction acquirerCustomFields subMerchant acquirer merchant airline cruise taxes transit pan csc"
    nroots = split(ROOTS, root_arr, " ")

    CLASSES = "TransactionResponse AcquirerAdditionalResponseData AcquirerSpecificResponseFields EBTBalances EmvResponse PreMapped Transaction AgreementData Airline AssociatedTransaction BillingAddress CSC Cruise EMVTrack2 EmvRequest InvoiceData LineItems MobileWallet OrderCustomFields PAN PlaceHolder PosTerminalAddress RelatedTransaction ShippingAddress Taxes TransactionsForThisOrder Transit MerchantContext MerchantAcquirerRelationship MerchantAcquirerCustomFields Acquirer AcquirerCustomFields Merchant SubMerchant SupportedEMV3DSSchemes"
    nclasses = split(CLASSES, class_arr, " ")

    # Java noise methods — chains ending in these are trimmed
    NOISE = "tostring equals equalsignorecase touppercase tolowercase hashcode length substring trim contains startswith endswith isempty isblank isnull isnotnull optional ofnullable orelse orelsethrow get set isnotempty nonnull"
    split(NOISE, noise_arr, " ")
    for (k in noise_arr) noise_set[noise_arr[k]] = 1
}

# ---------------------------------------------------------------------------
# Extract TSPI accessor chain from a source line
# Returns lowercase dot-notation string, e.g. "merchantcontext.merchant.submerchant.id"
# ---------------------------------------------------------------------------
function walk_chain(content, start_pos,    rest, parts, np, word, rl) {
    rest = substr(content, start_pos)
    np = 0
    delete parts
    while (length(rest) > 0) {
        if (!match(rest, /^[a-zA-Z_][a-zA-Z0-9_]*/)) break
        word = tolower(substr(rest, 1, RLENGTH))
        rl   = RLENGTH
        rest = substr(rest, rl + 1)
        # consume optional ()
        if (substr(rest, 1, 2) == "()") rest = substr(rest, 3)
        # stop if noise method
        if (word in noise_set) break
        parts[++np] = word
        # continue only if next char is a dot
        if (substr(rest, 1, 1) == ".") { rest = substr(rest, 2) } else { break }
        if (np >= 8) break
    }
    if (np < 2) return ""
    result = parts[1]
    for (j = 2; j <= np; j++) result = result "." parts[j]
    return result
}

function extract_field(content,    i, r, pos, chain, before, cl, cpos) {

    # Attempt 1: camelName(). — root accessor call chain
    for (i = 1; i <= nroots; i++) {
        r = root_arr[i]
        pos = index(content, r "()")
        if (pos > 0) {
            chain = walk_chain(content, pos)
            if (chain != "") return chain
        }
    }

    # Attempt 2: camelName. — direct field access; guard against substring match
    for (i = 1; i <= nroots; i++) {
        r = root_arr[i]
        pos = index(content, r ".")
        if (pos > 0) {
            before = (pos > 1) ? substr(content, pos - 1, 1) : " "
            if (before !~ /[a-zA-Z0-9_]/) {
                chain = walk_chain(content, pos)
                if (chain != "") return chain
            }
        }
    }

    # Attempt 3: ClassName:: static reference
    for (i = 1; i <= nclasses; i++) {
        cl = class_arr[i]
        cpos = index(content, cl "::")
        if (cpos > 0) {
            if (match(substr(content, cpos + length(cl) + 2), /^[A-Za-z0-9_]+/)) {
                return tolower(cl) "." tolower(substr(content, cpos + length(cl) + 2, RLENGTH))
            }
            return tolower(cl)
        }
    }

    return ""
}

# ---------------------------------------------------------------------------
# Main processing: parse grep -n output (filepath:lineno:content)
# ---------------------------------------------------------------------------
{
    line = $0

    # Extract filepath — everything up to .java
    if (!match(line, /\.java:/)) next
    java_end = RSTART + RLENGTH - 2   # position of last char of ".java"
    filepath = substr(line, 1, java_end)

    rest = substr(line, java_end + 2)  # skip ".java:"

    colon_pos = index(rest, ":")
    if (colon_pos == 0) next

    lineno  = substr(rest, 1, colon_pos - 1)
    content = substr(rest, colon_pos + 1)

    # Trim leading whitespace
    sub(/^[ \t]+/, "", content)
    if (content == "" || content ~ /^@/) next

    # Skip import and package declarations — package paths contain class names
    # (e.g. "import ...transaction.AssociatedTransaction;" triggers transaction. pattern)
    if (content ~ /^import /) next
    if (content ~ /^package /) next

    # Validate lineno is numeric
    if (lineno !~ /^[0-9]+$/) next

    # ClassName from filepath
    classfile = filepath
    sub(/.*\//, "", classfile)
    sub(/\.java$/, "", classfile)

    # Skip test class filenames
    if (classfile ~ /(Test|Tests|IT|ITest|Mock|Stub|Fake)$/) next

    # Extract FieldName
    field_name = extract_field(content)
    if (field_name == "") field_name = "UNKNOWN"

    # Strip transactionrequest. prefix (common variable name artefact)
    sub(/^transactionrequest\./, "", field_name)

    # Deduplicate consecutive identical segments: a.a.b → a.b
    while (match(field_name, /([a-z0-9]+)\.\1/)) {
        sub(/([a-z0-9]+)\.\1/, "&", field_name)
        # manual dedup
        n = split(field_name, segs, ".")
        field_name = segs[1]
        for (s = 2; s <= n; s++) {
            if (segs[s] != segs[s-1]) field_name = field_name "." segs[s]
        }
        break
    }

    # ValidationStatus
    if (field_name == "UNKNOWN" || field_name == "") {
        vstatus = "EMPTY"
        field_name = ""
    } else if (field_name in conv_set) {
        vstatus = "VALID"
    } else {
        vstatus = "NOT_IN_CONVENTIONS"
    }

    # CSV-escape
    gsub(/"/, "\"\"", content)
    gsub(/"/, "\"\"", filepath)

    printf "\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\"\n", \
        field_name, vstatus, classfile, content, lineno, filepath, repo
}
' >> "$OUTPUT_CSV"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
TOTAL=$(tail -n +2 "$OUTPUT_CSV" | wc -l | tr -d ' ')
VALID=$(grep -c '"VALID"' "$OUTPUT_CSV" 2>/dev/null || echo 0)
NOT_IN=$(grep -c '"NOT_IN_CONVENTIONS"' "$OUTPUT_CSV" 2>/dev/null || echo 0)
EMPTY=$(grep -c '"EMPTY"' "$OUTPUT_CSV" 2>/dev/null || echo 0)

echo ""
echo "  Results:"
echo "    Total rows    : $TOTAL"
echo "    VALID         : $VALID"
echo "    NOT_IN_CONV   : $NOT_IN"
echo "    EMPTY/UNKNOWN : $EMPTY"
echo ""
echo "  Output: $OUTPUT_CSV"
