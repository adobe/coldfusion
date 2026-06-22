import type { TalkSlide } from "../types";

interface OverviewProps {
  open: boolean;
  slides: TalkSlide[];
  currentIndex: number;
  onSelect: (index: number) => void;
  onClose: () => void;
}

export function Overview({ open, slides, currentIndex, onSelect, onClose }: OverviewProps) {
  if (!open) return null;

  return (
    <section className="overview-panel" aria-label="Slide overview">
      <div className="panel-heading">
        <div>
          <p className="panel-kicker">Overview</p>
          <h2>Tokenomics</h2>
        </div>
        <button className="icon-button" type="button" onClick={onClose} aria-label="Close overview" title="Close">
          X
        </button>
      </div>
      <div className="overview-grid">
        {slides.map((slide, index) => (
          <button
            className={index === currentIndex ? "overview-card current" : "overview-card"}
            key={slide.id}
            type="button"
            onClick={() => onSelect(index)}
          >
            <span>{String(index + 1).padStart(2, "0")}</span>
            <strong>{slide.title}</strong>
          </button>
        ))}
      </div>
    </section>
  );
}
