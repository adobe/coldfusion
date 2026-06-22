# CFSummitTalk

Browser-based presentation for:

```text
Tokenomics: ROI and Metrics for Your AI Workflows
```

This is a standalone Vite, React, and TypeScript app. It is not wired into the main demo launcher.

## Open Through ColdFusion

Use this URL for normal presentation from the local ColdFusion server:

```text
http://localhost:8500/CFSummit2026/demos/CFSummitTalk/
```

That entry redirects to the built static deck in `dist/`.

## Static Review Export

For AI review or full-deck inspection without JavaScript routing, use:

```text
http://localhost:8500/CFSummit2026/demos/CFSummitTalk/review/
```

The same content is exported as Markdown at:

```text
http://localhost:8500/CFSummit2026/demos/CFSummitTalk/slides.md
```

Both files are generated from `src/content/tokenomicsSlides.ts` by:

```bash
npm.cmd run export:review
```

## Install

PowerShell may block `npm.ps1` on this machine. Use `npm.cmd` from PowerShell:

```bash
npm.cmd install
```

In other terminals, normal npm commands work:

```bash
npm install
```

## Run

```bash
npm.cmd run dev
```

Open the local URL Vite prints, usually:

```text
http://127.0.0.1:5173/
```

## Build

```bash
npm.cmd run build
```

The static output is written to:

```text
dist/
```

## Preview Build

```bash
npm.cmd run preview
```

## Keyboard Controls

| Key | Action |
| --- | --- |
| Right arrow or Space | Next slide |
| Left arrow | Previous slide |
| Home | First slide |
| End | Last slide |
| N | Toggle speaker notes |
| R | Toggle references |
| O | Toggle overview |
| Esc | Close open panel |

Slides can be linked directly with hash URLs such as:

```text
#/usage-is-not-roi
```

## Editing Content

Slide content lives in:

```text
src/content/tokenomicsSlides.ts
```

Citation definitions live in:

```text
src/content/citations.ts
```

Keep slide copy concise. Put rehearsal detail and source reminders in `speakerNotes`.

## PDF Export

Use the browser print dialog from the running app or preview build. The project includes print CSS that hides controls and side panels.
