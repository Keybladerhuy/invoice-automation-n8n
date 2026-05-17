# Setup Guide

> For a faster path if you've already done this before, see the [Quickstart](./QUICKSTART.md).

---

## Google Sheet schema

Create a spreadsheet with one tab named **Invoices**. Paste this into cell A1 — Google Sheets will split it across columns automatically:

```
timestamp	vendor_name	invoice_number	invoice_date	due_date	total_amount	currency	confidence	notes
```

---

## n8n setup

### Option A: n8n Cloud (recommended for clients)

1. Sign up at [n8n.io](https://n8n.io) and create a workspace
2. Go to **Credentials** and add:
   - **Gmail OAuth2** — connect your invoice Gmail account
   - **OpenAI API** — paste your API key (skip if using Ollama)
   - **Google Sheets OAuth2** — connect the account that owns the sheet
   - **Slack API** — paste your bot token (starts with `xoxb-`)
3. Go to **Workflows → Import from File** and upload `workflow/invoice_processor.json`
4. Open the workflow and fill in the `REPLACE_WITH_YOUR_*` placeholders:
   - Both Sheets nodes: your Google Sheet ID (from the URL: `.../d/{ID}/edit`)
   - Both Slack nodes: your Slack channel ID (the `C…` string)
5. **Activate** the workflow

### Option B: Self-hosted (Docker)

```bash
docker run -d \
  --name n8n \
  -p 5678:5678 \
  -v ~/.n8n:/home/node/.n8n \
  n8nio/n8n
```

Then follow steps 2–5 from Option A at `http://localhost:5678`.

### Option C: Local (npx)

```bash
npx n8n
```

Open `http://localhost:5678`, then follow steps 2–5 from Option A.

---

## Provider configuration

The workflow is hardcoded to Ollama + `qwen3:8b` by default. To switch to OpenAI, edit `workflow/invoice_processor.json` in three places and re-import:

| Location | Ollama value | OpenAI value |
|---|---|---|
| `Provider Switch` → `leftValue` | `"ollama"` | `"openai"` |
| `Normalize Response` → `const provider` | `'ollama'` | `'openai'` |
| `OpenAI — Extract Invoice` → URL | *(unused)* | already set |

> **Note:** n8n community edition blocks `$env` access in node expressions, so provider settings are hardcoded in the workflow JSON rather than environment variables.

---

## Ollama setup (local AI)

```bash
ollama pull qwen3:8b
ollama serve
```

> **macOS tip:** Use `127.0.0.1` not `localhost` — on macOS, `localhost` resolves to IPv6 which Ollama doesn't listen on.

The Ollama branch extracts plain text from the PDF via the `Extract From File` node before sending it to the model, so both PDFs and images work. No vision model required.

---

## Gmail setup

1. Invoices land in your **INBOX** by default — no label needed
2. Optionally create a label (e.g. `invoice-inbox`) and a filter to apply it automatically

---

## First-run test

1. Generate sample PDFs (optional — a JPEG is already in `samples/`):
   ```bash
   bash samples/build_pdfs.sh
   ```
2. Email a sample invoice to your Gmail account
3. In the n8n canvas, click **Execute Workflow** to run immediately (skips the 5-minute poll)
4. Check:
   - A new row appears in the **Invoices** sheet
   - A Slack message shows `✅ Invoice processed`

---

## Troubleshooting

| Error | Fix |
|---|---|
| *"The workflow has issues and cannot be executed"* | Look for nodes with a red/orange warning dot. Right-click and **Disable** any node you don't need (e.g. the OpenAI node when testing Ollama). |
| Slack `not_in_channel` | Invite the bot: type `/invite @your-app-name` in the Slack channel |
| Ollama connection refused | Use `127.0.0.1` not `localhost` |
| Env var access denied | Don't use `$env` in node expressions — hardcode values directly in the JSON |

---

## 日本語セットアップ

### Googleスプレッドシートの準備

「Invoices」という名前のタブを作成し、A1セルに以下をペーストしてください（Tabで区切られています）：

```
timestamp	vendor_name	invoice_number	invoice_date	due_date	total_amount	currency	confidence	notes
```

### 導入手順（n8nクラウド版）

1. [n8n.io](https://n8n.io) でアカウントを作成
2. **Credentials** で以下を追加：
   - **Gmail OAuth2** — 請求書受信用Gmailを接続
   - **OpenAI API** — APIキーを入力（Ollama使用時は不要）
   - **Google Sheets OAuth2** — スプレッドシートのアカウントを接続
   - **Slack API** — ボットトークン（`xoxb-`で始まる）を入力
3. **Workflows → Import from File** で `workflow/invoice_processor.json` をアップロード
4. `REPLACE_WITH_YOUR_*` の箇所を実際のIDに置き換え
5. ワークフローを **Activate（有効化）**

### 動作確認

1. サンプル請求書（`samples/` 内のJPEGファイル）をGmailに送信
2. n8nキャンバスで **Execute Workflow** をクリック
3. スプレッドシートに行が追加され、Slackに通知が届けば成功です
