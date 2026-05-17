# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this project is

A portfolio MVP demonstrating AI-powered invoice processing for businesses. An n8n workflow watches a Gmail label for invoice attachments (PDF or image), extracts structured data via GPT-4o, and writes rows to Google Sheets with a Slack notification. Designed to be explainable on a screen share to non-technical clients.

## Generating demo PDFs

```bash
bash samples/build_pdfs.sh
```

Requires `pandoc` and `xelatex` with CJK font support. Install on macOS:

```bash
brew install pandoc
brew install --cask basictex
sudo tlmgr update --self
sudo tlmgr install collection-fontsrecommended cjk-gs-integrate xecjk
```

Output PDFs (`samples/*.pdf`) are gitignored. These are the files you attach to a test email to trigger the workflow.

## Validating the workflow JSON

```bash
jq . workflow/invoice_processor.json
```

The workflow JSON must remain valid for n8n import. Run this after any edit.

## Architecture

The entire automation lives in one file: **`workflow/invoice_processor.json`** (importable into n8n via Workflows → Import from File).

**Node chain:**
```
Gmail Trigger → Has Attachment? (IF) → Split Attachments (SplitInBatches)
  → OpenAI — Extract Invoice (HTTP Request → POST /v1/responses)
  → Parse & Classify (Code node)
  → Needs Review? (IF)
      ├─ false → Sheets "Invoices"   → Slack ✅
      └─ true  → Sheets "Needs Review" → Slack ⚠️
```

**Key design decisions:**
- Uses **HTTP Request node** (not the native n8n OpenAI node) because the native node only supports `input_image`, not `input_file` for PDFs. The HTTP Request node targets the OpenAI Responses API (`/v1/responses`) directly.
- **`response_format: json_schema`** with `strict: true` is set in the HTTP Request body — the model is constrained to return exactly the fields in the schema, no free-form prose.
- **Review routing rule** in the Code node: `needs_review = confidence !== "high" || invoice_number == null || vendor_name == null || total_amount == null`.
- The extraction prompt is stored as an **n8n Variable** named `EXTRACTION_PROMPT` (not hardcoded in the node) — clients set it once and it's reusable across workflow versions.

**Credentials** (set in n8n Credentials manager, never in the JSON):
- `gmailOAuth2` — Gmail Trigger
- `openAiApi` — HTTP Request node
- `googleSheetsOAuth2Api` — both Sheets nodes
- `slackOAuth2Api` — both Slack nodes

The four `REPLACE_WITH_YOUR_*` placeholder strings in the workflow JSON must be substituted with real IDs before first use.

**Prompt:** `prompts/invoice_extraction.txt` is the standalone source of truth for the GPT-4o prompt. Its content must be pasted into the n8n `EXTRACTION_PROMPT` variable. It handles JP tax rules (税込/税抜, 消費税 8%/10%), enforces ISO date/currency formats, and defines the confidence rubric (high/medium/low).

**Samples:** Three Markdown invoices covering EN, JP (税込, 銀行振込), and mixed (JP vendor + EN client). The `build_pdfs.sh` script converts them to PDFs using `pandoc --pdf-engine=xelatex` with `Noto Sans CJK JP` for Japanese rendering.

## Extending the workflow

- **New document types** (POs, receipts): update the `EXTRACTION_PROMPT` variable and extend the JSON schema inside the HTTP Request node body.
- **New output destination**: replace the Google Sheets nodes with any n8n-supported node (Airtable, Notion, database).
- **Stricter/looser review threshold**: edit the `needs_review` expression in the Code node.
- **Image-only mode**: if PDFs are never used, swap the HTTP Request node for the native n8n OpenAI node (operation: "Message a Model", image input) — simpler credential management.
