import type { Citation } from "../types";

interface CitationDrawerProps {
  open: boolean;
  citations: Citation[];
  slideCitations: Citation[];
  onClose: () => void;
}

export function CitationDrawer({ open, citations, slideCitations, onClose }: CitationDrawerProps) {
  if (!open) return null;

  const slideUrls = new Set(slideCitations.map((citation) => citation.url));

  return (
    <aside className="side-panel references-panel" aria-label="References">
      <div className="panel-heading">
        <div>
          <p className="panel-kicker">References</p>
          <h2>Sources used in this deck</h2>
        </div>
        <button className="icon-button" type="button" onClick={onClose} aria-label="Close references" title="Close">
          X
        </button>
      </div>
      <div className="reference-list">
        {citations.map((citation) => (
          <article className={slideUrls.has(citation.url) ? "reference-item active" : "reference-item"} key={citation.url}>
            <div className="reference-label">{citation.label}</div>
            <h3>{citation.title}</h3>
            <p>{citation.note}</p>
            <a href={citation.url} target="_blank" rel="noreferrer">
              Open source
            </a>
          </article>
        ))}
      </div>
    </aside>
  );
}
