-- 2026-06-05-create-generated-assets-and-guardrail-events.sql
-- Session 6 (Guardrails + Generated Assets) Layer-2 tables.
-- Canonical schema: stylemart-api-contract-and-db-schema.md §8.8 (translated PostgreSQL -> MySQL).
-- Follows the agent_traces migration convention: no hard FKs (chat_sessions / chat_messages
-- are Layer-2 tables not guaranteed present in db/mysql), so logical references are documented
-- in comments and indexed instead. users / carts exist but are left FK-free here for the same
-- "migration stays runnable on its own" reason.

CREATE TABLE IF NOT EXISTS generated_assets (
  asset_id          VARCHAR(64)  NOT NULL,
  type              VARCHAR(32)  NOT NULL,            -- recovery-email | landing-section | upsell-pitch
  session_id        VARCHAR(64)  NULL,                -- -> chat_sessions(session_id)
  user_id           VARCHAR(64)  NULL,                -- -> users(user_id)
  cart_id           VARCHAR(64)  NULL,                -- -> carts(cart_id)
  body_html         MEDIUMTEXT   NULL,
  body_json         JSON         NULL,
  source_inputs     JSON         NOT NULL,            -- prompt/context the run was given (Snapshot)
  guardrail_results JSON         NOT NULL,            -- frozen rule outcomes for this run (Snapshot)
  created_at        TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (asset_id),
  KEY idx_generated_assets_user (user_id, created_at),
  CONSTRAINT chk_generated_assets_type
    CHECK (type IN ('recovery-email', 'landing-section', 'upsell-pitch')),
  CONSTRAINT chk_generated_assets_body
    CHECK (body_html IS NOT NULL OR body_json IS NOT NULL)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Rows are IMMUTABLE: every column is captured once at G1/G3/G4 success. Regenerating an
-- asset always mints a NEW asset_id; there is no UPDATE path and no "version" column.

CREATE TABLE IF NOT EXISTS guardrail_events (
  event_id          VARCHAR(64)  NOT NULL,
  session_id        VARCHAR(64)  NOT NULL,            -- -> chat_sessions(session_id) ON DELETE CASCADE
  message_id        VARCHAR(64)  NULL,                -- -> chat_messages(message_id); NULL for generated-asset runs
  rule_id           VARCHAR(64)  NOT NULL,
  phase             VARCHAR(16)  NOT NULL,            -- input | output (which agent guardrail list fired it)
  result            VARCHAR(16)  NOT NULL,            -- success | failure | fatal (CHECK below)
  message           MEDIUMTEXT   NULL,                -- safe, user-facing reason the rule returned (failure/fatal)
  reprompt_message  MEDIUMTEXT   NULL,                -- LLM re-answer instruction for `failure`; NULL for success/fatal
  created_at        TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (event_id),
  KEY idx_guardrail_events_session (session_id, created_at),
  KEY idx_guardrail_events_message (message_id),
  CONSTRAINT chk_guardrail_events_result
    CHECK (result IN ('success', 'failure', 'fatal'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- guardrail_events is the per-event SoT log (one row per evaluated rule). Every row in
-- generated_assets.guardrail_results (the JSON Snapshot) MUST also exist here, written in the
-- SAME DB transaction (contract §8.8). On any disagreement, guardrail_events wins.
--
-- result model (CFC guardrail contract, no in-place rewrite):
--   success  -> rule passed; emitted to the stream as guardrail.check.
--   failure  -> recoverable violation; emitted as guardrail.violation; the agent re-answers using
--               `reprompt_message`. The chat stream stays HTTP 200 and continues.
--   fatal    -> unrecoverable violation; emitted as guardrail.violation, then an `error` event
--               (code = guardrail_blocked, source = guardrail) and a terminal done(status=error).
--               HTTP stays 200 throughout. `reprompt_message` is NULL.
-- This schema is the reconciled source of truth; it intentionally supersedes the rewrite-era
-- severity/original_draft/final_output shape. Contract §8.8 has been updated to match.
