#!/bin/bash
set -e

# =============================================================================
# SEED DUMMY DATA SCRIPT FOR KAVYA INDUSTRIES
# =============================================================================
# This script seeds the invoice-builder database with realistic dummy data to
# test: HSN/SAC codes, CGST/SGST split, Amount in Words, and Delivery Challan.
#
# Prerequisites:
#   - Backend server must be running on http://localhost:3000
#   - Start with: npm run dev:webserver (or equivalent)
#
# Usage:
#   chmod +x seed-dummy-data.sh
#   ./seed-dummy-data.sh
# =============================================================================

BASE_URL="http://localhost:3000/api"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_step() {
    echo -e "\n${YELLOW}==================================================${NC}"
    echo -e "${YELLOW}STEP: $1${NC}"
    echo -e "${YELLOW}==================================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

check_response() {
    local response="$1"
    local step_name="$2"
    if echo "$response" | grep -q '"success":true'; then
        print_success "$step_name completed successfully"
    else
        print_error "$step_name failed"
        echo "Response: $response"
        exit 1
    fi
}

# Helper function to extract ID from response
extract_id() {
    echo "$1" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2
}

# =============================================================================
# STEP 0: CHECK SERVER HEALTH
# =============================================================================
print_step "0. Checking server health"

HEALTH_RESPONSE=$(curl -s -w "\n%{http_code}" "$BASE_URL/health" 2>/dev/null)
HTTP_CODE=$(echo "$HEALTH_RESPONSE" | tail -n1)
if [ "$HTTP_CODE" = "200" ]; then
    print_success "Server is running on $BASE_URL"
else
    print_error "Server is not responding. Please start the backend server first."
    echo "Expected: http://localhost:3000"
    echo "HTTP Code: $HTTP_CODE"
    echo ""
    echo "To start the server, run:"
    echo "  npm run dev:webserver"
    exit 1
fi

# =============================================================================
# STEP 1: INITIALIZE DATABASE
# =============================================================================
print_step "1. Initializing database"

# First, list existing databases
echo "Checking existing databases..."
DB_LIST=$(curl -s "$BASE_URL/databases" 2>/dev/null)
echo "Existing databases: $DB_LIST"

# Create/open database
# IMPORTANT: dbType must be "SQLite" (capital S), not "sqlite"
# The fullPath is relative to the ./data/ directory
echo ""
echo "Creating database 'kavya-seed-db.db'..."
DB_RESPONSE=$(curl -s -X POST "$BASE_URL/databases" \
    -H "Content-Type: application/json" \
    -d '{
        "fullPath": "kavya-seed-db.db",
        "mode": "create",
        "dbType": "SQLite"
    }' 2>/dev/null)

echo "Database response: $DB_RESPONSE"
check_response "$DB_RESPONSE" "Database initialization"

# Verify database was created
echo ""
echo "Verifying database creation..."
VERIFY_RESPONSE=$(curl -s "$BASE_URL/databases" 2>/dev/null)
echo "Available databases: $VERIFY_RESPONSE"

if echo "$VERIFY_RESPONSE" | grep -q "kavya-seed-db.db"; then
    print_success "Database 'kavya-seed-db.db' is ready"
else
    print_error "Database was not created properly"
    echo "Please check if the 'data' directory exists and is writable"
    exit 1
fi

# =============================================================================
# STEP 2: GET OR CREATE CURRENCY (INR)
# =============================================================================
print_step "2. Getting INR currency"

# The database is pre-seeded with INR currency (and others) during initialization
# So we need to GET the existing INR currency ID, not create a duplicate
echo "Fetching existing currencies..."
CURRENCIES_RESPONSE=$(curl -s "$BASE_URL/currencies" 2>/dev/null)
echo "Currencies: $CURRENCIES_RESPONSE"

# Extract INR currency ID from the response
CURRENCY_ID=$(echo "$CURRENCIES_RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)

if [ -z "$CURRENCY_ID" ]; then
    print_error "No currency found. Creating INR..."
    CURRENCY_RESPONSE=$(curl -s -X POST "$BASE_URL/currencies" \
        -H "Content-Type: application/json" \
        -d '{
            "code": "INR",
            "symbol": "₹",
            "text": "Indian Rupee",
            "format": "{symbol}{amount}",
            "subunit": 100
        }' 2>/dev/null)
    CURRENCY_ID=$(extract_id "$CURRENCY_RESPONSE")
fi

print_success "INR currency found (ID: $CURRENCY_ID)"

# =============================================================================
# STEP 3: GET UNITS (pcs, hrs, kgs from pre-seeded data)
# =============================================================================
print_step "3. Getting units (pcs, hrs, kgs)"

# Fetch existing units (pre-seeded: pcs, hrs, kgs, etc.)
echo "Fetching existing units..."
UNITS_RESPONSE=$(curl -s "$BASE_URL/units" 2>/dev/null)

# Extract unit IDs using python3 for reliable JSON parsing
UNIT_PCS_ID=$(echo "$UNITS_RESPONSE" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for u in data.get('data', []):
    if u.get('name') == 'pcs':
        print(u['id']); break
" 2>/dev/null || echo "")

UNIT_HRS_ID=$(echo "$UNITS_RESPONSE" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for u in data.get('data', []):
    if u.get('name') == 'hrs':
        print(u['id']); break
" 2>/dev/null || echo "")

UNIT_KGS_ID=$(echo "$UNITS_RESPONSE" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for u in data.get('data', []):
    if u.get('name') == 'kgs':
        print(u['id']); break
" 2>/dev/null || echo "")

print_success "Unit 'pcs' (ID: $UNIT_PCS_ID)"
print_success "Unit 'hrs' (ID: $UNIT_HRS_ID)"
print_success "Unit 'kgs' (ID: $UNIT_KGS_ID)"

# =============================================================================
# STEP 4: GET OR CREATE CATEGORY
# =============================================================================
print_step "4. Getting category"

# Fetch existing categories
echo "Fetching existing categories..."
CATEGORIES_RESPONSE=$(curl -s "$BASE_URL/categories" 2>/dev/null)
echo "Categories: $CATEGORIES_RESPONSE"

# Try to find existing category
CATEGORY_ID=$(echo "$CATEGORIES_RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)

if [ -z "$CATEGORY_ID" ]; then
    echo "Creating 'Industrial Equipment' category..."
    CATEGORY_RESPONSE=$(curl -s -X POST "$BASE_URL/categories" \
        -H "Content-Type: application/json" \
        -d '{"name": "Industrial Equipment"}' 2>/dev/null)
    CATEGORY_ID=$(extract_id "$CATEGORY_RESPONSE")
fi
print_success "Category ready (ID: $CATEGORY_ID)"

# =============================================================================
# STEP 5: CREATE BUSINESS (Kavya Industries)
# =============================================================================
print_step "5. Creating business - Kavya Industries"

BUSINESS_RESPONSE=$(curl -s -X POST "$BASE_URL/businesses" \
    -H "Content-Type: application/json" \
    -d '{
        "name": "Kavya Industries",
        "shortName": "KI",
        "email": "info@kavyaindustries.com",
        "phone": "+91-9876543210",
        "role": "Seller",
        "address": "Plot No. 42, Phase III, MIDC Industrial Area, Pune - 411018, Maharashtra, India",
        "website": "https://kavyaindustries.com",
        "additional": "GSTIN: 27AABCK1234M1Z5",
        "vatCode": "27AABCK1234M1Z5",
        "countryCode": "IN",
        "code": "KI",
        "paymentInformation": "HDFC Bank, A/C: 50100234567890, IFSC: HDFC0001234",
        "isArchived": false
    }' 2>/dev/null)

check_response "$BUSINESS_RESPONSE" "Business creation"
BUSINESS_ID=$(extract_id "$BUSINESS_RESPONSE")
echo "Business ID: $BUSINESS_ID"

# =============================================================================
# STEP 6: CREATE BANK
# =============================================================================
print_step "6. Creating bank - HDFC Bank"

BANK_RESPONSE=$(curl -s -X POST "$BASE_URL/banks" \
    -H "Content-Type: application/json" \
    -d '{
        "name": "HDFC Bank - Main Branch",
        "bankName": "HDFC Bank Ltd",
        "accountNumber": "50100234567890",
        "swiftCode": "HDFCINBB",
        "address": "HDFC Bank House, 2nd Floor, Pune - 411001",
        "branchCode": "PUNE001",
        "type": "Savings",
        "accountHolder": "Kavya Industries",
        "upiCode": "kavyaindustries@hdfcbank",
        "isArchived": false
    }' 2>/dev/null)

check_response "$BANK_RESPONSE" "Bank creation"
BANK_ID=$(extract_id "$BANK_RESPONSE")
echo "Bank ID: $BANK_ID"

# =============================================================================
# STEP 7: CREATE CLIENT (GOVIND PRECISION TECH INDIA PVT.LTD)
# =============================================================================
print_step "7. Creating client - GOVIND PRECISION TECH INDIA PVT.LTD"

CLIENT_RESPONSE=$(curl -s -X POST "$BASE_URL/clients" \
    -H "Content-Type: application/json" \
    -d '{
        "name": "GOVIND PRECISION TECH INDIA PVT.LTD",
        "shortName": "GP",
        "address": "Survey No. 123, Chakan Industrial Area, Pune - 410501, Maharashtra, India",
        "email": "accounts@govindprecision.com",
        "phone": "+91-2135-276541",
        "code": "GPT",
        "additional": "Contact: Mr. Rajesh Sharma (Purchase Manager)",
        "description": "Precision engineering components manufacturer",
        "vatCode": "27AAKCG7481Q1ZM",
        "countryCode": "IN",
        "buyerReference": "PO-2026-0892",
        "isArchived": false
    }' 2>/dev/null)

check_response "$CLIENT_RESPONSE" "Client creation"
CLIENT_ID=$(extract_id "$CLIENT_RESPONSE")
echo "Client ID: $CLIENT_ID"

# =============================================================================
# STEP 8: CREATE ITEMS WITH HSN/SAC CODES
# =============================================================================
print_step "8. Creating items with HSN/SAC codes"

# Item 1: WELDMNT TORQUE ARM (Physical good - HSN 998860)
ITEM1_RESPONSE=$(curl -s -X POST "$BASE_URL/items" \
    -H "Content-Type: application/json" \
    -d '{
        "name": "WELDMNT TORQUE ARM",
        "amount": "16000.00",
        "unitId": '$UNIT_PCS_ID',
        "categoryId": '$CATEGORY_ID',
        "description": "Heavy duty torque arm for welding fixtures - SS316 grade",
        "hsn_sac_code": "998860",
        "isArchived": false
    }' 2>/dev/null)

check_response "$ITEM1_RESPONSE" "Item 1 (WELDMNT TORQUE ARM) creation"
ITEM1_ID=$(extract_id "$ITEM1_RESPONSE")
echo "Item 1 ID: $ITEM1_ID"

# Item 2: Installation & Labour Charges (Service - HSN 998730)
ITEM2_RESPONSE=$(curl -s -X POST "$BASE_URL/items" \
    -H "Content-Type: application/json" \
    -d '{
        "name": "Installation & Labour Charges",
        "amount": "5000.00",
        "unitId": '$UNIT_HRS_ID',
        "categoryId": '$CATEGORY_ID',
        "description": "On-site installation and commissioning charges",
        "hsn_sac_code": "998730",
        "isArchived": false
    }' 2>/dev/null)

check_response "$ITEM2_RESPONSE" "Item 2 (Installation & Labour Charges) creation"
ITEM2_ID=$(extract_id "$ITEM2_RESPONSE")
echo "Item 2 ID: $ITEM2_ID"

# Item 3: Mild Steel Plate (Physical good - HSN 7208)
ITEM3_RESPONSE=$(curl -s -X POST "$BASE_URL/items" \
    -H "Content-Type: application/json" \
    -d '{
        "name": "Mild Steel Plate 10mm",
        "amount": "8500.00",
        "unitId": '$UNIT_KGS_ID',
        "categoryId": '$CATEGORY_ID',
        "description": "IS 2062 Grade E250BR MS Plate - Cut to size",
        "hsn_sac_code": "7208",
        "isArchived": false
    }' 2>/dev/null)

check_response "$ITEM3_RESPONSE" "Item 3 (Mild Steel Plate) creation"
ITEM3_ID=$(extract_id "$ITEM3_RESPONSE")
echo "Item 3 ID: $ITEM3_ID"

# =============================================================================
# STEP 9: CREATE DEFAULT LAYOUT (if needed)
# =============================================================================
print_step "9. Creating default layout"

# Check if layout exists
LAYOUTS_RESPONSE=$(curl -s "$BASE_URL/layouts" 2>/dev/null)
LAYOUT_ID=$(echo "$LAYOUTS_RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)

if [ -z "$LAYOUT_ID" ]; then
    echo "Creating 'Standard Invoice Layout'..."
    LAYOUT_SCHEMA=$(python3 -c "
import json
schema = {
    'schemaVersion': 1,
    'meta': {'name': 'Standard Invoice Layout'},
    'sections': [
        {
            'type': 'header',
            'visible': True,
            'blocks': [
                {
                    'type': 'row',
                    'children': [
                        {'type': 'logo', 'width': '20%'},
                        {'type': 'title', 'width': '40%'},
                        {'type': 'invoiceMeta', 'width': '40%', 'showTitle': False, 'showInvoiceLabel': True}
                    ],
                    'justify': 'between',
                    'align': 'start'
                },
                {'type': 'businessInfo', 'visible': True},
                {'type': 'clientInfo', 'visible': True}
            ]
        },
        {'type': 'itemsTable', 'visible': True, 'columnSizing': 'fixedFlex'},
        {'type': 'financialTotals', 'visible': True},
        {'type': 'notes', 'visible': True},
        {'type': 'signature', 'visible': True},
        {'type': 'pageCounter', 'visible': True}
    ]
}
print(json.dumps(schema))
")
    LAYOUT_RESPONSE=$(curl -s -X POST "$BASE_URL/layouts" \
        -H "Content-Type: application/json" \
        -d "{\"schema\": $LAYOUT_SCHEMA, \"isArchived\": false}" 2>/dev/null)
    LAYOUT_ID=$(extract_id "$LAYOUT_RESPONSE")
fi
print_success "Layout ready (ID: $LAYOUT_ID)"

# =============================================================================
# STEP 10: CREATE STANDARD TAX INVOICE (with CGST/SGST)
# =============================================================================
print_step "10. Creating standard Tax Invoice with CGST/SGST"

INVOICE_RESPONSE=$(curl -s -X POST "$BASE_URL/invoices" \
    -H "Content-Type: application/json" \
    -d '{
        "invoiceType": "invoice",
        "businessId": '$BUSINESS_ID',
        "clientId": '$CLIENT_ID',
        "currencyId": '$CURRENCY_ID',
        "bankId": '$BANK_ID',
        "layoutId": '$LAYOUT_ID',
        "invoiceNumber": "001",
        "issuedAt": "2026-09-14T00:00:00.000Z",
        "dueDate": "2026-10-14T00:00:00.000Z",
        "status": "open",
        "isArchived": false,
        "language": "en",
        "invoicePrefix": "INV-",
        "invoiceSuffix": "/26-27",
        "customerNotes": "Supply within 15 days. Payment due within 30 days of invoice date.",
        "thanksNotes": "Thank you for your business!",
        "termsConditionNotes": "1. Warranty as per manufacturer terms.\n2. Subject to Pune jurisdiction.\n3. E&OE.",
        "discountName": "Volume Discount",
        "discountType": "percentage",
        "discountAmountCents": "0",
        "discountPercent": 5,
        "shippingFeeCents": "250000",
        "surchargeName": "",
        "surchargeAmountCents": "0",
        "surchargeType": "fixed",
        "surchargePercent": 0,
        "taxName": "GST",
        "taxRate": 0,
        "taxType": "exclusive",
        "cgstRate": 9,
        "sgstRate": 9,
        "cgstAmount": "0",
        "sgstAmount": "0",
        "invoiceItems": [
            {
                "itemId": '$ITEM1_ID',
                "quantity": "10",
                "taxRate": 0,
                "taxType": "exclusive",
                "hsn_sac_code": "998860",
                "customField": null,
                "invoiceItemSnapshot": {
                    "itemName": "WELDMNT TORQUE ARM",
                    "unitPriceCents": "1600000",
                    "unitName": "Nos",
                    "hsn_sac_code": "998860"
                }
            },
            {
                "itemId": '$ITEM2_ID',
                "quantity": "8",
                "taxRate": 0,
                "taxType": "exclusive",
                "hsn_sac_code": "998730",
                "customField": null,
                "invoiceItemSnapshot": {
                    "itemName": "Installation & Labour Charges",
                    "unitPriceCents": "500000",
                    "unitName": "Hrs",
                    "hsn_sac_code": "998730"
                }
            }
        ],
        "invoicePayments": [],
        "invoiceAttachments": [],
        "invoiceBusinessSnapshot": {
            "businessName": "Kavya Industries",
            "businessShortName": "KI",
            "businessAddress": "Plot No. 42, Phase III, MIDC Industrial Area, Pune - 411018, Maharashtra, India",
            "businessRole": "Seller",
            "businessEmail": "info@kavyaindustries.com",
            "businessPhone": "+91-9876543210",
            "businessAdditional": "GSTIN: 27AABCK1234M1Z5",
            "businessVatCode": "27AABCK1234M1Z5",
            "businessCountryCode": "IN",
            "businessCode": "KI"
        },
        "invoiceClientSnapshot": {
            "clientName": "GOVIND PRECISION TECH INDIA PVT.LTD",
            "clientAddress": "Survey No. 123, Chakan Industrial Area, Pune - 410501, Maharashtra, India",
            "clientEmail": "accounts@govindprecision.com",
            "clientPhone": "+91-2135-276541",
            "clientCode": "GPT",
            "clientAdditional": "Contact: Mr. Rajesh Sharma (Purchase Manager)",
            "clientVatCode": "27AAKCG7481Q1ZM",
            "clientCountryCode": "IN",
            "clientBuyerReference": "PO-2026-0892"
        },
        "invoiceCurrencySnapshot": {
            "currencyCode": "INR",
            "currencySymbol": "₹",
            "currencySubunit": 100
        },
        "invoiceBankSnapshot": {
            "name": "HDFC Bank - Main Branch",
            "bankName": "HDFC Bank Ltd",
            "accountNumber": "50100234567890",
            "swiftCode": "HDFCINBB",
            "address": "HDFC Bank House, 2nd Floor, Pune - 411001",
            "branchCode": "PUNE001",
            "type": "Savings",
            "accountHolder": "Kavya Industries",
            "upiCode": "kavyaindustries@hdfcbank"
        },
        "invoiceStyleProfileSnapshot": {
            "styleProfileName": "Default"
        },
        "invoiceLayoutSnapshot": {
            "layoutSchema": {
                "sections": [
                    {
                        "type": "header",
                        "blocks": [
                            {
                                "type": "row",
                                "children": [
                                    {"type": "logo", "width": "20%"},
                                    {"type": "title", "width": "40%"},
                                    {"type": "invoiceMeta", "width": "40%", "showTitle": false, "showInvoiceLabel": true}
                                ],
                                "justify": "between",
                                "align": "start"
                            },
                            {"type": "businessInfo"},
                            {"type": "clientInfo"}
                        ]
                    },
                    {"type": "itemsTable", "columnSizing": "fixedFlex"},
                    {"type": "financialTotals"},
                    {"type": "notes"},
                    {"type": "signature"},
                    {"type": "pageCounter"}
                ]
            }
        },
        "invoiceCustomization": {
            "color": "#1976d2",
            "logoSize": "medium",
            "fontSize": "medium",
            "fontFamily": "Inter",
            "tableHeaderStyle": "light",
            "tableRowStyle": "bordered",
            "pageFormat": "A4",
            "labelUpperCase": true,
            "showQuantity": true,
            "showUnit": true,
            "showRowNo": false,
            "fieldSortOrders": {
                "no": 0,
                "item": 1,
                "hsnSac": 2,
                "quantity": 3,
                "unit": 4,
                "unitCost": 5,
                "total": 6,
                "tax": 7,
                "discount": 8
            }
        }
    }' 2>/dev/null)

check_response "$INVOICE_RESPONSE" "Tax Invoice creation"
INVOICE_ID=$(extract_id "$INVOICE_RESPONSE")
echo "Invoice ID: $INVOICE_ID"
echo "Invoice Number: INV-001/26-27"
echo ""
echo "Invoice Summary:"
echo "  Item 1: WELDMNT TORQUE ARM x 10 = ₹1,60,000"
echo "  Item 2: Installation & Labour x 8 = ₹40,000"
echo "  Subtotal: ₹2,00,000"
echo "  Discount (5%): -₹10,000"
echo "  After Discount: ₹1,90,000"
echo "  Shipping: ₹2,500"
echo "  CGST @ 9%: ₹17,100"
echo "  SGST @ 9%: ₹17,100"
echo "  Grand Total: ₹2,26,700"
echo "  Amount in Words: RUPEES TWO LAKH TWENTY SIX THOUSAND SEVEN HUNDRED ONLY"

# =============================================================================
# STEP 11: CREATE DELIVERY CHALLAN
# =============================================================================
print_step "11. Creating Delivery Challan"

CHALLAN_RESPONSE=$(curl -s -X POST "$BASE_URL/invoices" \
    -H "Content-Type: application/json" \
    -d '{
        "invoiceType": "challan",
        "businessId": '$BUSINESS_ID',
        "clientId": '$CLIENT_ID',
        "currencyId": '$CURRENCY_ID',
        "bankId": '$BANK_ID',
        "layoutId": '$LAYOUT_ID',
        "invoiceNumber": "001",
        "issuedAt": "2026-09-14T00:00:00.000Z",
        "dueDate": null,
        "status": "open",
        "isArchived": false,
        "language": "en",
        "invoicePrefix": "DC-",
        "invoiceSuffix": "/26-27",
        "customerNotes": "Goods sent for on-site installation. To be returned after completion.",
        "thanksNotes": "",
        "termsConditionNotes": "1. Goods must be returned within 30 days.\n2. Damage to goods will be charged.",
        "discountName": "",
        "discountType": "fixed",
        "discountAmountCents": "0",
        "discountPercent": 0,
        "shippingFeeCents": "0",
        "surchargeName": "",
        "surchargeAmountCents": "0",
        "surchargeType": "fixed",
        "surchargePercent": 0,
        "taxName": "",
        "taxRate": 0,
        "taxType": null,
        "cgstRate": 0,
        "sgstRate": 0,
        "cgstAmount": "0",
        "sgstAmount": "0",
        "vehicleNumber": "MH-12-AB-1234",
        "transporterName": "Safe Express Logistics Pvt Ltd",
        "receiverName": "Mr. Rajesh Sharma",
        "invoiceItems": [
            {
                "itemId": '$ITEM1_ID',
                "quantity": "5",
                "taxRate": 0,
                "taxType": null,
                "hsn_sac_code": "998860",
                "customField": null,
                "invoiceItemSnapshot": {
                    "itemName": "WELDMNT TORQUE ARM",
                    "unitPriceCents": "0",
                    "unitName": "Nos",
                    "hsn_sac_code": "998860"
                }
            },
            {
                "itemId": '$ITEM3_ID',
                "quantity": "20",
                "taxRate": 0,
                "taxType": null,
                "hsn_sac_code": "7208",
                "customField": null,
                "invoiceItemSnapshot": {
                    "itemName": "Mild Steel Plate 10mm",
                    "unitPriceCents": "0",
                    "unitName": "Kg",
                    "hsn_sac_code": "7208"
                }
            }
        ],
        "invoicePayments": [],
        "invoiceAttachments": [],
        "invoiceBusinessSnapshot": {
            "businessName": "Kavya Industries",
            "businessShortName": "KI",
            "businessAddress": "Plot No. 42, Phase III, MIDC Industrial Area, Pune - 411018, Maharashtra, India",
            "businessRole": "Sender",
            "businessEmail": "info@kavyaindustries.com",
            "businessPhone": "+91-9876543210",
            "businessAdditional": "GSTIN: 27AABCK1234M1Z5",
            "businessVatCode": "27AABCK1234M1Z5",
            "businessCountryCode": "IN",
            "businessCode": "KI"
        },
        "invoiceClientSnapshot": {
            "clientName": "GOVIND PRECISION TECH INDIA PVT.LTD",
            "clientAddress": "Survey No. 123, Chakan Industrial Area, Pune - 410501, Maharashtra, India",
            "clientEmail": "accounts@govindprecision.com",
            "clientPhone": "+91-2135-276541",
            "clientCode": "GPT",
            "clientAdditional": "Contact: Mr. Rajesh Sharma (Purchase Manager)",
            "clientVatCode": "27AAKCG7481Q1ZM",
            "clientCountryCode": "IN",
            "clientBuyerReference": "PO-2026-0892"
        },
        "invoiceCurrencySnapshot": {
            "currencyCode": "INR",
            "currencySymbol": "₹",
            "currencySubunit": 100
        },
        "invoiceBankSnapshot": {
            "name": "HDFC Bank - Main Branch",
            "bankName": "HDFC Bank Ltd",
            "accountNumber": "50100234567890",
            "swiftCode": "HDFCINBB",
            "address": "HDFC Bank House, 2nd Floor, Pune - 411001",
            "branchCode": "PUNE001",
            "type": "Savings",
            "accountHolder": "Kavya Industries",
            "upiCode": "kavyaindustries@hdfcbank"
        },
        "invoiceStyleProfileSnapshot": {
            "styleProfileName": "Default"
        },
        "invoiceLayoutSnapshot": {
            "layoutSchema": {
                "sections": [
                    {
                        "type": "header",
                        "blocks": [
                            {
                                "type": "row",
                                "children": [
                                    {"type": "logo", "width": "20%"},
                                    {"type": "title", "width": "40%"},
                                    {"type": "invoiceMeta", "width": "40%", "showTitle": false, "showInvoiceLabel": true}
                                ],
                                "justify": "between",
                                "align": "start"
                            },
                            {"type": "businessInfo"},
                            {"type": "clientInfo"}
                        ]
                    },
                    {"type": "itemsTable", "columnSizing": "fixedFlex"},
                    {"type": "notes"},
                    {"type": "signature"},
                    {"type": "pageCounter"}
                ]
            }
        },
        "invoiceCustomization": {
            "color": "#388e3c",
            "logoSize": "medium",
            "fontSize": "medium",
            "fontFamily": "Inter",
            "tableHeaderStyle": "light",
            "tableRowStyle": "bordered",
            "pageFormat": "A4",
            "labelUpperCase": true,
            "showQuantity": true,
            "showUnit": true,
            "showRowNo": false,
            "fieldSortOrders": {
                "no": 0,
                "item": 1,
                "hsnSac": 2,
                "quantity": 3,
                "unit": 4
            }
        }
    }' 2>/dev/null)

check_response "$CHALLAN_RESPONSE" "Delivery Challan creation"
CHALLAN_ID=$(extract_id "$CHALLAN_RESPONSE")
echo "Challan ID: $CHALLAN_ID"
echo "Challan Number: DC-001/26-27"
echo ""
echo "Challan Summary:"
echo "  Vehicle Number: MH-12-AB-1234"
echo "  Transporter: Safe Express Logistics Pvt Ltd"
echo "  Receiver: Mr. Rajesh Sharma"
echo "  Items:"
echo "    1. WELDMNT TORQUE ARM x 5 Nos"
echo "    2. Mild Steel Plate 10mm x 20 Kg"

# =============================================================================
# STEP 12: VERIFY SEED DATA
# =============================================================================
print_step "12. Verifying seeded data"

echo ""
echo "Fetching all items..."
ITEMS=$(curl -s "$BASE_URL/items" 2>/dev/null)
echo "$ITEMS" | grep -o '"name":"[^"]*"' | head -10

echo ""
echo "Fetching all clients..."
CLIENTS=$(curl -s "$BASE_URL/clients" 2>/dev/null)
echo "$CLIENTS" | grep -o '"name":"[^"]*"' | head -5

echo ""
echo "Fetching all invoices..."
INVOICES=$(curl -s "$BASE_URL/invoices" 2>/dev/null)
echo "$INVOICES" | grep -o '"invoiceNumber":"[^"]*"' | head -5

# =============================================================================
# COMPLETION
# =============================================================================
echo ""
echo -e "${GREEN}==================================================${NC}"
echo -e "${GREEN}SEED DATA COMPLETED SUCCESSFULLY!${NC}"
echo -e "${GREEN}==================================================${NC}"
echo ""
echo "Summary of created entities:"
echo "  - Currency: INR (₹) (ID: $CURRENCY_ID)"
echo "  - Units: pcs (ID: $UNIT_PCS_ID), hrs (ID: $UNIT_HRS_ID), kgs (ID: $UNIT_KGS_ID)"
echo "  - Category: Industrial Equipment (ID: $CATEGORY_ID)"
echo "  - Business: Kavya Industries (ID: $BUSINESS_ID)"
echo "  - Bank: HDFC Bank (ID: $BANK_ID)"
echo "  - Client: GOVIND PRECISION TECH INDIA PVT.LTD (ID: $CLIENT_ID)"
echo "  - Items:"
echo "    1. WELDMNT TORQUE ARM (HSN: 998860) - ₹16,000/Nos (ID: $ITEM1_ID)"
echo "    2. Installation & Labour Charges (HSN: 998730) - ₹5,000/Hrs (ID: $ITEM2_ID)"
echo "    3. Mild Steel Plate 10mm (HSN: 7208) - ₹8,500/Kg (ID: $ITEM3_ID)"
echo "  - Layout: Standard Invoice Layout (ID: $LAYOUT_ID)"
echo "  - Tax Invoice: INV-001/26-27 (ID: $INVOICE_ID)"
echo "  - Delivery Challan: DC-001/26-27 (ID: $CHALLAN_ID)"
echo ""
echo "Test the features:"
echo "  1. HSN/SAC codes visible on items"
echo "  2. CGST/SGST split at 9% each on invoice"
echo "  3. Amount in Words: RUPEES TWO LAKH TWENTY SIX THOUSAND SEVEN HUNDRED ONLY"
echo "  4. Delivery Challan with Vehicle No, Transporter, Receiver fields"
echo ""
echo "Open the app at http://localhost:5173 to view the seeded data."
