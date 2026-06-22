import { useCallback, useEffect, useMemo, useState } from "react";
import { Deck } from "./components/Deck";
import { CitationDrawer } from "./components/CitationDrawer";
import { SpeakerNotes } from "./components/SpeakerNotes";
import { Overview } from "./components/Overview";
import { slides, slideById } from "./content/tokenomicsSlides";
import type { Citation } from "./types";

function indexFromHash() {
  const raw = window.location.hash.replace(/^#\/?/, "");
  if (!raw) return 0;
  return slideById.get(raw)?.index ?? 0;
}

function writeHash(index: number) {
  const id = slides[index]?.id ?? slides[0].id;
  if (window.location.hash !== `#/${id}`) {
    window.history.replaceState(null, "", `#/${id}`);
  }
}

export default function App() {
  const [index, setIndex] = useState(indexFromHash);
  const [notesOpen, setNotesOpen] = useState(false);
  const [referencesOpen, setReferencesOpen] = useState(false);
  const [overviewOpen, setOverviewOpen] = useState(false);

  const slide = slides[index];
  const allCitations = useMemo(() => {
    const seen = new Map<string, Citation>();
    slides.forEach((item) => {
      item.citations?.forEach((citation) => {
        seen.set(citation.url, citation);
      });
    });
    return Array.from(seen.values());
  }, []);

  const goTo = useCallback((nextIndex: number) => {
    const clamped = Math.max(0, Math.min(slides.length - 1, nextIndex));
    setIndex(clamped);
    writeHash(clamped);
  }, []);

  const closePanels = useCallback(() => {
    setNotesOpen(false);
    setReferencesOpen(false);
    setOverviewOpen(false);
  }, []);

  useEffect(() => {
    writeHash(index);
  }, [index]);

  useEffect(() => {
    const onHashChange = () => {
      setIndex(indexFromHash());
      closePanels();
    };
    window.addEventListener("hashchange", onHashChange);
    return () => window.removeEventListener("hashchange", onHashChange);
  }, [closePanels]);

  useEffect(() => {
    const onKeyDown = (event: KeyboardEvent) => {
      const target = event.target as HTMLElement | null;
      if (target && ["INPUT", "TEXTAREA", "SELECT"].includes(target.tagName)) return;

      if (event.key === "Escape") {
        closePanels();
        return;
      }
      if (event.key === "ArrowRight" || event.key === " ") {
        event.preventDefault();
        closePanels();
        goTo(index + 1);
      }
      if (event.key === "ArrowLeft") {
        event.preventDefault();
        closePanels();
        goTo(index - 1);
      }
      if (event.key === "Home") {
        event.preventDefault();
        closePanels();
        goTo(0);
      }
      if (event.key === "End") {
        event.preventDefault();
        closePanels();
        goTo(slides.length - 1);
      }
      if (event.key.toLowerCase() === "n") {
        event.preventDefault();
        setNotesOpen((value) => !value);
        setReferencesOpen(false);
        setOverviewOpen(false);
      }
      if (event.key.toLowerCase() === "r") {
        event.preventDefault();
        setReferencesOpen((value) => !value);
        setNotesOpen(false);
        setOverviewOpen(false);
      }
      if (event.key.toLowerCase() === "o") {
        event.preventDefault();
        setOverviewOpen((value) => !value);
        setNotesOpen(false);
        setReferencesOpen(false);
      }
    };

    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, [closePanels, goTo, index]);

  return (
    <main className="app-shell">
      <Deck
        slide={slide}
        slideIndex={index}
        slideCount={slides.length}
        onNext={() => goTo(index + 1)}
        onPrevious={() => goTo(index - 1)}
        onToggleNotes={() => {
          setNotesOpen((value) => !value);
          setReferencesOpen(false);
          setOverviewOpen(false);
        }}
        onToggleReferences={() => {
          setReferencesOpen((value) => !value);
          setNotesOpen(false);
          setOverviewOpen(false);
        }}
        onToggleOverview={() => {
          setOverviewOpen((value) => !value);
          setNotesOpen(false);
          setReferencesOpen(false);
        }}
      />
      <SpeakerNotes slide={slide} open={notesOpen} onClose={() => setNotesOpen(false)} />
      <CitationDrawer
        open={referencesOpen}
        citations={allCitations}
        slideCitations={slide.citations ?? []}
        onClose={() => setReferencesOpen(false)}
      />
      <Overview
        open={overviewOpen}
        slides={slides}
        currentIndex={index}
        onSelect={(nextIndex) => {
          goTo(nextIndex);
          setOverviewOpen(false);
        }}
        onClose={() => setOverviewOpen(false)}
      />
    </main>
  );
}
