import type { TalkSlide } from "../types";

interface SpeakerNotesProps {
  slide: TalkSlide;
  open: boolean;
  onClose: () => void;
}

export function SpeakerNotes({ slide, open, onClose }: SpeakerNotesProps) {
  if (!open) return null;

  return (
    <aside className="side-panel notes-panel" aria-label="Speaker notes">
      <div className="panel-heading">
        <div>
          <p className="panel-kicker">Speaker notes</p>
          <h2>{slide.visibleTitle}</h2>
        </div>
        <button className="icon-button" type="button" onClick={onClose} aria-label="Close speaker notes" title="Close">
          X
        </button>
      </div>
      <p>{slide.speakerNotes}</p>
    </aside>
  );
}
