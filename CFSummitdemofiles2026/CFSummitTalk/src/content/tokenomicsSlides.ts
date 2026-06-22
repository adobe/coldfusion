import type { TalkSlide } from "../types";
import { citations } from "./citations";

export const slides: TalkSlide[] = [
  {
    id: "title",
    title: "Tokenomics",
    visibleTitle: "Tokenomics",
    eyebrow: "ColdFusion Summit 2026",
    layout: "title",
    visibleBody: ["ROI and Metrics for Your AI Workflows", "Measuring what AI workflows cost and what they return."],
    visualDescription:
      "Clean title slide with subtle ledger-row texture and a thin abstract cost trace. No diagram labels or extra visible words.",
    speakerNotes:
      "Set the expectation that this is about moving from impressive AI features to measurable AI operations. The point is practical operating discipline for ColdFusion teams building real applications."
  },
  {
    id: "prototype-was-cheap",
    title: "The prototype was cheap",
    visibleTitle: "The prototype was cheap",
    layout: "grouped-cards",
    visibleBody: ["The demo worked.", "The bill looked harmless.", "That was not the whole story."],
    visibleCards: [
      {
        title: "Prototype",
        body: "one prompt, one answer, one happy path",
        tone: "accent"
      },
      {
        title: "Production",
        body: "context, tools, retries, review, logging",
        tone: "warning"
      }
    ],
    visualDescription:
      "Simple two-card contrast between prototype and production, with no dashboard chrome or extra planning labels.",
    speakerNotes:
      "Explain that the prototype proves possibility, not economics. A cheap prototype can be useful and still hide production costs that only appear when the workflow becomes real."
  },
  {
    id: "production-changed-the-math",
    title: "Production changed the math",
    visibleTitle: "Production changed the math",
    layout: "statement",
    visibleBody: ["Production adds the parts the demo skipped."],
    visibleBullets: [
      "Longer prompts",
      "More context",
      "RAG",
      "Tool calls",
      "Retries",
      "Human review",
      "Audit logging",
      "Support burden"
    ],
    visualDescription:
      "Clean vertical build-up of production cost layers, revealed as restrained stacked bands.",
    speakerNotes:
      "This is where workflow cost starts to separate from the API-call mental model. Production adds reliability, context, routing, auditability, support, and review."
  },
  {
    id: "why-this-matters-now",
    title: "Why this matters now",
    visibleTitle: "Why this matters now",
    layout: "metric-cards",
    visibleBody: ["AI adoption is moving faster than AI measurement."],
    visibleCards: [
      { title: "worker access growth", value: "50%", tone: "accent" },
      { title: "expected ROI delivery", value: "25%", tone: "warning" },
      { title: "enterprise-level EBIT impact", value: "39%" }
    ],
    citations: [citations.deloitte, citations.ibm, citations.mckinsey],
    visualDescription:
      "Three clean metric cards with small source tags; no dashboard frame or extra controls.",
    speakerNotes:
      "Ground the talk in current enterprise reality. Adoption is real. Measurement is lagging. Deloitte supports the worker access and adoption momentum point. IBM supports the expected ROI point. McKinsey supports the enterprise-level EBIT impact point."
  },
  {
    id: "what-tokenomics-means",
    title: "What tokenomics means",
    visibleTitle: "What tokenomics means",
    layout: "two-column",
    visibleBody: [
      "Tokenomics is the discipline of measuring what AI workflows consume, what they change, and whether the result is worth scaling.",
      "Tokens are the billing unit. Workflows are the business unit."
    ],
    visibleColumns: [
      { title: "Token view", items: ["input", "output", "model", "requests"] },
      { title: "Workflow view", items: ["context", "tools", "retries", "review", "outcomes"] }
    ],
    visualDescription:
      "Restrained two-column comparison between token accounting and workflow economics.",
    speakerNotes:
      "Keep this as the core definition. Do not make it sound academic. The useful shift is from provider billing units to the actual business workflow."
  },
  {
    id: "token-price-is-not-workflow-cost",
    title: "Token price is not workflow cost",
    visibleTitle: "Token price is not workflow cost",
    layout: "two-column",
    visibleBody: [
      "The invoice tells you what the provider charged. It does not tell you whether the workflow was worth running."
    ],
    visibleColumns: [
      {
        title: "Provider invoice",
        items: ["model usage", "token usage", "tool charges, if applicable"]
      },
      {
        title: "Workflow cost",
        items: ["retrieval", "validation", "review", "rework", "outcome"]
      }
    ],
    visualDescription:
      "Simple side-by-side comparison between provider invoice surfaces and broader workflow cost surfaces.",
    speakerNotes:
      "Provider cost is real, but incomplete. A production workflow can include retrieval, tool calls, validation, review, rework, and business outcomes that never appear on the provider invoice."
  },
  {
    id: "real-cost-stack",
    title: "The real cost stack",
    visibleTitle: "The real cost stack",
    layout: "grouped-cards",
    visibleBody: ["Cost hides in layers."],
    visibleCards: [
      {
        title: "Provider",
        items: ["model tokens", "cached tokens", "tool charges"],
        tone: "accent"
      },
      {
        title: "Application",
        items: ["retrieval", "storage", "orchestration", "infrastructure"]
      },
      {
        title: "Business",
        items: ["review", "rework", "latency", "compliance"],
        tone: "warning"
      }
    ],
    visualDescription:
      "Three-zone cost grouping instead of another dense stack: provider, application, and business.",
    speakerNotes:
      "Use this slide to challenge simplistic per-prompt math. The visible model call is often just the most obvious line item. The durable habit is grouping costs by where they are created and who can influence them."
  },
  {
    id: "model-sizing-is-architecture",
    title: "Model sizing is architecture",
    visibleTitle: "Model sizing is architecture",
    layout: "statement",
    visibleBody: ["The strongest model is sometimes right. It should not be the unmanaged default."],
    visibleBullets: [
      "Can normal code solve it?",
      "Can code handle most of it?",
      "Can a smaller model handle the language portion?",
      "Can a mid-tier model handle it with validation?",
      "Does it need a frontier model?",
      "Does the value justify that choice?"
    ],
    visualDescription:
      "Clean decision path for model sizing, shown as a serious operating sequence rather than a toy ladder.",
    speakerNotes:
      "This is not a cheapness argument. It is an architectural control argument. The model is part of the design, not just a setting."
  },
  {
    id: "model-strategy-examples",
    title: "Model strategy examples",
    visibleTitle: "Model strategy examples",
    layout: "grouped-cards",
    visibleBody: ["Match model capability to workflow risk."],
    visibleCards: [
      {
        title: "Routine language work",
        body: "categorization, summarization"
      },
      {
        title: "Structured business work",
        body: "extraction, validation, workflow assistance",
        tone: "accent"
      },
      {
        title: "High-risk work",
        body: "code review, policy/compliance, customer-facing recommendations",
        tone: "warning"
      }
    ],
    visualDescription:
      "Three grouped example cards organized by workflow risk instead of a six-row table.",
    speakerNotes:
      "Detailed examples: categorize support tickets with a smaller model plus validation and escalation; summarize internal notes with a small or mid-tier model; extract document fields with schema validation; use mid-tier or stronger models with guardrails for customer-facing recommendations; use stronger models with retrieval for complex code review; pair policy or compliance analysis with human review. Tie this to ColdFusion apps: forms, reports, support tools, admin workflows, dashboards, intranet systems, and integration-heavy business apps."
  },
  {
    id: "context-cost-grows",
    title: "Context is where cost quietly grows",
    visibleTitle: "Context is where cost quietly grows",
    layout: "statement",
    visibleBody: ['"Just send everything" is not an architecture.'],
    visibleBullets: [
      "system instructions",
      "user prompt",
      "chat history",
      "retrieved documents",
      "examples",
      "tool outputs",
      "formatting rules",
      "policy instructions"
    ],
    visualDescription:
      "Context shown as an input budget with restrained stacked token bands, not a marketing funnel.",
    speakerNotes:
      "Long context is useful, but it is a cost surface. It can also introduce noise. The goal is selected context, not maximum context."
  },
  {
    id: "context-discipline",
    title: "Context discipline",
    visibleTitle: "Context discipline",
    layout: "statement",
    visibleBody: ["Send the smallest sufficient context for the task."],
    visibleBullets: [
      "Keep stable instructions stable.",
      "Retrieve fewer, better documents.",
      "Summarize long history.",
      "Trim tool output before sending it back."
    ],
    citations: [citations.openAiPricing, citations.anthropicPricing, citations.geminiPricing],
    visualDescription:
      "Four principle rows with quiet emphasis; no dense seven-item checklist.",
    speakerNotes:
      "Also version prompts, track retrieved token count separately, and measure context size by workflow. Mention that OpenAI, Anthropic, and Google expose different pricing and caching surfaces. The vendor details differ. The architecture lesson is consistent."
  },
  {
    id: "tool-calls-are-transactions",
    title: "Tool calls turn prompts into transactions",
    visibleTitle: "Tool calls turn prompts into transactions",
    layout: "statement",
    visibleBody: ["The user made one request.", "The application executed a transaction."],
    visibleBullets: ["classify", "retrieve", "query database", "call API", "validate", "retry", "answer", "review"],
    visualDescription:
      "A single clean transaction trace showing how one request expands into operational steps.",
    speakerNotes:
      "This is where agentic workflows, MCP, database calls, and external APIs change the cost model. One user request can become a transaction across several systems."
  },
  {
    id: "coldfusion-implementation-pattern",
    title: "ColdFusion implementation pattern",
    visibleTitle: "ColdFusion implementation pattern",
    layout: "architecture",
    visibleBody: ["Put a measurable layer around AI usage."],
    visibleCards: [
      { title: "ColdFusion Application" },
      {
        title: "AI Service Wrapper / CFC",
        items: ["Provider Call", "Token Tracking", "Tool Tracking", "Retry Tracking", "Cost Estimate", "Outcome Logging"],
        tone: "accent"
      },
      { title: "Metrics Store" },
      { title: "Dashboard / Reports", tone: "warning" }
    ],
    visualDescription:
      "One clean architecture diagram with the AI Service Wrapper / CFC emphasized as the central measurable layer.",
    speakerNotes:
      "The point is not to scatter AI calls across controllers, CFCs, scheduled tasks, and UI handlers. Centralize the measurable behavior in a wrapper or service layer. The wrapper should capture provider, model, prompt version, token counts, tool calls, retries, cost estimates, status, review, and outcome hooks."
  },
  {
    id: "ai-usage-ledger",
    title: "Build an AI Usage Ledger",
    visibleTitle: "Build an AI Usage Ledger",
    layout: "grouped-cards",
    visibleBody: ["Every production AI workflow should create a structured usage record."],
    visibleCards: [
      {
        title: "Identity",
        items: ["application", "workflow", "provider", "model", "prompt version"]
      },
      {
        title: "Usage",
        items: ["input tokens", "output tokens", "cached tokens", "retrieved tokens"],
        tone: "accent"
      },
      {
        title: "Transaction",
        items: ["tool calls", "retries", "validation failures", "latency"]
      },
      {
        title: "Outcome",
        items: ["status", "review required", "estimated cost"],
        tone: "warning"
      }
    ],
    visualDescription:
      "Four grouped ledger field cards instead of a dense table.",
    speakerNotes:
      "This is the practical center of the talk. Make it feel buildable. The first ledger does not have to be perfect, but every workflow needs a structured record. Additional useful fields include retrieved document IDs, response status, error category, user or team, environment, and release version."
  },
  {
    id: "usage-ledger-answers",
    title: "What the usage ledger answers",
    visibleTitle: "What the usage ledger answers",
    layout: "statement",
    visibleBody: ["Cost visibility becomes workflow visibility."],
    visibleBullets: [
      "Which workflows spend the most?",
      "Where is context growing?",
      "Which tools multiply cost?",
      "What does a successful outcome cost?"
    ],
    visualDescription:
      "Four large question rows with generous spacing, emphasizing operational visibility.",
    speakerNotes:
      "The goal is not a perfect finance system on day one. The goal is to stop flying blind and make workflow questions answerable. Additional questions include which models are overused, where retries are hiding, and which workflows require review."
  },
  {
    id: "usage-is-not-roi",
    title: "Usage is not ROI",
    visibleTitle: "Usage is not ROI",
    layout: "grouped-cards",
    visibleBody: ["80,000 AI calls is activity. It is not value."],
    visibleCards: [
      {
        title: "Activity metric",
        value: "80,000 AI calls",
        tone: "warning"
      },
      {
        title: "Operating metric",
        body: "Example data: review time fell from 18 minutes to 7 minutes, with a 4% escalation rate, at $0.14 per completed review.",
        tone: "accent"
      }
    ],
    visualDescription:
      "Clean contrast between an activity metric and an operating metric, with the operating metric marked as example data.",
    speakerNotes:
      "This is the second major turn. Consumption metrics matter, but they are only half of the story. Usage needs to connect to a measurable operational result. The numbers shown here are illustrative until replaced with real measured data."
  },
  {
    id: "outcome-ledger",
    title: "Build an Outcome Ledger",
    visibleTitle: "Build an Outcome Ledger",
    layout: "grouped-cards",
    visibleBody: ["Pair usage metrics with business outcomes."],
    visibleCards: [
      { title: "Time", body: "minutes avoided per task" },
      { title: "Throughput", body: "more tickets, cases, documents, reviews", tone: "accent" },
      { title: "Quality", body: "fewer errors, escalations, rework" },
      { title: "Business", body: "revenue impact, risk reduction, customer experience", tone: "warning" }
    ],
    visualDescription:
      "Four outcome groups instead of a seven-row table.",
    speakerNotes:
      "People liking a tool is feedback. A measured improvement at an acceptable quality threshold is an operating metric. Additional outcome categories include productivity, audit coverage, faster response, better conversion, renewal support, and fewer missed issues."
  },
  {
    id: "useful-roi-formula",
    title: "A useful ROI formula",
    visibleTitle: "A useful ROI formula",
    layout: "formula",
    visibleBody: ["Use simple math before complex dashboards."],
    visibleFormula: {
      expression: "AI Workflow ROI = (Value Created - Total Workflow Cost) / Total Workflow Cost",
      costTitle: "Total workflow cost",
      costLines: ["model", "tools", "retrieval", "infrastructure", "review", "rework"],
      valueTitle: "Value created",
      valueLines: ["time", "throughput", "quality", "revenue", "risk reduction"]
    },
    visualDescription:
      "Dominant formula block with two small supporting panels for cost and value lines.",
    speakerNotes:
      "The first version will be imperfect. That is acceptable. The goal is disciplined visibility, not theatrical precision."
  },
  {
    id: "failure-modes",
    title: "Enterprise and SMB failure modes",
    visibleTitle: "Enterprise and SMB failure modes",
    layout: "two-column",
    visibleBody: ["Same discipline. Different ways to get hurt."],
    visibleColumns: [
      {
        title: "Enterprise",
        items: ["invisible spend at scale", "disconnected tools", "pilots that never scale"]
      },
      {
        title: "SMB",
        items: ["spend with no margin benefit", "overbuying sophistication", "useful tools that are never evaluated"]
      }
    ],
    visualDescription:
      "Two-column contrast with three visible failure modes per column.",
    speakerNotes:
      "Do not make this a long enterprise-versus-SMB lecture. Use it to show that tokenomics matters at both scales. Additional failure modes include governance after adoption, unclear ownership, owner intuition replacing measurement, and no measurement at all."
  },
  {
    id: "scale-optimize-stop",
    title: "Scale, optimize, or stop",
    visibleTitle: "Scale, optimize, or stop",
    layout: "matrix",
    visibleBody: ["Every AI workflow needs an operating decision."],
    visibleTable: {
      columns: ["Cost", "Value", "Decision"],
      rows: [
        ["low", "high", "scale"],
        ["high", "high", "optimize"],
        ["low", "low", "tolerate, redesign, or defer"],
        ["high", "low", "stop"],
        ["unclear", "unclear", "instrument before expanding"]
      ]
    },
    visualDescription:
      "Clean decision matrix connecting cost, value, and operating decision.",
    speakerNotes:
      "This gives business and technical teams a shared decision model. The unknown state is not a reason to expand. It is a reason to instrument."
  },
  {
    id: "closing",
    title: "Closing",
    visibleTitle: "The question is not just whether the AI worked.",
    layout: "closing",
    visibleBody: ["The question is whether the workflow was worth running.", "That is tokenomics."],
    visualDescription:
      "Minimal final slide with the same subtle ledger-row texture and cost trace as the title slide.",
    speakerNotes:
      "Close soberly. AI is becoming normal application architecture. It needs observability, accountability, cost controls, and measurable outcomes."
  }
];

export const slideById = new Map(slides.map((slide, index) => [slide.id, { slide, index }]));
