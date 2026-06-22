export interface Citation {
  label: string;
  title: string;
  url: string;
  note?: string;
}

export type SlideLayout =
  | "title"
  | "statement"
  | "two-column"
  | "metric-cards"
  | "grouped-cards"
  | "architecture"
  | "matrix"
  | "formula"
  | "closing";

export interface VisibleCard {
  title: string;
  value?: string;
  body?: string;
  items?: string[];
  tone?: "default" | "accent" | "warning" | "quiet";
}

export interface VisibleColumn {
  title: string;
  body?: string;
  items?: string[];
}

export interface VisibleTable {
  columns: string[];
  rows: string[][];
}

export interface VisibleFormula {
  expression: string;
  costTitle: string;
  costLines: string[];
  valueTitle: string;
  valueLines: string[];
}

export interface TalkSlide {
  id: string;
  title: string;
  visibleTitle: string;
  eyebrow?: string;
  layout: SlideLayout;
  visibleBody?: string[];
  visibleBullets?: string[];
  visibleCards?: VisibleCard[];
  visibleColumns?: VisibleColumn[];
  visibleTable?: VisibleTable;
  visibleFormula?: VisibleFormula;
  speakerNotes: string;
  citations?: Citation[];
  visualDescription: string;
}
