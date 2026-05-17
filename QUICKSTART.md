# Quickstart

This guide walks you from zero to a running invoice processing workflow.

**What n8n is:** a server with a browser-based UI where you build, configure, and run workflows. Your IDE is only for editing `workflow/invoice_processor.json`. You cannot trigger the workflow from your IDE.

- **IDE** — modify the workflow JSON
- **n8n UI** (browser) — run it, set credentials, monitor executions

---

## Already configured? Run it now

Use this if you've already imported the workflow, set up all credentials, and replaced all placeholders.

1. Make sure Ollama is running with the right model:
   ```bash
   ollama serve
   ollama pull qwen3:8b   # skip if already pulled
   ```
2. Start n8n:
   ```bash
   npx n8n
   ```
3. Open `http://localhost:5678`
4. Email a sample invoice (PDF or image) to your Gmail account and make sure it lands under the configured label or ID (e.g. INBOX)
5. In the n8n canvas, click **Execute Workflow** — this runs immediately without waiting for the 5-minute poll
6. Watch each node light up. Results appear in your Google Sheet and Slack channel

Show Google Sheets: https://docs.google.com/spreadsheets/d/REPLACE_WITH_YOUR_GOOGLE_SHEET_ID/edit
Show Slack: https://app.slack.com/client/REPLACE_WITH_YOUR_SLACK_WORKSPACE_ID/REPLACE_WITH_YOUR_SLACK_CHANNEL_ID

---

## Prerequisites — External setup (do all of this before opening n8n)

### Node.js
Required to run n8n locally. Install from nodejs.org (LTS version). Verify:
```bash
node -v   # should be 18+
```

### Ollama
The workflow is configured to use a local Ollama model out of the box. Install Ollama from ollama.com, then pull the model:
```bash
ollama pull qwen3:8b
```

The Ollama branch extracts plain text from the PDF first (via the `Extract From File` node) before sending it to the model, so both PDFs and images work. No vision capability required.

> **OpenAI instead:** If you want to use GPT-4o, see [Switching providers](#switching-providers) below.

### Google Cloud — Gmail + Sheets OAuth2
n8n connects to Google via OAuth2. You need to create a Google Cloud app once:

1. Go to console.cloud.google.com → Create a new project
2. Go to **APIs & Services** → **Enable APIs** → enable both:
   - Gmail API
   - Google Sheets API
3. Go to **APIs & Services** → **Credentials** → **Create Credentials** → **OAuth client ID**
   - Application type: **Web application**
   - Authorized redirect URI: `http://localhost:5678/rest/oauth2-credential/callback`
4. Copy the **Client ID** and **Client Secret** — you'll enter these in n8n when creating the Gmail and Sheets credentials
5. Add yourself as a test user:
   - **APIs & Services** → **OAuth consent screen** → **Audience** tab
   - Scroll to **Test users** → **+ Add Users** → enter your Gmail address → **Save**

### Google Sheet
Create this before Step 4 so you have the Sheet ID ready.

1. Go to sheets.google.com → **Blank spreadsheet**
2. Rename the file to something like `Invoice Processor`
3. Rename **Sheet1** to `Invoices`
4. In row 1, paste these headers (copy the line below and paste into cell A1 — Google Sheets will split on tabs automatically):
   ```
   timestamp	vendor_name	invoice_number	invoice_date	due_date	total_amount	currency	confidence	notes
   ```
5. Copy your **Sheet ID** from the URL — the string between `/d/` and `/edit`:
   ```
   https://docs.google.com/spreadsheets/d/YOUR_SHEET_ID_IS_HERE/edit
   ```

### Gmail label
1. In Gmail, create a label called `invoice-inbox`
2. Optionally add a filter to apply it automatically to incoming invoices

### Slack app
1. Go to api.slack.com/apps → **Create New App** → From scratch
2. Under **OAuth & Permissions** → **Bot Token Scopes**, add: `chat:write`, `channels:read`, `channels:join`
3. Click **Install to Workspace** → copy the **Bot User OAuth Token** (starts with `xoxb-`)
4. In Slack, right-click the channel you want notifications in → **Copy link** → the channel ID is the `C…` string at the end of the URL
5. **Invite the bot to the channel** — open the channel in Slack and type:
   ```
   /invite @your-app-name
   ```
   The bot must be a channel member before it can post. Without this you'll get a `not_in_channel` error.

---

## Step 1 — Get n8n running

```bash
npx n8n
```

Then open `http://localhost:5678` in your browser.

> **n8n Cloud:** Sign up at n8n.io (free trial) if you prefer not to run locally. No install needed, but you'll need to expose your Ollama instance publicly or use OpenAI instead.

---

## Step 2 — Import the workflow

1. In the n8n UI, open a workflow canvas
2. Click the **⋯** (three-dot menu) in the top bar → **Import from File**
3. Select `workflow/invoice_processor.json` from this repo

The workflow canvas will appear with all nodes connected.

---

## Step 3 — Set up credentials

Go to **Credentials** → **Add Credential** in the left sidebar. Add one entry for each service below. After creating each credential, open the matching node in the canvas and assign it from the dropdown.

### Gmail
Search for **Gmail OAuth2 API**. n8n will walk you through connecting your Google account via OAuth.

### OpenAI (optional — only needed if using OpenAI)
Search for **OpenAI API**. Paste your API key from platform.openai.com. You can skip this if you're using Ollama only.

### Google Sheets
Search for **Google Sheets OAuth2 API**. Enter the **Client ID** and **Client Secret** from the Google Cloud app you created in Prerequisites. n8n will open a Google login popup to complete the OAuth handshake — sign in as the account that owns the Sheet.

### Slack
Search for **Slack API** and paste in the **Bot User OAuth Token** (starts with `xoxb-`) from api.slack.com/apps → your app → **OAuth & Permissions**.

---

## Step 4 — Replace the placeholders

Each node that contains a `REPLACE_WITH_YOUR_*` value needs a real ID. Click the node in the canvas to edit it:

| Node | What to fill in |
|---|---|
| Gmail Trigger | Assign your Gmail credential |
| OpenAI — Extract Invoice | Assign your OpenAI credential (skip if Ollama-only) |
| Both Sheets nodes | Your Google Sheet ID + Sheets credential |
| Both Slack nodes | Your Slack channel ID (`C…` string) + Slack credential |

---

## Step 5 — Test it

**Generate sample PDFs** (optional — a JPEG is included in `samples/` already):
```bash
bash samples/build_pdfs.sh
```
See `CLAUDE.md` for install requirements (`pandoc`, `xelatex`).

**Run a test:**
1. Email a sample invoice (PDF or image) to your Gmail account so it lands under the `invoice-inbox` label
2. Start n8n: `npx n8n`
3. In the n8n canvas, click **Execute Workflow** to run immediately
4. Watch each node light up as it executes
5. Check your Google Sheet for a new row and your Slack channel for a notification

**Troubleshooting:**
- *"The workflow has issues and cannot be executed"* — one or more nodes still has a placeholder value or a missing credential. Look for nodes with a red or orange warning dot in the canvas and fix those first. You can right-click and **Disable** any node not needed for your current test path (e.g. disable the OpenAI node if you're testing Ollama only).
- *Slack `not_in_channel` error* — the bot hasn't been invited to the channel. Type `/invite @your-app-name` in the Slack channel.
- *Ollama connection refused* — use `127.0.0.1` not `localhost`. On macOS, `localhost` resolves to IPv6 (`::1`) first but Ollama only listens on IPv4.

---

## Switching providers

The workflow is hardcoded to Ollama + `qwen3:8b` by default. To switch to OpenAI (GPT-4o), edit `workflow/invoice_processor.json` in three places, then re-import:

| Location | Ollama value | OpenAI value |
|---|---|---|
| `Provider Switch` → `leftValue` | `"ollama"` | `"openai"` |
| `Normalize Response` → `const provider` | `'ollama'` | `'openai'` |
| `OpenAI — Extract Invoice` → URL | *(unused)* | already set to OpenAI |

When switching to OpenAI, make sure the OpenAI credential is assigned to the `OpenAI — Extract Invoice` node.

> **Why not env vars?** n8n community edition blocks `$env` access inside node expressions by default, so provider settings are hardcoded directly in the workflow JSON instead.

---

## The edit loop

Once the workflow is running, the normal iteration cycle is:

1. Edit `workflow/invoice_processor.json` in your IDE
2. Validate the JSON: `jq . workflow/invoice_processor.json`
3. In the n8n UI: open your workflow → **⋯** menu → **Import** to reload the updated file
4. Test again

The JavaScript code lives in two nodes: `Normalize Response` (unwraps the LLM response) and `Parse & Classify` (routing logic and output shape). Everything else is configuration.
