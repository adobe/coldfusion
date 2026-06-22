import fs from "node:fs";
import path from "node:path";
import vm from "node:vm";
import { fileURLToPath } from "node:url";
import ts from "typescript";

const projectRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const slideModulePath = path.join(projectRoot, "src", "content", "tokenomicsSlides.ts");
const moduleCache = new Map();
const { slides } = loadTsModule(slideModulePath);

if (!Array.isArray(slides) || slides.length === 0) {
  throw new Error("No slides were exported from src/content/tokenomicsSlides.ts");
}

const reviewHtml = renderReviewHtml(slides);
const markdown = renderMarkdown(slides);

const outputTargets = [
  {
    html: path.join(projectRoot, "review", "index.html"),
    md: path.join(projectRoot, "slides.md")
  },
  {
    html: path.join(projectRoot, "public", "review", "index.html"),
    md: path.join(projectRoot, "public", "slides.md")
  }
];

for (const target of outputTargets) {
  fs.mkdirSync(path.dirname(target.html), { recursive: true });
  fs.mkdirSync(path.dirname(target.md), { recursive: true });
  fs.writeFileSync(target.html, reviewHtml, "utf8");
  fs.writeFileSync(target.md, markdown, "utf8");
}

console.log(`Generated review export for ${slides.length} slides.`);

function loadTsModule(filePath) {
  const resolvedPath = resolveTsPath(filePath);
  const cached = moduleCache.get(resolvedPath);

  if (cached) {
    return cached.exports;
  }

  const source = fs.readFileSync(resolvedPath, "utf8");
  const { outputText } = ts.transpileModule(source, {
    compilerOptions: {
      esModuleInterop: true,
      jsx: ts.JsxEmit.ReactJSX,
      module: ts.ModuleKind.CommonJS,
      target: ts.ScriptTarget.ES2022
    },
    fileName: resolvedPath
  });

  const module = { exports: {} };
  moduleCache.set(resolvedPath, module);

  const localRequire = (specifier) => {
    if (specifier.startsWith(".")) {
      return loadTsModule(path.resolve(path.dirname(resolvedPath), specifier));
    }

    throw new Error(`Unsupported import in review export script: ${specifier}`);
  };

  vm.runInNewContext(
    outputText,
    {
      console,
      exports: module.exports,
      module,
      require: localRequire
    },
    { filename: resolvedPath }
  );

  return module.exports;
}

function resolveTsPath(filePath) {
  if (path.extname(filePath)) {
    return filePath;
  }

  const tsPath = `${filePath}.ts`;
  if (fs.existsSync(tsPath)) {
    return tsPath;
  }

  const tsxPath = `${filePath}.tsx`;
  if (fs.existsSync(tsxPath)) {
    return tsxPath;
  }

  throw new Error(`Could not resolve TypeScript module: ${filePath}`);
}

function renderReviewHtml(deckSlides) {
  const deckTitle = `${deckSlides[0].visibleTitle}: ${deckSlides[0].visibleBody?.[0] ?? deckSlides[0].title}`;
  const slidesMarkup = deckSlides.map((slide, index) => renderSlideReview(slide, index, deckSlides.length)).join("\n");

  return `<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>${escapeHtml(deckTitle)} - Review Export</title>
    <style>
      :root {
        color-scheme: dark;
        --bg: #10141b;
        --panel: #171d27;
        --panel-strong: #202839;
        --ink: #f3f5f7;
        --muted: #aeb8c7;
        --line: #394255;
        --cyan: #6ed6e8;
        --amber: #f1c96b;
        --soft: #d8dee8;
        --warn: #f7b267;
        --ok: #8bd6a5;
      }

      * {
        box-sizing: border-box;
      }

      html {
        background: var(--bg);
        color: var(--ink);
        font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
        line-height: 1.5;
      }

      body {
        margin: 0;
      }

      main {
        width: min(1180px, calc(100% - 48px));
        margin: 0 auto;
        padding: 44px 0 64px;
      }

      .review-header {
        border-bottom: 1px solid var(--line);
        margin-bottom: 28px;
        padding-bottom: 24px;
      }

      .review-header p,
      .meta,
      .notes,
      .visual,
      .citation-note,
      .audit-ok {
        color: var(--muted);
      }

      h1,
      h2,
      h3 {
        line-height: 1.12;
        margin: 0;
      }

      .review-header h1 {
        font-size: clamp(2.2rem, 4vw, 4.25rem);
        letter-spacing: 0;
        margin-bottom: 10px;
      }

      .review-header p {
        max-width: 780px;
        font-size: 1.05rem;
        margin: 0;
      }

      .slide-review {
        background: var(--panel);
        border: 1px solid var(--line);
        border-radius: 8px;
        margin: 24px 0;
        overflow: hidden;
      }

      .slide-heading {
        background: linear-gradient(180deg, rgba(110, 214, 232, 0.09), rgba(110, 214, 232, 0));
        border-bottom: 1px solid var(--line);
        padding: 22px 24px;
      }

      .meta {
        display: flex;
        flex-wrap: wrap;
        gap: 10px 18px;
        font-size: 0.88rem;
        letter-spacing: 0.04em;
        margin-bottom: 12px;
        text-transform: uppercase;
      }

      .slide-heading h2 {
        color: var(--ink);
        font-size: clamp(1.7rem, 3vw, 2.6rem);
      }

      .slide-body {
        display: grid;
        gap: 18px;
        padding: 24px;
      }

      section.content-block {
        background: rgba(255, 255, 255, 0.025);
        border: 1px solid rgba(216, 222, 232, 0.12);
        border-radius: 8px;
        padding: 18px;
      }

      section.content-block h3 {
        color: var(--amber);
        font-size: 0.9rem;
        letter-spacing: 0.08em;
        margin-bottom: 12px;
        text-transform: uppercase;
      }

      p {
        margin: 0 0 10px;
      }

      p:last-child {
        margin-bottom: 0;
      }

      .primary {
        color: var(--soft);
        font-size: 1.12rem;
      }

      ul,
      ol {
        margin: 0;
        padding-left: 1.35rem;
      }

      li + li {
        margin-top: 6px;
      }

      .cards,
      .columns {
        display: grid;
        gap: 12px;
        grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
      }

      .card,
      .column {
        background: var(--panel-strong);
        border: 1px solid rgba(216, 222, 232, 0.14);
        border-radius: 8px;
        padding: 14px;
      }

      .card strong,
      .column strong {
        color: var(--cyan);
        display: block;
        margin-bottom: 6px;
      }

      table {
        border-collapse: collapse;
        width: 100%;
      }

      th,
      td {
        border: 1px solid rgba(216, 222, 232, 0.16);
        padding: 10px 12px;
        text-align: left;
        vertical-align: top;
      }

      th {
        background: rgba(110, 214, 232, 0.1);
        color: var(--cyan);
      }

      code {
        background: rgba(216, 222, 232, 0.09);
        border: 1px solid rgba(216, 222, 232, 0.16);
        border-radius: 4px;
        color: var(--ink);
        padding: 0.1rem 0.35rem;
      }

      .visual {
        border-left: 3px solid var(--cyan);
        padding-left: 14px;
      }

      .notes {
        border-left: 3px solid var(--amber);
        padding-left: 14px;
      }

      .audit-ok {
        border-left: 3px solid var(--ok);
        padding-left: 14px;
      }

      .audit-warning {
        border-left: 3px solid var(--warn);
        color: var(--warn);
        padding-left: 14px;
      }

      .citations a {
        color: var(--cyan);
        overflow-wrap: anywhere;
      }

      @media print {
        :root {
          color-scheme: light;
        }

        html {
          background: #ffffff;
          color: #111827;
        }

        main {
          width: 100%;
          padding: 0;
        }

        .slide-review {
          background: #ffffff;
          border-color: #c6ccd6;
          break-inside: avoid;
          page-break-inside: avoid;
        }

        .slide-heading,
        section.content-block,
        .card,
        .column {
          background: #ffffff;
        }
      }
    </style>
  </head>
  <body>
    <main>
      <header class="review-header">
        <h1>${escapeHtml(deckTitle)}</h1>
        <p>Static review export. This page contains all ${deckSlides.length} slides, visible slide content, speaker notes, citations, text descriptions of visual elements, and a manifest audit warning when rendered text is not listed in visible fields.</p>
      </header>
${slidesMarkup}
    </main>
  </body>
</html>
`;
}

function renderSlideReview(slide, index, total) {
  const audit = auditSlide(slide);

  return `      <article class="slide-review" id="${escapeAttribute(slide.id)}">
        <header class="slide-heading">
          <div class="meta">
            <span>Slide ${String(index + 1).padStart(2, "0")} / ${String(total).padStart(2, "0")}</span>
            <span>ID: <code>${escapeHtml(slide.id)}</code></span>
            <span>Layout: ${escapeHtml(slide.layout)}</span>
          </div>
          <h2>${escapeHtml(slide.title)}</h2>
        </header>
        <div class="slide-body">
          <section class="content-block">
            <h3>Visible Slide Content</h3>
${renderVisibleContentHtml(slide)}
          </section>
          <section class="content-block">
            <h3>Manifest Audit</h3>
${renderAuditHtml(audit)}
          </section>
          <section class="content-block">
            <h3>Visual Description</h3>
            <p class="visual">${escapeHtml(slide.visualDescription)}</p>
          </section>
          <section class="content-block">
            <h3>Speaker Notes</h3>
            <p class="notes">${escapeHtml(slide.speakerNotes)}</p>
          </section>
${renderCitationsHtml(slide)}
        </div>
      </article>`;
}

function renderVisibleContentHtml(slide) {
  const parts = [`<p class="primary"><strong>Visible title:</strong> ${escapeHtml(slide.visibleTitle)}</p>`];

  if (slide.eyebrow) {
    parts.push(`<p><strong>Eyebrow:</strong> ${escapeHtml(slide.eyebrow)}</p>`);
  }

  if (slide.visibleBody?.length) {
    parts.push(`<p><strong>Body:</strong></p>${unorderedListHtml(slide.visibleBody)}`);
  }

  if (slide.visibleBullets?.length) {
    parts.push(`<p><strong>Bullets:</strong></p>${orderedListHtml(slide.visibleBullets)}`);
  }

  if (slide.visibleCards?.length) {
    parts.push(`<p><strong>Cards:</strong></p><div class="cards">${slide.visibleCards.map(renderCardHtml).join("")}</div>`);
  }

  if (slide.visibleColumns?.length) {
    parts.push(`<p><strong>Columns:</strong></p><div class="columns">${slide.visibleColumns.map(renderColumnHtml).join("")}</div>`);
  }

  if (slide.visibleTable) {
    parts.push(`<p><strong>Table:</strong></p>${tableHtml(slide.visibleTable)}`);
  }

  if (slide.visibleFormula) {
    parts.push(`<p><strong>Formula:</strong> ${escapeHtml(slide.visibleFormula.expression)}</p>`);
    parts.push(`<p><strong>${escapeHtml(slide.visibleFormula.costTitle)}:</strong></p>${unorderedListHtml(slide.visibleFormula.costLines)}`);
    parts.push(`<p><strong>${escapeHtml(slide.visibleFormula.valueTitle)}:</strong></p>${unorderedListHtml(slide.visibleFormula.valueLines)}`);
  }

  return parts.map((part) => `            ${part}`).join("\n");
}

function renderCardHtml(card) {
  const parts = [`<strong>${escapeHtml(card.title)}</strong>`];
  if (card.value) parts.push(`<p>${escapeHtml(card.value)}</p>`);
  if (card.body) parts.push(`<p>${escapeHtml(card.body)}</p>`);
  if (card.items?.length) parts.push(unorderedListHtml(card.items));
  return `<div class="card">${parts.join("")}</div>`;
}

function renderColumnHtml(column) {
  const parts = [`<strong>${escapeHtml(column.title)}</strong>`];
  if (column.body) parts.push(`<p>${escapeHtml(column.body)}</p>`);
  if (column.items?.length) parts.push(unorderedListHtml(column.items));
  return `<div class="column">${parts.join("")}</div>`;
}

function orderedListHtml(items) {
  return `<ol>${items.map((item) => `<li>${escapeHtml(item)}</li>`).join("")}</ol>`;
}

function unorderedListHtml(items) {
  return `<ul>${items.map((item) => `<li>${escapeHtml(item)}</li>`).join("")}</ul>`;
}

function tableHtml(table) {
  const header = table.columns.map((column) => `<th>${escapeHtml(column)}</th>`).join("");
  const rows = table.rows
    .map((row) => `<tr>${row.map((cell) => `<td>${escapeHtml(cell)}</td>`).join("")}</tr>`)
    .join("");

  return `<table><thead><tr>${header}</tr></thead><tbody>${rows}</tbody></table>`;
}

function renderAuditHtml(audit) {
  if (!audit.warnings.length) {
    return `            <p class="audit-ok">No visible text outside manifest visible fields was detected by the static render contract.</p>`;
  }

  return `            <div class="audit-warning">
              <p>Warning: possible rendered text not present in visible fields.</p>
              ${unorderedListHtml(audit.warnings)}
            </div>`;
}

function auditSlide(slide) {
  const allowed = new Set(flattenVisibleText(slide).map(normalizeAuditText));
  const rendered = flattenRenderContractText(slide).map(normalizeAuditText);
  const warnings = rendered.filter((text) => text && !allowed.has(text));
  return { warnings: Array.from(new Set(warnings)) };
}

function flattenVisibleText(slide) {
  const values = [];
  add(values, slide.visibleTitle);
  add(values, slide.eyebrow);
  add(values, slide.visibleBody);
  add(values, slide.visibleBullets);
  add(values, slide.visibleCards?.flatMap((card) => [card.title, card.value, card.body, card.items].flat()));
  add(values, slide.visibleColumns?.flatMap((column) => [column.title, column.body, column.items].flat()));
  add(values, slide.visibleTable?.columns);
  add(values, slide.visibleTable?.rows.flat());
  add(values, slide.visibleFormula?.expression);
  add(values, slide.visibleFormula?.costTitle);
  add(values, slide.visibleFormula?.costLines);
  add(values, slide.visibleFormula?.valueTitle);
  add(values, slide.visibleFormula?.valueLines);
  add(values, slide.citations?.map((citation) => citation.label));
  return values;
}

function flattenRenderContractText(slide) {
  const values = flattenVisibleText(slide);
  return values;
}

function add(values, candidate) {
  if (!candidate) return;
  if (Array.isArray(candidate)) {
    candidate.forEach((item) => add(values, item));
    return;
  }
  values.push(String(candidate));
}

function normalizeAuditText(value) {
  return value.trim().replace(/\s+/g, " ").toLowerCase();
}

function renderCitationsHtml(slide) {
  if (!slide.citations?.length) {
    return "";
  }

  const citations = slide.citations
    .map(
      (citation) => `              <li>
                <strong>${escapeHtml(citation.label)}:</strong>
                <a href="${escapeAttribute(citation.url)}">${escapeHtml(citation.title)}</a>
                ${citation.note ? `<p class="citation-note">${escapeHtml(citation.note)}</p>` : ""}
              </li>`
    )
    .join("\n");

  return `          <section class="content-block citations">
            <h3>Citations</h3>
            <ul>
${citations}
            </ul>
          </section>`;
}

function renderMarkdown(deckSlides) {
  const deckTitle = `${deckSlides[0].visibleTitle}: ${deckSlides[0].visibleBody?.[0] ?? deckSlides[0].title}`;
  const lines = [
    `# ${deckTitle}`,
    "",
    "Static review export generated from `src/content/tokenomicsSlides.ts`.",
    "",
    `Slide count: ${deckSlides.length}`,
    ""
  ];

  deckSlides.forEach((slide, index) => {
    const audit = auditSlide(slide);
    lines.push(`## ${String(index + 1).padStart(2, "0")}. ${slide.title}`);
    lines.push("");
    lines.push(`- ID: \`${slide.id}\``);
    lines.push(`- Layout: \`${slide.layout}\``);
    lines.push("");
    lines.push("### Visible Slide Content");
    lines.push("");
    lines.push(...visibleContentMarkdown(slide));
    lines.push("");
    lines.push("### Manifest Audit");
    lines.push("");
    if (audit.warnings.length) {
      audit.warnings.forEach((warning) => lines.push(`- Warning: ${warning}`));
    } else {
      lines.push("No visible text outside manifest visible fields was detected by the static render contract.");
    }
    lines.push("");
    lines.push("### Visual Description");
    lines.push("");
    lines.push(slide.visualDescription);
    lines.push("");
    lines.push("### Speaker Notes");
    lines.push("");
    lines.push(slide.speakerNotes);

    if (slide.citations?.length) {
      lines.push("");
      lines.push("### Citations");
      lines.push("");
      slide.citations.forEach((citation) => {
        lines.push(`- ${citation.label}: [${citation.title}](${citation.url})`);
        if (citation.note) {
          lines.push(`  ${citation.note}`);
        }
      });
    }

    lines.push("");
  });

  return `${lines.join("\n").trim()}\n`;
}

function visibleContentMarkdown(slide) {
  const lines = [`- Visible title: ${slide.visibleTitle}`];
  if (slide.eyebrow) lines.push(`- Eyebrow: ${slide.eyebrow}`);
  appendList(lines, "Body", slide.visibleBody);
  appendList(lines, "Bullets", slide.visibleBullets);

  if (slide.visibleCards?.length) {
    lines.push("- Cards:");
    slide.visibleCards.forEach((card) => {
      lines.push(`  - ${card.title}`);
      if (card.value) lines.push(`    - Value: ${card.value}`);
      if (card.body) lines.push(`    - Body: ${card.body}`);
      if (card.items?.length) lines.push(`    - Items: ${joinList(card.items)}`);
    });
  }

  if (slide.visibleColumns?.length) {
    lines.push("- Columns:");
    slide.visibleColumns.forEach((column) => {
      lines.push(`  - ${column.title}`);
      if (column.body) lines.push(`    - Body: ${column.body}`);
      if (column.items?.length) lines.push(`    - Items: ${joinList(column.items)}`);
    });
  }

  if (slide.visibleTable) {
    lines.push("");
    lines.push(...markdownTable(slide.visibleTable));
  }

  if (slide.visibleFormula) {
    lines.push(`- Formula: ${slide.visibleFormula.expression}`);
    appendList(lines, slide.visibleFormula.costTitle, slide.visibleFormula.costLines);
    appendList(lines, slide.visibleFormula.valueTitle, slide.visibleFormula.valueLines);
  }

  return lines;
}

function appendList(lines, label, items) {
  if (!items?.length) return;
  lines.push(`- ${label}:`);
  items.forEach((item) => lines.push(`  - ${item}`));
}

function markdownTable(table) {
  const header = `| ${table.columns.map(escapeMarkdownCell).join(" | ")} |`;
  const separator = `| ${table.columns.map(() => "---").join(" | ")} |`;
  const rows = table.rows.map((row) => `| ${row.map(escapeMarkdownCell).join(" | ")} |`);
  return [header, separator, ...rows];
}

function joinList(items) {
  return items?.filter(Boolean).join(", ") || "none specified";
}

function escapeHtml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

function escapeAttribute(value) {
  return escapeHtml(value).replaceAll("`", "&#96;");
}

function escapeMarkdownCell(value) {
  return String(value).replaceAll("|", "\\|");
}
