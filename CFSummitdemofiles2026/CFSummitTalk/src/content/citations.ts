import type { Citation } from "../types";

export const citations = {
  deloitte: {
    label: "Deloitte",
    title: "2026 State of AI in the Enterprise",
    url: "https://www.deloitte.com/us/en/what-we-do/capabilities/applied-artificial-intelligence/content/state-of-ai-in-the-enterprise.html",
    note: "Supports adoption momentum, including worker access growth and movement from pilot to production."
  },
  ibm: {
    label: "IBM",
    title: "AI ROI",
    url: "https://www.ibm.com/think/insights/ai-roi",
    note: "Supports ROI maturity concerns and the cited gap between investment and expected ROI."
  },
  ibmPress: {
    label: "IBM CEO Study",
    title: "CEOs Double Down on AI While Navigating Enterprise Hurdles",
    url: "https://newsroom.ibm.com/2025-05-06-ibm-study-ceos-double-down-on-ai-while-navigating-enterprise-hurdles",
    note: "Press reference for the 25 percent expected ROI and 16 percent enterprise-wide scaling figures."
  },
  mckinsey: {
    label: "McKinsey",
    title: "The State of AI",
    url: "https://www.mckinsey.com/capabilities/quantumblack/our-insights/the-state-of-ai",
    note: "Supports the distinction between use-case gains and enterprise-level EBIT impact."
  },
  openAiPricing: {
    label: "OpenAI",
    title: "API Pricing",
    url: "https://developers.openai.com/api/docs/pricing",
    note: "Supports pricing surfaces such as input, cached input, output, model tier, processing mode, and tool costs."
  },
  anthropicPricing: {
    label: "Anthropic",
    title: "Claude Pricing",
    url: "https://docs.anthropic.com/en/docs/about-claude/pricing",
    note: "Supports input, output, cache write, cache read, and tool-related pricing surfaces."
  },
  geminiPricing: {
    label: "Gemini",
    title: "Gemini API Pricing",
    url: "https://ai.google.dev/gemini-api/docs/pricing",
    note: "Supports context caching, cache storage, and grounding charge surfaces."
  }
} satisfies Record<string, Citation>;
