# AI-Powered Invoice Processing Workflow

> Automatically extract invoice data from email attachments and write it to Google Sheets — no manual entry required.

---

## English

### The problem

Your team receives invoices by email. Someone opens each PDF, reads the numbers, types them into a spreadsheet, and hopes they didn't make a typo. This takes time, introduces errors, and scales badly when invoice volume grows.

### The solution

This n8n workflow watches a Gmail label for incoming invoices. When a new email arrives with a PDF or image attachment, the workflow:

1. **Downloads** the attachment automatically.
2. **Sends it to an AI model** (GPT-4o by default, or a local Ollama model for demos) with a bilingual (English/Japanese) extraction prompt.
3. **Parses the response** into structured fields: vendor, invoice number, date, amount, line items, and more.
4. **Writes a row** to your Google Sheet — ready for accounting, reconciliation, or reporting.
5. **Notifies your team** on Slack: a green tick for processed invoices, a warning for anything that needs human review.

Works with English and Japanese invoices out of the box.

---

### Architecture

```
Gmail (label: invoice-inbox)
        │
        ▼
┌──────────────────┐
│ Has attachment?  │ ── no ──▶  (skip)
└──────────────────┘
        │ yes
        ▼
┌──────────────────────┐
│  Split attachments   │  (one row per file)
└──────────────────────┘
        │
        ▼
┌──────────────────────┐
│   Provider Switch    │  reads LLM_PROVIDER variable
└──────────────────────┘
        │                          │
     openai                     ollama
        ▼                          ▼
┌───────────────┐        ┌───────────────────┐
│ OpenAI (GPT)  │        │  Ollama (local)   │
│ /v1/responses │        │ /v1/chat/completions│
└───────────────┘        └───────────────────┘
        │                          │
        └──────────┬───────────────┘
                   ▼
        ┌─────────────────────┐
        │  Normalize Response │  unifies provider output
        └─────────────────────┘
                   │
                   ▼
        ┌─────────────────────────────────┐
        │  Parse & classify (Code node)   │  → computes needs_review flag
        └─────────────────────────────────┘
                   │
        ├─ confidence=high, all fields present ──▶  Sheets "Invoices"  ──▶  Slack ✅
        │
        └─ confidence<high OR missing field    ──▶  Sheets "Needs Review"  ──▶  Slack ⚠️
```

---

### What the client needs to provide

| Requirement | Notes |
|---|---|
| Gmail account | Must be able to create labels and set up filters |
| Google Sheet | Two tabs: **Invoices** and **Needs Review** (see schema below) |
| OpenAI API key | GPT-4o access required (Tier 1 is sufficient for low volume). Not needed if using Ollama. |
| Slack workspace | One channel for notifications |
| n8n instance | Cloud or self-hosted (see Setup below) |
| Ollama (optional) | For local demo mode — runs models on your machine, no API key needed |

---

### Google Sheet schema

**Tab: Invoices**

| Column | Type | Notes |
|---|---|---|
| timestamp | datetime | ISO 8601 |
| email_from | string | Sender address |
| email_subject | string | |
| attachment_filename | string | |
| invoice_number | string | null if not found |
| vendor_name | string | null if not found |
| invoice_date | date | YYYY-MM-DD |
| due_date | date | YYYY-MM-DD |
| total_amount | number | No currency symbol |
| currency | string | ISO 4217 (JPY, USD…) |
| line_items_json | string | JSON array serialized as text |
| notes | string | Tax handling, ambiguities, etc. |
| confidence | string | high / medium / low |
| raw_json | string | Full model response (for audit) |

**Tab: Needs Review** — same columns, plus:

| Column | Type | Notes |
|---|---|---|
| review_reason | string | e.g. "confidence=medium; missing: invoice_number" |

---

### Setup

#### Option A: n8n Cloud (recommended for clients)

1. Sign up at [n8n.io](https://n8n.io) and create a workspace.
2. Go to **Credentials** and add:
   - **Gmail OAuth2** (connect your invoice Gmail account)
   - **OpenAI API** (paste your API key)
   - **Google Sheets OAuth2** (connect the account that owns the sheet)
   - **Slack OAuth2** (install the n8n Slack app to your workspace)
3. Go to **Workflows → Import from File** and upload `workflow/invoice_processor.json`.
4. Open the imported workflow and update the four `REPLACE_WITH_YOUR_*` placeholders:
   - Both Google Sheets nodes: set **Document ID** to your Sheet ID (from the URL: `.../spreadsheets/d/{ID}/edit`).
   - Both Slack nodes: set **Channel** to your notification channel.
5. In **n8n → Variables**, create the following variables:

   | Variable | Value |
   |---|---|
   | `EXTRACTION_PROMPT` | Full contents of `prompts/invoice_extraction.txt` |
   | `LLM_PROVIDER` | `openai` |
   | `LLM_BASE_URL` | `https://api.openai.com` |
   | `LLM_MODEL` | `gpt-4o` |
6. **Activate** the workflow (toggle in the top-right corner).

#### Option B: Self-hosted (Docker)

```bash
docker run -d \
  --name n8n \
  -p 5678:5678 \
  -v ~/.n8n:/home/node/.n8n \
  n8nio/n8n
```

Then follow steps 2–6 from Option A at `http://localhost:5678`.

---

### Gmail setup

1. In Gmail, create a label called `invoice-inbox`.
2. Create a filter: `has:attachment filename:pdf` → apply label `invoice-inbox`.
3. Optionally add sender-domain filters to narrow scope.

---

### First-run smoke test

1. Convert a sample invoice to PDF: `bash samples/build_pdfs.sh` (see prerequisites in that script).
2. Email `invoice_jp_01.pdf` to your Gmail account — it will self-apply the label within seconds.
3. Wait up to 5 minutes for the trigger to fire (or click **Test workflow** in n8n to run immediately).
4. Check:
   - A new row appears in the **Invoices** sheet.
   - A Slack message shows `✅ Invoice processed`.
5. Email a deliberately blurry or corrupt PDF to verify the **Needs Review** path.

---

### Customisation

| What to change | How |
|---|---|
| Switch to local model (demo mode) | Set `LLM_PROVIDER=ollama`, `LLM_BASE_URL=http://127.0.0.1:11434` (use `127.0.0.1`, not `localhost` — on macOS, `localhost` resolves to IPv6 which Ollama doesn't bind to), `LLM_MODEL=llama3.2-vision`. Note: Ollama supports images only, not PDFs. |
| Different document types (POs, receipts) | Update the `EXTRACTION_PROMPT` variable |
| Additional output fields | Extend the JSON schema in "OpenAI — Extract Invoice" and add columns in Sheets nodes |
| Different email source (Outlook, IMAP) | Swap the Gmail Trigger for Email Trigger or Microsoft Outlook Trigger |
| Output to Airtable, Notion, or a database | Replace the Google Sheets nodes with the relevant n8n node |
| Japanese-only mode | Remove the English examples from the prompt |
| Review threshold (stricter/looser) | Adjust the `needs_review` logic in the Code node |

---

### Notes on the HTTP Request node choice

The workflow uses an **HTTP Request** node rather than n8n's native OpenAI node. This is because the native node (as of May 2026) does not support `input_file` for PDFs — only `input_image` for raster images. Since invoices most commonly arrive as PDFs, HTTP Request gives us full access to the OpenAI Responses API without needing a PDF-to-image conversion step.

Using HTTP Request for both providers also makes the OpenAI and Ollama branches symmetric — both are plain HTTP calls, which keeps the provider-switching logic simple.

If your invoices arrive exclusively as images (PNG/JPG), you can swap the OpenAI HTTP Request node for the native **OpenAI node** (operation: "Message a Model") and configure it with image input — this simplifies credential management but removes PDF support.

---

---

## 日本語

# AIを使った請求書自動処理ワークフロー

> Gmailに届いた請求書の添付ファイルを自動で読み取り、Googleスプレッドシートにデータを転記します。手入力不要。

---

### こんなお悩みはありませんか？

メールで届く請求書をひとつひとつ開き、内容を手でスプレッドシートに入力している…そんな作業に時間をとられていませんか？入力ミスのリスクもあり、請求書の量が増えるほど負担が大きくなります。

---

### このワークフローでできること

n8nというローコードツールと、OpenAIのGPT-4oを組み合わせたワークフローです。Gmailの特定ラベル（例：`invoice-inbox`）に届いた請求書の添付ファイル（PDFや画像）を自動で処理します。

**処理の流れ：**

1. **Gmailを監視** — 指定ラベルに新しいメールが届くと自動で起動
2. **添付ファイルを取得** — PDFや画像ファイルを自動でダウンロード
3. **GPT-4oで内容を読み取る** — 日本語・英語どちらの請求書にも対応
4. **データを構造化** — 請求番号・請求日・支払期日・合計金額などを抽出
5. **Googleスプレッドシートに転記** — 指定のシートに自動で行を追加
6. **Slackに通知** — 処理完了は「✅」、要確認は「⚠️」で通知

---

### 日本語請求書への対応

このワークフローは日本語請求書に特化したルールを含んでいます：

- **税込・税抜の判別** — 税込合計がある場合はそちらを使用、税抜のみの場合はメモ欄に記録
- **消費税率の検出** — 10%（標準）・8%（軽減税率）を自動認識
- **銀行振込情報の記録** — 振込先もメモ欄に保存
- **適格請求書番号（インボイス番号）** — T+13桁の登録番号を検出

---

### ご用意いただくもの

| 必要なもの | 補足 |
|---|---|
| Gmailアカウント | 請求書受信用（ラベル機能を使います） |
| Googleスプレッドシート | 「請求書」と「要確認」の2つのタブを作成 |
| OpenAI APIキー | GPT-4oが使えるプランが必要です |
| Slackワークスペース | 通知用チャンネル1つ |
| n8nアカウント | クラウド版（n8n.io）が簡単でおすすめです |

---

### 導入手順（n8nクラウド版）

1. [n8n.io](https://n8n.io) でアカウントを作成します。
2. **認証情報（Credentials）** を設定します：
   - **Gmail OAuth2** — 請求書受信用Gmailアカウントを接続
   - **OpenAI API** — APIキーを入力
   - **Google Sheets OAuth2** — スプレッドシートのGoogleアカウントを接続
   - **Slack OAuth2** — n8nのSlackアプリをワークスペースに追加
3. **ワークフロー → ファイルからインポート** で `workflow/invoice_processor.json` をアップロードします。
4. ワークフロー内の `REPLACE_WITH_YOUR_*` の箇所を実際のIDに置き換えます：
   - Google SheetsノードのドキュメントID（URLの `/d/` と `/edit` の間の文字列）
   - SlackノードのチャンネルID
5. **n8n → 変数（Variables）** に以下の変数を作成します：

   | 変数名 | 値 |
   |---|---|
   | `EXTRACTION_PROMPT` | `prompts/invoice_extraction.txt` の内容を貼り付け |
   | `LLM_PROVIDER` | `openai` |
   | `LLM_BASE_URL` | `https://api.openai.com` |
   | `LLM_MODEL` | `gpt-4o` |
6. ワークフローを **有効化（Activate）** します。

---

### Gmailの設定

1. Gmailで `invoice-inbox` というラベルを作成します。
2. フィルター設定：「添付ファイルあり、ファイル名にpdfを含む」→ラベル `invoice-inbox` を付与
3. 送信元ドメインで絞り込むとさらに精度が上がります。

---

### 動作確認の手順

1. `samples/build_pdfs.sh` でサンプル請求書をPDFに変換します（pandocが必要です）。
2. `invoice_jp_01.pdf` をGmailアカウントに送信します。
3. 最大5分以内にワークフローが起動します（n8nの「テスト実行」ボタンで即時確認も可能）。
4. スプレッドシートに新しい行が追加されていることを確認してください。

---

### カスタマイズ例

- **対応書類の追加**（発注書、領収書など）→ `EXTRACTION_PROMPT` 変数を更新
- **出力先の変更**（Airtable、Notion、データベースなど）→ GoogleSheetsノードを入れ替え
- **通知先の変更**（メール、Chatworkなど）→ Slackノードを入れ替え
- **審査基準の調整**（より厳格/ゆるやかに）→ Codeノードの `needs_review` 条件を修正

---

ご不明な点はお気軽にご連絡ください。お客様の業務フローに合わせてカスタマイズいたします。
