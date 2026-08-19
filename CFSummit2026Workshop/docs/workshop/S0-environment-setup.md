# S0: Environment Validation (5 Minutes)

Your workshop AMI has everything pre-installed and configured. This checklist confirms it is working. Do NOT attempt to install or fix anything — if a step fails, raise your hand for instructor help.

## Step 1: Run Setup

Open: `http://localhost:8500/CFSummit2026Workshop/StyleMart/setup/setup.cfm`

You should see:
```
=== Datasources ===
[ok] datasource 'stylemart' registered (...)
[ok] datasource 'prologics' registered (...)

=== REST services ===
[ok] REST 'agent' registered at ...
[ok] REST 'commerce' registered at ...
[ok] REST 'logistics' (prologics) registered at ...

Setup complete.
```

If you see `[fail]` on any line, raise your hand for instructor help.

**When to re-run:** After any ColdFusion restart, or if you get "datasource not found" or "REST service not registered" errors.

---

## Validation Checklist

### Check 1: StoreFront Loads

**Action:** Open your browser. Navigate to `http://localhost:8500/CFSummit2026Workshop/StyleMart/`

**Expected:** The StyleMart product catalog page loads. You see product cards with images, names, and prices.

**What this proves:** ColdFusion 2025 is running, the database is seeded, and the web application is deployed.

---

### Check 2: Chat Panel Opens

**Action:** Click the chat icon (bottom-right corner of the page).

**Expected:** A chat panel slides open with a text input field and a mode toggle (Lab/Ref) in the header.

**What this proves:** The frontend JavaScript is loaded and the chat UI is functional.

---

### Check 3: Reference Mode Responds

**Action:** Toggle the mode selector to **Ref**. Type "hi" and press Enter.

**Expected:** Mira (the AI assistant) responds with a streaming greeting — tokens appear word-by-word. The response is 2-3 sentences.

**What this proves:** ColdFusion → OpenAI API → SSE streaming → browser rendering all work end-to-end.

---

### Check 4: Trace Panel Shows Events

**Action:** Open the trace panel (click the panel toggle, usually on the right side). Look at the events from your "hi" message.

**Expected:** You see events in this order: `model.start` → multiple `model.delta` → `model.end` → `done`

**What this proves:** The streaming event infrastructure is working. This panel is your primary debugging tool for all 6 sessions.

---

### Check 5: Lab Mode Is Empty (Correct!)

**Action:** Toggle the mode selector to **Lab**. Type "hi" and press Enter.

**Expected:** No response appears, or you see an error. **This is correct!** The lab files have TODO markers that you will fill in during Session 1.

**What this proves:** Lab mode is reading from the lab/ files (which have empty TODO zones). Your code will make it work.

---

### Check 6: Editor Ready

**Action:** Open VS Code (already installed). The workspace should show the `CFSummit2026Workshop` folder.

**Expected:** Navigate to `StyleMart/api/agent/s1/lab/ChatService.cfc`. You should see TODO-S1-4 in the file.

**What this proves:** Your editor is ready and you can find the files you will work on.

---

## What Each Mode Does

| Mode | What it reads | State |
|------|--------------|-------|
| **Lab** | `api/agent/sN/lab/*.cfc` | Your workspace — starts empty, you fill it in |
| **Ref** | `api/agent/sN/ref/*.cfc` | Complete reference — always works |

You can toggle between modes at any time. Use Ref to see the working version, then toggle back to Lab to continue your own code.

---

## If Something Fails

| Step that failed | What to do |
|-----------------|------------|
| Page does not load at all | Check that the URL is exactly `http://localhost:8500/CFSummit2026Workshop/StyleMart/` |
| Chat panel does not open | Try a hard refresh (Ctrl+Shift+R or Cmd+Shift+R) |
| Ref mode does not respond | Raise your hand — the API key or CF service may need attention |
| Trace panel is empty | Ensure you toggled to Ref mode before sending the message |
| VS Code does not show the folder | Open the folder manually: File → Open Folder → navigate to `CFSummit2026Workshop` |
| Any other failure | Raise your hand. Do NOT attempt to fix infrastructure. |

---

## You Are Ready

If all 6 checks passed: you are ready for Session 1. The instructor will begin shortly.

If Lab mode shows no response — that is correct. You will fix that in Session 1, Step 1.
