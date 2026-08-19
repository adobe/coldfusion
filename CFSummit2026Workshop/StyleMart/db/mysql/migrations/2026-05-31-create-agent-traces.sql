-- 2026-05-31-create-agent-traces.sql
-- Observability sink for the agent SSE pipeline (Session 1+).
-- One row per emitted SSE event. Write-only on the request thread.

CREATE TABLE IF NOT EXISTS agent_traces (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  session_id    VARCHAR(64)     NOT NULL,
  message_id    VARCHAR(64)     NOT NULL,
  seq           INT UNSIGNED    NOT NULL,
  type          VARCHAR(32)     NOT NULL,
  payload_json  MEDIUMTEXT      NULL,
  ts            TIMESTAMP(3)    NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  KEY idx_agent_traces_session (session_id, ts),
  KEY idx_agent_traces_message (message_id, seq)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
