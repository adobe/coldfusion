import type { TalkSlide } from "../types";
import { ProgressBar } from "./ProgressBar";
import { Slide } from "./Slide";

interface DeckProps {
  slide: TalkSlide;
  slideIndex: number;
  slideCount: number;
  onNext: () => void;
  onPrevious: () => void;
  onToggleNotes: () => void;
  onToggleReferences: () => void;
  onToggleOverview: () => void;
}

export function Deck({
  slide,
  slideIndex,
  slideCount,
  onNext,
  onPrevious,
  onToggleNotes,
  onToggleReferences,
  onToggleOverview
}: DeckProps) {
  return (
    <section className="deck" aria-label="Tokenomics presentation">
      <div className="deck-stage">
        <Slide slide={slide} slideIndex={slideIndex} slideCount={slideCount} />
      </div>
      <ProgressBar current={slideIndex + 1} total={slideCount} />
      <div className="deck-controls" aria-label="Deck controls">
        <button className="icon-button wide" type="button" onClick={onPrevious} aria-label="Previous slide" title="Previous slide">
          Prev
        </button>
        <button className="icon-button wide" type="button" onClick={onNext} aria-label="Next slide" title="Next slide">
          Next
        </button>
        <button className="icon-button" type="button" onClick={onToggleOverview} aria-label="Open overview" title="Overview">
          O
        </button>
        <button className="icon-button" type="button" onClick={onToggleNotes} aria-label="Open speaker notes" title="Speaker notes">
          N
        </button>
        <button className="icon-button" type="button" onClick={onToggleReferences} aria-label="Open references" title="References">
          R
        </button>
      </div>
    </section>
  );
}
