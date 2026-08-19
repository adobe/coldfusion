# StyleMart Brand Assets

Canonical brand vector marks. All marks use `currentColor` (except `favicon.svg`,
which is a filled badge for browser-tab visibility) so they inherit
`color: var(--ink)` (walnut `#3d2914`) on light surfaces and flip cleanly on
dark surfaces / themes without re-export.

## Files

| File | Viewport | Use |
|---|---|---|
| `mark.svg`     | 28×28   | Header icon, social avatar source, hangtag overlay |
| `wordmark.svg` | 160×28  | Footer, large hero placements, email signature, share-card |
| `lockup.svg`   | 200×32  | Mark + wordmark combined — alternate header / invoice header |
| `favicon.svg`  | 32×32   | Browser-tab favicon (filled walnut badge, cream S) |

## Design notes

- **Concept**: Italic capital "S" in a thin rounded-square frame — reads as a
  fabric-care label / luxury menswear tag. Single-letter monogram, paired with
  the Georgia italic wordmark used throughout the storefront.
- **Typography**: `Georgia, 'Playfair Display', 'Times New Roman', serif`,
  italic, weight 700. System-safe fallback chain — Georgia is universally
  installed on macOS / Windows / iOS / Android.
- **Color**: `currentColor` everywhere. Driven by `--ink: #3d2914` on light
  themes; flips automatically on the dark walnut theme via CSS.
- **Favicon exception**: hard-coded `#3d2914` background + `#fdfaf4` foreground
  so the tab badge has sufficient contrast on any browser-tab background.

## Replacing or extending

To swap the entire brand, edit the four SVGs in place. The header in
`includes/header.cfm` points at `assets/img/brand/mark.svg`; `shell.cfm` points
at `assets/img/brand/favicon.svg` via `<link rel="icon">`.
