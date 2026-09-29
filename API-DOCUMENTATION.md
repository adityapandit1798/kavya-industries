# API Endpoints Documentation

## Overview

This document describes the REST API endpoints for the Invoice Builder application. The API is designed for local/single-user Electron app use with no authentication required.

**Base URL:** `http://localhost:3000/api`

---

## Database Management

| Method | Endpoint | Description | Key Payload Fields |
|--------|----------|-------------|-------------------|
| GET | `/api/databases` | List available SQLite databases | None |
| POST | `/api/databases` | Initialize/open a database | `fullPath`, `mode`, `dbType` |
| POST | `/api/databases/test` | Test PostgreSQL connection | `postgresConfig.*` |

### POST /api/databases
```json
{
  "fullPath": "kavya-industries.db",
  "mode": "create",           // "create" | "open"
  "dbType": "SQLite"          // "SQLite" (capital S) | "PostgreSQL"
}
```

**Note:** All other endpoints require database initialization first.

---

## Items

| Method | Endpoint | Description | Key Payload Fields |
|--------|----------|-------------|-------------------|
| GET | `/api/items` | List all items | `?filter=...` |
| POST | `/api/items` | Create an item | `name`, `amount`, `unitId`, `hsn_sac_code` |
| PUT | `/api/items/:id` | Update an item | Same as create + `id` |
| DELETE | `/api/items/:id` | Delete an item | None |
| POST | `/api/items/batch` | Batch create items | Array of items |

### POST /api/items
```json
{
  "name": "WELDMNT TORQUE ARM",
  "amount": "16000.00",        // Price as string
  "unitId": 1,
  "categoryId": 1,
  "description": "Heavy duty torque arm",
  "hsn_sac_code": "998860",   // HSN/SAC code for GST
  "isArchived": false
}
```

---

## Clients

| Method | Endpoint | Description | Key Payload Fields |
|--------|----------|-------------|-------------------|
| GET | `/api/clients` | List all clients | `?filter=...` |
| POST | `/api/clients` | Create a client | `name`, `shortName`, `vatCode` |
| PUT | `/api/clients/:id` | Update a client | Same as create + `id` |
| DELETE | `/api/clients/:id` | Delete a client | None |
| POST | `/api/clients/batch` | Batch create clients | Array of clients |

### POST /api/clients
```json
{
  "name": "GOVIND PRECISION TECH INDIA PVT.LTD",
  "shortName": "GPT",
  "address": "Survey No. 123, Chakan Industrial Area, Pune",
  "email": "accounts@govindprecision.com",
  "phone": "+91-2135-276541",
  "code": "GPT",
  "vatCode": "27AAKCG7481Q1ZM",  // GST number
  "countryCode": "IN",
  "buyerReference": "PO-2026-0892"
}
```

---

## Invoices

| Method | Endpoint | Description | Key Payload Fields |
|--------|----------|-------------|-------------------|
| GET | `/api/invoices` | List all invoices | `?type=invoice\|quotation\|challan` |
| POST | `/api/invoices` | Create an invoice | Full invoice object (see below) |
| PUT | `/api/invoices/:id` | Update an invoice | Full invoice object + `id` |
| DELETE | `/api/invoices/:id` | Delete an invoice | None |
| POST | `/api/invoices/duplicate` | Duplicate an invoice | `invoiceId`, `invoiceType` |
| GET | `/api/invoices/sequence` | Get next sequence number | `?type=invoice\|quotation\|challan` |
| GET | `/api/invoices/headers` | Get custom field headers | None |

### POST /api/invoices - Tax Invoice with CGST/SGST
```json
{
  "invoiceType": "invoice",
  "businessId": 1,
  "clientId": 1,
  "currencyId": 1,
  "bankId": 1,
  "layoutId": 1,
  "invoiceNumber": "001",
  "issuedAt": "2026-09-14T00:00:00.000Z",
  "dueDate": "2026-10-14T00:00:00.000Z",
  "status": "open",
  "language": "en",
  "invoicePrefix": "INV-",
  "invoiceSuffix": "/26-27",
  
  "taxName": "GST",
  "taxRate": 0,
  "taxType": "exclusive",
  "cgstRate": 9,               // CGST rate percentage
  "sgstRate": 9,               // SGST rate percentage
  "cgstAmount": "0",           // Calculated amount (cents)
  "sgstAmount": "0",           // Calculated amount (cents)
  
  "discountType": "percentage",
  "discountPercent": 5,
  "shippingFeeCents": "250000",
  
  "invoiceItems": [
    {
      "itemId": 1,
      "quantity": "10",
      "taxRate": 0,
      "taxType": "exclusive",
      "hsn_sac_code": "998860",
      "invoiceItemSnapshot": {
        "itemName": "WELDMNT TORQUE ARM",
        "unitPriceCents": "1600000",  // Price in cents (16000 * 100)
        "unitName": "Nos",
        "hsn_sac_code": "998860"
      }
    }
  ],
  
  "invoiceBusinessSnapshot": { ... },
  "invoiceClientSnapshot": { ... },
  "invoiceCurrencySnapshot": {
    "currencyCode": "INR",
    "currencySymbol": "₹",
    "currencySubunit": 100
  },
  "invoiceBankSnapshot": { ... },
  "invoiceCustomization": { ... }
}
```

### POST /api/invoices - Delivery Challan
```json
{
  "invoiceType": "challan",    // Must be "challan"
  "businessId": 1,
  "clientId": 1,
  "currencyId": 1,
  "bankId": 1,
  "layoutId": 1,
  "invoiceNumber": "001",
  "issuedAt": "2026-09-14T00:00:00.000Z",
  "status": "open",
  "language": "en",
  "invoicePrefix": "DC-",
  "invoiceSuffix": "/26-27",
  
  "vehicleNumber": "MH-12-AB-1234",     // Vehicle registration
  "transporterName": "Safe Express Logistics",  // Transporter name
  "receiverName": "Mr. Rajesh Sharma",  // Receiver name
  
  "invoiceItems": [
    {
      "itemId": 1,
      "quantity": "5",
      "hsn_sac_code": "998860",
      "invoiceItemSnapshot": {
        "itemName": "WELDMNT TORQUE ARM",
        "unitPriceCents": "0",  // No prices on challan
        "unitName": "Nos",
        "hsn_sac_code": "998860"
      }
    }
  ],
  
  "invoiceBusinessSnapshot": { ... },
  "invoiceClientSnapshot": { ... },
  "invoiceCurrencySnapshot": { ... }
}
```

---

## Businesses

| Method | Endpoint | Description | Key Payload Fields |
|--------|----------|-------------|-------------------|
| GET | `/api/businesses` | List all businesses | None |
| POST | `/api/businesses` | Create a business | `name`, `shortName`, `vatCode` |
| PUT | `/api/businesses/:id` | Update a business | Same as create + `id` |
| DELETE | `/api/businesses/:id` | Delete a business | None |
| POST | `/api/businesses/batch` | Batch create | Array of businesses |

### POST /api/businesses
```json
{
  "name": "Kavya Industries",
  "shortName": "KI",
  "email": "info@kavyaindustries.com",
  "phone": "+91-9876543210",
  "role": "Seller",
  "address": "Plot No. 42, Phase III, MIDC Industrial Area, Pune - 411018",
  "vatCode": "27AABCK1234M1Z5",
  "countryCode": "IN",
  "paymentInformation": "HDFC Bank, A/C: 50100234567890"
}
```

---

## Banks

| Method | Endpoint | Description | Key Payload Fields |
|--------|----------|-------------|-------------------|
| GET | `/api/banks` | List all banks | None |
| POST | `/api/banks` | Create a bank | `name`, `bankName`, `accountNumber` |
| PUT | `/api/banks/:id` | Update a bank | Same as create + `id` |
| DELETE | `/api/banks/:id` | Delete a bank | None |
| POST | `/api/banks/batch` | Batch create | Array of banks |

### POST /api/banks
```json
{
  "name": "HDFC Bank - Main Branch",
  "bankName": "HDFC Bank Ltd",
  "accountNumber": "50100234567890",
  "swiftCode": "HDFCINBB",
  "address": "HDFC Bank House, Pune",
  "branchCode": "PUNE001",
  "type": "Savings",
  "accountHolder": "Kavya Industries",
  "upiCode": "kavyaindustries@hdfcbank"
}
```

---

## Currencies

| Method | Endpoint | Description | Key Payload Fields |
|--------|----------|-------------|-------------------|
| GET | `/api/currencies` | List all currencies | None |
| POST | `/api/currencies` | Create a currency | `code`, `symbol`, `text`, `format`, `subunit` |
| PUT | `/api/currencies/:id` | Update a currency | Same as create + `id` |
| DELETE | `/api/currencies/:id` | Delete a currency | None |
| POST | `/api/currencies/batch` | Batch create | Array of currencies |

### POST /api/currencies
```json
{
  "code": "INR",
  "symbol": "₹",
  "text": "Indian Rupee",
  "format": "{symbol}{amount}",
  "subunit": 100
}
```

---

## Units

| Method | Endpoint | Description | Key Payload Fields |
|--------|----------|-------------|-------------------|
| GET | `/api/units` | List all units | None |
| POST | `/api/units` | Create a unit | `name` |
| PUT | `/api/units/:id` | Update a unit | Same as create + `id` |
| DELETE | `/api/units/:id` | Delete a unit | None |
| POST | `/api/units/batch` | Batch create | Array of units |

### POST /api/units
```json
{
  "name": "Nos"
}
```

---

## Categories

| Method | Endpoint | Description | Key Payload Fields |
|--------|----------|-------------|-------------------|
| GET | `/api/categories` | List all categories | None |
| POST | `/api/categories` | Create a category | `name` |
| PUT | `/api/categories/:id` | Update a category | Same as create + `id` |
| DELETE | `/api/categories/:id` | Delete a category | None |
| POST | `/api/categories/batch` | Batch create | Array of categories |

### POST /api/categories
```json
{
  "name": "Industrial Equipment"
}
```

---

## Layouts

| Method | Endpoint | Description | Key Payload Fields |
|--------|----------|-------------|-------------------|
| GET | `/api/layouts` | List all layouts | None |
| POST | `/api/layouts` | Create a layout | `name`, `layoutSchema` |
| PUT | `/api/layouts/:id` | Update a layout | Same as create + `id` |
| DELETE | `/api/layouts/:id` | Delete a layout | None |
| GET | `/api/layouts/export/:id` | Export layout schema | None |

### POST /api/layouts
```json
{
  "name": "Standard Invoice Layout",
  "layoutSchema": {
    "sections": [
      { "type": "header", "blocks": [...] },
      { "type": "itemsTable", "columnSizing": "fixedFlex" },
      { "type": "financialTotals" },
      { "type": "notes" },
      { "type": "signature" },
      { "type": "pageCounter" }
    ]
  }
}
```

---

## Settings

| Method | Endpoint | Description | Key Payload Fields |
|--------|----------|-------------|-------------------|
| GET | `/api/settings` | Get all settings | None |
| PUT | `/api/settings` | Update settings | All settings fields |

### PUT /api/settings
```json
{
  "language": "en",
  "amountFormat": "{symbol}{amount}",
  "dateFormat": "dd/MM/yyyy",
  "isDarkMode": false,
  "invoicePrefix": "INV-",
  "invoiceSuffix": "",
  "shouldIncludeYear": true,
  "quotesON": true,
  "presetsON": true
}
```

---

## Import/Export

| Method | Endpoint | Description | Key Payload Fields |
|--------|----------|-------------|-------------------|
| GET | `/api/export` | Export all data as JSON | None |
| POST | `/api/import` | Import gzipped JSON | `file` (multipart form) |

---

## Key Notes

1. **No Authentication** - The API is designed for local Electron app use.

2. **Database Required** - Call `POST /api/databases` before any data operations.

3. **Prices in Cents** - All monetary values are stored as cents (integers). Multiply by 100 for display.

4. **GST Calculation** - CGST/SGST are calculated on the discounted amount, not the subtotal.

5. **Challan vs Invoice** - Challans have `invoiceType: "challan"` and include `vehicleNumber`, `transporterName`, `receiverName` fields.

6. **HSN/SAC Codes** - Both items and invoice line items can include HSN/SAC codes for GST compliance.
