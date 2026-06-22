interface ProgressBarProps {
  current: number;
  total: number;
}

export function ProgressBar({ current, total }: ProgressBarProps) {
  const percent = (current / total) * 100;

  return (
    <footer className="progress-shell" aria-label={`Slide ${current} of ${total}`}>
      <div className="progress-track">
        <div className="progress-fill" style={{ width: `${percent}%` }} />
      </div>
      <span className="progress-count">
        {String(current).padStart(2, "0")} / {String(total).padStart(2, "0")}
      </span>
    </footer>
  );
}
