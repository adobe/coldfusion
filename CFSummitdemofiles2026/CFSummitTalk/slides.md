# Tokenomics: ROI and Metrics for Your AI Workflows

Static review export generated from `src/content/tokenomicsSlides.ts`.

Slide count: 21

## 01. Tokenomics

- ID: `title`
- Layout: `title`

### Visible Slide Content

- Visible title: Tokenomics
- Eyebrow: ColdFusion Summit 2026
- Body:
  - ROI and Metrics for Your AI Workflows
  - Measuring what AI workflows cost and what they return.

### Manifest Audit

No visible text outside manifest visible fields was detected by the static render contract.

### Visual Description

Clean title slide with subtle ledger-row texture and a thin abstract cost trace. No diagram labels or extra visible words.

### Speaker Notes

Set the expectation that this is about moving from impressive AI features to measurable AI operations. The point is practical operating discipline for ColdFusion teams building real applications.

## 02. The prototype was cheap

- ID: `prototype-was-cheap`
- Layout: `grouped-cards`

### Visible Slide Content

- Visible title: The prototype was cheap
- Body:
  - The demo worked.
  - The bill looked harmless.
  - That was not the whole story.
- Cards:
  - Prototype
    - Body: one prompt, one answer, one happy path
  - Production
    - Body: context, tools, retries, review, logging

### Manifest Audit

No visible text outside manifest visible fields was detected by the static render contract.

### Visual Description

Simple two-card contrast between prototype and production, with no dashboard chrome or extra planning labels.

### Speaker Notes

Explain that the prototype proves possibility, not economics. A cheap prototype can be useful and still hide production costs that only appear when the workflow becomes real.

## 03. Production changed the math

- ID: `production-changed-the-math`
- Layout: `statement`

### Visible Slide Content

- Visible title: Production changed the math
- Body:
  - Production adds the parts the demo skipped.
- Bullets:
  - Longer prompts
  - More context
  - RAG
  - Tool calls
  - Retries
  - Human review
  - Audit logging
  - Support burden

### Manifest Audit

No visible text outside manifest visible fields was detected by the static render contract.

### Visual Description

Clean vertical build-up of production cost layers, revealed as restrained stacked bands.

### Speaker Notes

This is where workflow cost starts to separate from the API-call mental model. Production adds reliability, context, routing, auditability, support, and review.

## 04. Why this matters now

- ID: `why-this-matters-now`
- Layout: `metric-cards`

### Visible Slide Content

- Visible title: Why this matters now
- Body:
  - AI adoption is moving faster than AI measurement.
- Cards:
  - worker access growth
    - Value: 50%
  - expected ROI delivery
    - Value: 25%
  - enterprise-level EBIT impact
    - Value: 39%

### Manifest Audit

No visible text outside manifest visible fields was detected by the static render contract.

### Visual Description

Three clean metric cards with small source tags; no dashboard frame or extra controls.

### Speaker Notes

Ground the talk in current enterprise reality. Adoption is real. Measurement is lagging. Deloitte supports the worker access and adoption momentum point. IBM supports the expected ROI point. McKinsey supports the enterprise-level EBIT impact point.

### Citations

- Deloitte: [2026 State of AI in the Enterprise](https://www.deloitte.com/us/en/what-we-do/capabilities/applied-artificial-intelligence/content/state-of-ai-in-the-enterprise.html)
  Supports adoption momentum, including worker access growth and movement from pilot to production.
- IBM: [AI ROI](https://www.ibm.com/think/insights/ai-roi)
  Supports ROI maturity concerns and the cited gap between investment and expected ROI.
- McKinsey: [The State of AI](https://www.mckinsey.com/capabilities/quantumblack/our-insights/the-state-of-ai)
  Supports the distinction between use-case gains and enterprise-level EBIT impact.

## 05. What tokenomics means

- ID: `what-tokenomics-means`
- Layout: `two-column`

### Visible Slide Content

- Visible title: What tokenomics means
- Body:
  - Tokenomics is the discipline of measuring what AI workflows consume, what they change, and whether the result is worth scaling.
  - Tokens are the billing unit. Workflows are the business unit.
- Columns:
  - Token view
    - Items: input, output, model, requests
  - Workflow view
    - Items: context, tools, retries, review, outcomes

### Manifest Audit

No visible text outside manifest visible fields was detected by the static render contract.

### Visual Description

Restrained two-column comparison between token accounting and workflow economics.

### Speaker Notes

Keep this as the core definition. Do not make it sound academic. The useful shift is from provider billing units to the actual business workflow.

## 06. Token price is not workflow cost

- ID: `token-price-is-not-workflow-cost`
- Layout: `two-column`

### Visible Slide Content

- Visible title: Token price is not workflow cost
- Body:
  - The invoice tells you what the provider charged. It does not tell you whether the workflow was worth running.
- Columns:
  - Provider invoice
    - Items: model usage, token usage, tool charges, if applicable
  - Workflow cost
    - Items: retrieval, validation, review, rework, outcome

### Manifest Audit

No visible text outside manifest visible fields was detected by the static render contract.

### Visual Description

Simple side-by-side comparison between provider invoice surfaces and broader workflow cost surfaces.

### Speaker Notes

Provider cost is real, but incomplete. A production workflow can include retrieval, tool calls, validation, review, rework, and business outcomes that never appear on the provider invoice.

## 07. The real cost stack

- ID: `real-cost-stack`
- Layout: `grouped-cards`

### Visible Slide Content

- Visible title: The real cost stack
- Body:
  - Cost hides in layers.
- Cards:
  - Provider
    - Items: model tokens, cached tokens, tool charges
  - Application
    - Items: retrieval, storage, orchestration, infrastructure
  - Business
    - Items: review, rework, latency, compliance

### Manifest Audit

No visible text outside manifest visible fields was detected by the static render contract.

### Visual Description

Three-zone cost grouping instead of another dense stack: provider, application, and business.

### Speaker Notes

Use this slide to challenge simplistic per-prompt math. The visible model call is often just the most obvious line item. The durable habit is grouping costs by where they are created and who can influence them.

## 08. Model sizing is architecture

- ID: `model-sizing-is-architecture`
- Layout: `statement`

### Visible Slide Content

- Visible title: Model sizing is architecture
- Body:
  - The strongest model is sometimes right. It should not be the unmanaged default.
- Bullets:
  - Can normal code solve it?
  - Can code handle most of it?
  - Can a smaller model handle the language portion?
  - Can a mid-tier model handle it with validation?
  - Does it need a frontier model?
  - Does the value justify that choice?

### Manifest Audit

No visible text outside manifest visible fields was detected by the static render contract.

### Visual Description

Clean decision path for model sizing, shown as a serious operating sequence rather than a toy ladder.

### Speaker Notes

This is not a cheapness argument. It is an architectural control argument. The model is part of the design, not just a setting.

## 09. Model strategy examples

- ID: `model-strategy-examples`
- Layout: `grouped-cards`

### Visible Slide Content

- Visible title: Model strategy examples
- Body:
  - Match model capability to workflow risk.
- Cards:
  - Routine language work
    - Body: categorization, summarization
  - Structured business work
    - Body: extraction, validation, workflow assistance
  - High-risk work
    - Body: code review, policy/compliance, customer-facing recommendations

### Manifest Audit

No visible text outside manifest visible fields was detected by the static render contract.

### Visual Description

Three grouped example cards organized by workflow risk instead of a six-row table.

### Speaker Notes

Detailed examples: categorize support tickets with a smaller model plus validation and escalation; summarize internal notes with a small or mid-tier model; extract document fields with schema validation; use mid-tier or stronger models with guardrails for customer-facing recommendations; use stronger models with retrieval for complex code review; pair policy or compliance analysis with human review. Tie this to ColdFusion apps: forms, reports, support tools, admin workflows, dashboards, intranet systems, and integration-heavy business apps.

## 10. Context is where cost quietly grows

- ID: `context-cost-grows`
- Layout: `statement`

### Visible Slide Content

- Visible title: Context is where cost quietly grows
- Body:
  - "Just send everything" is not an architecture.
- Bullets:
  - system instructions
  - user prompt
  - chat history
  - retrieved documents
  - examples
  - tool outputs
  - formatting rules
  - policy instructions

### Manifest Audit

No visible text outside manifest visible fields was detected by the static render contract.

### Visual Description

Context shown as an input budget with restrained stacked token bands, not a marketing funnel.

### Speaker Notes

Long context is useful, but it is a cost surface. It can also introduce noise. The goal is selected context, not maximum context.

## 11. Context discipline

- ID: `context-discipline`
- Layout: `statement`

### Visible Slide Content

- Visible title: Context discipline
- Body:
  - Send the smallest sufficient context for the task.
- Bullets:
  - Keep stable instructions stable.
  - Retrieve fewer, better documents.
  - Summarize long history.
  - Trim tool output before sending it back.

### Manifest Audit

No visible text outside manifest visible fields was detected by the static render contract.

### Visual Description

Four principle rows with quiet emphasis; no dense seven-item checklist.

### Speaker Notes

Also version prompts, track retrieved token count separately, and measure context size by workflow. Mention that OpenAI, Anthropic, and Google expose different pricing and caching surfaces. The vendor details differ. The architecture lesson is consistent.

### Citations

- OpenAI: [API Pricing](https://developers.openai.com/api/docs/pricing)
  Supports pricing surfaces such as input, cached input, output, model tier, processing mode, and tool costs.
- Anthropic: [Claude Pricing](https://docs.anthropic.com/en/docs/about-claude/pricing)
  Supports input, output, cache write, cache read, and tool-related pricing surfaces.
- Gemini: [Gemini API Pricing](https://ai.google.dev/gemini-api/docs/pricing)
  Supports context caching, cache storage, and grounding charge surfaces.

## 12. Tool calls turn prompts into transactions

- ID: `tool-calls-are-transactions`
- Layout: `statement`

### Visible Slide Content

- Visible title: Tool calls turn prompts into transactions
- Body:
  - The user made one request.
  - The application executed a transaction.
- Bullets:
  - classify
  - retrieve
  - query database
  - call API
  - validate
  - retry
  - answer
  - review

### Manifest Audit

No visible text outside manifest visible fields was detected by the static render contract.

### Visual Description

A single clean transaction trace showing how one request expands into operational steps.

### Speaker Notes

This is where agentic workflows, MCP, database calls, and external APIs change the cost model. One user request can become a transaction across several systems.

## 13. ColdFusion implementation pattern

- ID: `coldfusion-implementation-pattern`
- Layout: `architecture`

### Visible Slide Content

- Visible title: ColdFusion implementation pattern
- Body:
  - Put a measurable layer around AI usage.
- Cards:
  - ColdFusion Application
  - AI Service Wrapper / CFC
    - Items: Provider Call, Token Tracking, Tool Tracking, Retry Tracking, Cost Estimate, Outcome Logging
  - Metrics Store
  - Dashboard / Reports

### Manifest Audit

No visible text outside manifest visible fields was detected by the static render contract.

### Visual Description

One clean architecture diagram with the AI Service Wrapper / CFC emphasized as the central measurable layer.

### Speaker Notes

The point is not to scatter AI calls across controllers, CFCs, scheduled tasks, and UI handlers. Centralize the measurable behavior in a wrapper or service layer. The wrapper should capture provider, model, prompt version, token counts, tool calls, retries, cost estimates, status, review, and outcome hooks.

## 14. Build an AI Usage Ledger

- ID: `ai-usage-ledger`
- Layout: `grouped-cards`

### Visible Slide Content

- Visible title: Build an AI Usage Ledger
- Body:
  - Every production AI workflow should create a structured usage record.
- Cards:
  - Identity
    - Items: application, workflow, provider, model, prompt version
  - Usage
    - Items: input tokens, output tokens, cached tokens, retrieved tokens
  - Transaction
    - Items: tool calls, retries, validation failures, latency
  - Outcome
    - Items: status, review required, estimated cost

### Manifest Audit

No visible text outside manifest visible fields was detected by the static render contract.

### Visual Description

Four grouped ledger field cards instead of a dense table.

### Speaker Notes

This is the practical center of the talk. Make it feel buildable. The first ledger does not have to be perfect, but every workflow needs a structured record. Additional useful fields include retrieved document IDs, response status, error category, user or team, environment, and release version.

## 15. What the usage ledger answers

- ID: `usage-ledger-answers`
- Layout: `statement`

### Visible Slide Content

- Visible title: What the usage ledger answers
- Body:
  - Cost visibility becomes workflow visibility.
- Bullets:
  - Which workflows spend the most?
  - Where is context growing?
  - Which tools multiply cost?
  - What does a successful outcome cost?

### Manifest Audit

No visible text outside manifest visible fields was detected by the static render contract.

### Visual Description

Four large question rows with generous spacing, emphasizing operational visibility.

### Speaker Notes

The goal is not a perfect finance system on day one. The goal is to stop flying blind and make workflow questions answerable. Additional questions include which models are overused, where retries are hiding, and which workflows require review.

## 16. Usage is not ROI

- ID: `usage-is-not-roi`
- Layout: `grouped-cards`

### Visible Slide Content

- Visible title: Usage is not ROI
- Body:
  - 80,000 AI calls is activity. It is not value.
- Cards:
  - Activity metric
    - Value: 80,000 AI calls
  - Operating metric
    - Body: Example data: review time fell from 18 minutes to 7 minutes, with a 4% escalation rate, at $0.14 per completed review.

### Manifest Audit

No visible text outside manifest visible fields was detected by the static render contract.

### Visual Description

Clean contrast between an activity metric and an operating metric, with the operating metric marked as example data.

### Speaker Notes

This is the second major turn. Consumption metrics matter, but they are only half of the story. Usage needs to connect to a measurable operational result. The numbers shown here are illustrative until replaced with real measured data.

## 17. Build an Outcome Ledger

- ID: `outcome-ledger`
- Layout: `grouped-cards`

### Visible Slide Content

- Visible title: Build an Outcome Ledger
- Body:
  - Pair usage metrics with business outcomes.
- Cards:
  - Time
    - Body: minutes avoided per task
  - Throughput
    - Body: more tickets, cases, documents, reviews
  - Quality
    - Body: fewer errors, escalations, rework
  - Business
    - Body: revenue impact, risk reduction, customer experience

### Manifest Audit

No visible text outside manifest visible fields was detected by the static render contract.

### Visual Description

Four outcome groups instead of a seven-row table.

### Speaker Notes

People liking a tool is feedback. A measured improvement at an acceptable quality threshold is an operating metric. Additional outcome categories include productivity, audit coverage, faster response, better conversion, renewal support, and fewer missed issues.

## 18. A useful ROI formula

- ID: `useful-roi-formula`
- Layout: `formula`

### Visible Slide Content

- Visible title: A useful ROI formula
- Body:
  - Use simple math before complex dashboards.
- Formula: AI Workflow ROI = (Value Created - Total Workflow Cost) / Total Workflow Cost
- Total workflow cost:
  - model
  - tools
  - retrieval
  - infrastructure
  - review
  - rework
- Value created:
  - time
  - throughput
  - quality
  - revenue
  - risk reduction

### Manifest Audit

No visible text outside manifest visible fields was detected by the static render contract.

### Visual Description

Dominant formula block with two small supporting panels for cost and value lines.

### Speaker Notes

The first version will be imperfect. That is acceptable. The goal is disciplined visibility, not theatrical precision.

## 19. Enterprise and SMB failure modes

- ID: `failure-modes`
- Layout: `two-column`

### Visible Slide Content

- Visible title: Enterprise and SMB failure modes
- Body:
  - Same discipline. Different ways to get hurt.
- Columns:
  - Enterprise
    - Items: invisible spend at scale, disconnected tools, pilots that never scale
  - SMB
    - Items: spend with no margin benefit, overbuying sophistication, useful tools that are never evaluated

### Manifest Audit

No visible text outside manifest visible fields was detected by the static render contract.

### Visual Description

Two-column contrast with three visible failure modes per column.

### Speaker Notes

Do not make this a long enterprise-versus-SMB lecture. Use it to show that tokenomics matters at both scales. Additional failure modes include governance after adoption, unclear ownership, owner intuition replacing measurement, and no measurement at all.

## 20. Scale, optimize, or stop

- ID: `scale-optimize-stop`
- Layout: `matrix`

### Visible Slide Content

- Visible title: Scale, optimize, or stop
- Body:
  - Every AI workflow needs an operating decision.

| Cost | Value | Decision |
| --- | --- | --- |
| low | high | scale |
| high | high | optimize |
| low | low | tolerate, redesign, or defer |
| high | low | stop |
| unclear | unclear | instrument before expanding |

### Manifest Audit

No visible text outside manifest visible fields was detected by the static render contract.

### Visual Description

Clean decision matrix connecting cost, value, and operating decision.

### Speaker Notes

This gives business and technical teams a shared decision model. The unknown state is not a reason to expand. It is a reason to instrument.

## 21. Closing

- ID: `closing`
- Layout: `closing`

### Visible Slide Content

- Visible title: The question is not just whether the AI worked.
- Body:
  - The question is whether the workflow was worth running.
  - That is tokenomics.

### Manifest Audit

No visible text outside manifest visible fields was detected by the static render contract.

### Visual Description

Minimal final slide with the same subtle ledger-row texture and cost trace as the title slide.

### Speaker Notes

Close soberly. AI is becoming normal application architecture. It needs observability, accountability, cost controls, and measurable outcomes.
