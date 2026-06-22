import type { CSSProperties } from "react";
import type { TalkSlide, VisibleCard, VisibleColumn, VisibleTable } from "../types";

interface SlideProps {
  slide: TalkSlide;
  slideIndex: number;
  slideCount: number;
}

export function Slide({ slide, slideIndex, slideCount }: SlideProps) {
  return (
    <article className={`slide slide-${slide.layout}`} aria-labelledby={`slide-title-${slide.id}`}>
      <SlideSurface />
      {slide.layout === "title" ? (
        <TitleSlide slide={slide} />
      ) : slide.layout === "closing" ? (
        <ClosingSlide slide={slide} />
      ) : (
        <>
          <SlideHeader slide={slide} slideIndex={slideIndex} slideCount={slideCount} />
          <div className="slide-body">{renderSlideBody(slide)}</div>
          <SlideCitations slide={slide} />
        </>
      )}
    </article>
  );
}

function SlideSurface() {
  return (
    <div className="slide-surface" aria-hidden="true">
      <span />
      <span />
      <span />
    </div>
  );
}

function SlideHeader({ slide, slideIndex, slideCount }: SlideProps) {
  return (
    <header className="slide-header">
      <div>
        <p className="slide-number">
          {String(slideIndex + 1).padStart(2, "0")} / {String(slideCount).padStart(2, "0")}
        </p>
      </div>
      <h1 id={`slide-title-${slide.id}`}>{slide.visibleTitle}</h1>
    </header>
  );
}

function SlideCitations({ slide }: { slide: TalkSlide }) {
  if (!slide.citations?.length) return <div className="slide-citations" />;

  return (
    <div className="slide-citations" aria-label="Slide citations">
      {slide.citations.map((citation) => (
        <span key={citation.url} title={citation.title}>
          {citation.label}
        </span>
      ))}
    </div>
  );
}

function TitleSlide({ slide }: { slide: TalkSlide }) {
  return (
    <div className="title-slide">
      <p className="eyebrow">{slide.eyebrow}</p>
      <h1 id={`slide-title-${slide.id}`}>{slide.visibleTitle}</h1>
      <div className="title-lines">
        {slide.visibleBody?.map((line) => (
          <p key={line}>{line}</p>
        ))}
      </div>
    </div>
  );
}

function ClosingSlide({ slide }: { slide: TalkSlide }) {
  return (
    <div className="closing-slide">
      <h1 id={`slide-title-${slide.id}`}>{slide.visibleTitle}</h1>
      {slide.visibleBody?.map((line, index) =>
        index === slide.visibleBody!.length - 1 ? <strong key={line}>{line}</strong> : <p key={line}>{line}</p>
      )}
    </div>
  );
}

function renderSlideBody(slide: TalkSlide) {
  switch (slide.layout) {
    case "statement":
      return (
        <div className="statement-layout">
          <BodyLines slide={slide} />
          <BulletTrace bullets={slide.visibleBullets ?? []} />
        </div>
      );
    case "metric-cards":
      return (
        <div className="stacked-layout">
          <BodyLines slide={slide} />
          <CardGrid cards={slide.visibleCards ?? []} metric />
        </div>
      );
    case "two-column":
      return (
        <div className="stacked-layout">
          <BodyLines slide={slide} />
          <ColumnGrid columns={slide.visibleColumns ?? []} />
        </div>
      );
    case "grouped-cards":
      return (
        <div className="stacked-layout">
          <BodyLines slide={slide} />
          <CardGrid cards={slide.visibleCards ?? []} />
        </div>
      );
    case "architecture":
      return (
        <div className="stacked-layout">
          <BodyLines slide={slide} />
          <ArchitectureCards cards={slide.visibleCards ?? []} />
        </div>
      );
    case "matrix":
      return (
        <div className="stacked-layout">
          <BodyLines slide={slide} />
          <MatrixTable table={slide.visibleTable} />
        </div>
      );
    case "formula":
      return (
        <div className="stacked-layout">
          <BodyLines slide={slide} />
          <FormulaBlock slide={slide} />
        </div>
      );
    case "title":
    case "closing":
      return null;
  }
}

function BodyLines({ slide }: { slide: TalkSlide }) {
  if (!slide.visibleBody?.length) return null;

  return (
    <div className="body-lines">
      {slide.visibleBody.map((line, index) => (
        <p className={index === 0 ? "main-statement" : "support-copy"} key={line}>
          {line}
        </p>
      ))}
    </div>
  );
}

function BulletTrace({ bullets }: { bullets: string[] }) {
  if (!bullets.length) return null;

  return (
    <ol className="bullet-trace">
      {bullets.map((bullet, index) => (
        <li key={bullet} style={{ "--delay": `${index * 45}ms` } as CSSProperties}>
          <span>{String(index + 1).padStart(2, "0")}</span>
          <p>{bullet}</p>
        </li>
      ))}
    </ol>
  );
}

function CardGrid({ cards, metric = false }: { cards: VisibleCard[]; metric?: boolean }) {
  if (!cards.length) return null;

  return (
    <div className={metric ? "card-grid metric-grid" : "card-grid"}>
      {cards.map((card, index) => (
        <section className={`content-card ${card.tone ?? "default"}`} key={card.title} style={{ "--delay": `${index * 70}ms` } as CSSProperties}>
          <h2>{card.title}</h2>
          {card.value && <strong>{card.value}</strong>}
          {card.body && <p>{card.body}</p>}
          {card.items?.length ? (
            <ul>
              {card.items.map((item) => (
                <li key={item}>{item}</li>
              ))}
            </ul>
          ) : null}
        </section>
      ))}
    </div>
  );
}

function ColumnGrid({ columns }: { columns: VisibleColumn[] }) {
  if (!columns.length) return null;

  return (
    <div className="column-grid">
      {columns.map((column, index) => (
        <section className="content-column" key={column.title} style={{ "--delay": `${index * 80}ms` } as CSSProperties}>
          <h2>{column.title}</h2>
          {column.body && <p>{column.body}</p>}
          {column.items?.length ? (
            <ul>
              {column.items.map((item) => (
                <li key={item}>{item}</li>
              ))}
            </ul>
          ) : null}
        </section>
      ))}
    </div>
  );
}

function ArchitectureCards({ cards }: { cards: VisibleCard[] }) {
  if (!cards.length) return null;

  return (
    <div className="architecture-flow">
      {cards.map((card, index) => (
        <section className={`arch-card ${card.tone ?? "default"}`} key={card.title} style={{ "--delay": `${index * 70}ms` } as CSSProperties}>
          <h2>{card.title}</h2>
          {card.items?.length ? (
            <ul>
              {card.items.map((item) => (
                <li key={item}>{item}</li>
              ))}
            </ul>
          ) : null}
        </section>
      ))}
    </div>
  );
}

function MatrixTable({ table }: { table?: VisibleTable }) {
  if (!table) return null;

  return (
    <div className="matrix-table">
      <table>
        <thead>
          <tr>
            {table.columns.map((column) => (
              <th key={column}>{column}</th>
            ))}
          </tr>
        </thead>
        <tbody>
          {table.rows.map((row, index) => (
            <tr key={row.join("-")} style={{ "--delay": `${index * 45}ms` } as CSSProperties}>
              {row.map((cell) => (
                <td key={cell}>{cell}</td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

function FormulaBlock({ slide }: { slide: TalkSlide }) {
  const formula = slide.visibleFormula;
  if (!formula) return null;

  return (
    <div className="formula-layout">
      <div className="formula-expression">{formula.expression}</div>
      <div className="formula-panels">
        <section>
          <h2>{formula.costTitle}</h2>
          <ul>
            {formula.costLines.map((item) => (
              <li key={item}>{item}</li>
            ))}
          </ul>
        </section>
        <section>
          <h2>{formula.valueTitle}</h2>
          <ul>
            {formula.valueLines.map((item) => (
              <li key={item}>{item}</li>
            ))}
          </ul>
        </section>
      </div>
    </div>
  );
}
