# AI Invoice Processing — Client Pitch

## What it does

Automatically reads invoices from your email, extracts the key numbers, and writes them to a spreadsheet — so your team never has to do it manually again.

---

## The problem

Manual invoice processing is one of the most common time sinks in small-business operations:

- **Time cost**: A team member opens each PDF, reads the numbers, and types them into a spreadsheet — typically 5–15 minutes per invoice.
- **Error risk**: Manual data entry introduces typos and missed fields that cause payment delays and accounting headaches.
- **Volume scales badly**: 10 invoices a week is manageable. 50 is not.
- **Language barrier**: If you work with Japanese vendors or clients, bilingual invoice processing is an additional bottleneck.

---

## The solution

An automated workflow (built in n8n, a popular low-code automation tool) that:

1. **Watches your Gmail inbox** for emails with invoice attachments.
2. **Reads the invoice** using GPT-4o — the same AI behind ChatGPT — and extracts all the key fields.
3. **Writes a structured row** to your Google Sheet automatically.
4. **Notifies your team** on Slack when an invoice is processed, or when something looks uncertain and needs a human check.

No coding required to run it. Works with PDFs and images. Handles both English and Japanese invoices.

---

## Example ROI

| Before | After |
|---|---|
| ~10 minutes per invoice (manual entry + checking) | ~30 seconds per invoice (review only if flagged) |
| 2 hours/week for 12 invoices/week | ~15 minutes/week (flagged items only) |
| High error rate (fat-finger, copy-paste) | Near-zero data entry errors |
| Bilingual invoices require specialist time | Handled automatically |

> If your team currently spends 2 hours per week on invoice data entry, this workflow can bring that down to 15 minutes — freeing up roughly **85 hours per year** for higher-value work.

---

## What's included

| Deliverable | Description |
|---|---|
| **Workflow file** | Ready-to-import n8n workflow JSON |
| **Extraction prompt** | Tuned GPT-4o prompt for EN/JP invoices |
| **Sample invoices** | English, Japanese, and bilingual test documents |
| **Setup guide** | Step-by-step README in English and Japanese |
| **Setup support** | I walk you through the credential setup and first live test |

---

## What's customisable per client

Everything in this workflow can be adapted to your specific situation:

| Parameter | Options |
|---|---|
| **Document types** | Invoices, purchase orders, receipts, expense reports, contracts |
| **Fields extracted** | Add or remove any fields — tax ID, PO number, bank details, etc. |
| **Output destination** | Google Sheets, Airtable, Notion, Slack, email summary, CSV, database |
| **Notification channel** | Slack, Microsoft Teams, email, LINE, Chatwork |
| **Language** | English, Japanese, or any language GPT-4o supports |
| **Trigger** | Gmail, Outlook, IMAP, file drop in Google Drive or Dropbox |
| **Review threshold** | Tune how aggressively uncertain extractions are flagged |

---

## FAQ

**Can it handle Japanese invoices?**
Yes. The prompt is specifically designed for Japanese invoice formats, including 請求番号, 請求日, 支払期日, 消費税 (8% and 10%), 税込/税抜 amounts, and bank transfer details (銀行振込先).

**What if the invoice is a photo taken on a phone?**
GPT-4o has strong vision capabilities. It can read most photos of invoices as long as the text is legible. Very blurry or extreme-angle photos will be flagged for human review rather than silently misread.

**Is my data safe?**
Invoice PDFs are sent to OpenAI's API for processing (the same infrastructure used by ChatGPT Plus). OpenAI does not use API inputs to train their models by default. For highly sensitive documents, a self-hosted LLM option (e.g. running a model locally via Ollama) can be substituted — ask me about this if it's a requirement.

**What does it cost to run?**
n8n Cloud starts at $20/month. OpenAI API costs roughly $0.01–0.05 per invoice (depending on PDF size). For 50 invoices/month, total running cost is typically under $25/month.

**Do I need technical staff to maintain it?**
No. Once set up, the workflow runs automatically. If you want to change the fields it extracts or add a new document type, I can make those changes for you — usually in under an hour.

**What if it makes a mistake?**
Low-confidence extractions are automatically flagged and routed to a "Needs Review" tab in your spreadsheet, with a Slack alert. Nothing is silently wrong — uncertain results are always surfaced for human review.

---

*Interested? Let's schedule a 30-minute demo where I run the workflow live on one of your actual invoices.*
