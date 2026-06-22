-- Apache Derby reference schema for CAIROI.
-- The app creates this schema automatically through cairoi.db.DerbyStore.

CREATE TABLE cairoi_applications (
    app_id VARCHAR(100) NOT NULL PRIMARY KEY,
    app_name VARCHAR(200) NOT NULL,
    owner_name VARCHAR(200),
    environment VARCHAR(50) NOT NULL DEFAULT 'dev',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active SMALLINT NOT NULL DEFAULT 1
);

CREATE TABLE cairoi_traces (
    trace_id VARCHAR(80) NOT NULL PRIMARY KEY,
    app_id VARCHAR(100) NOT NULL,
    environment VARCHAR(50) NOT NULL DEFAULT 'dev',
    workflow_name VARCHAR(200) NOT NULL,
    user_hash VARCHAR(80),
    session_hash VARCHAR(80),
    request_id VARCHAR(120),
    started_at TIMESTAMP NOT NULL,
    ended_at TIMESTAMP,
    duration_ms INT,
    status VARCHAR(40) NOT NULL DEFAULT 'success',
    total_input_tokens INT NOT NULL DEFAULT 0,
    total_output_tokens INT NOT NULL DEFAULT 0,
    total_tokens INT NOT NULL DEFAULT 0,
    estimated_cost DECIMAL(19, 8) NOT NULL DEFAULT 0,
    metadata_json CLOB,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE cairoi_spans (
    span_id VARCHAR(80) NOT NULL PRIMARY KEY,
    trace_id VARCHAR(80) NOT NULL,
    parent_span_id VARCHAR(80),
    app_id VARCHAR(100) NOT NULL,
    environment VARCHAR(50) NOT NULL DEFAULT 'dev',
    workflow_name VARCHAR(200) NOT NULL,
    operation_type VARCHAR(80) NOT NULL,
    operation_name VARCHAR(200),
    provider VARCHAR(100),
    model_name VARCHAR(200),
    started_at TIMESTAMP NOT NULL,
    ended_at TIMESTAMP,
    duration_ms INT,
    status VARCHAR(40) NOT NULL DEFAULT 'success',
    input_tokens INT NOT NULL DEFAULT 0,
    output_tokens INT NOT NULL DEFAULT 0,
    total_tokens INT NOT NULL DEFAULT 0,
    input_token_source VARCHAR(40),
    output_token_source VARCHAR(40),
    total_token_source VARCHAR(40),
    estimated_cost DECIMAL(19, 8) NOT NULL DEFAULT 0,
    cost_source VARCHAR(80),
    prompt_hash VARCHAR(80),
    response_hash VARCHAR(80),
    prompt_chars INT NOT NULL DEFAULT 0,
    response_chars INT NOT NULL DEFAULT 0,
    request_bytes INT NOT NULL DEFAULT 0,
    response_bytes INT NOT NULL DEFAULT 0,
    error_type VARCHAR(200),
    error_message VARCHAR(2000),
    metadata_json CLOB,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE cairoi_api_keys (
    api_key_id INT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    app_id VARCHAR(100) NOT NULL,
    api_key_hash VARCHAR(80) NOT NULL UNIQUE,
    api_key_preview VARCHAR(40) NOT NULL,
    is_active SMALLINT NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_used_at TIMESTAMP
);

CREATE TABLE cairoi_model_prices (
    price_id INT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    provider VARCHAR(100) NOT NULL,
    model_name VARCHAR(200) NOT NULL,
    input_cost_per_1m DECIMAL(19, 8) NOT NULL DEFAULT 0,
    output_cost_per_1m DECIMAL(19, 8) NOT NULL DEFAULT 0,
    currency VARCHAR(10) NOT NULL DEFAULT 'USD',
    effective_start TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    effective_end TIMESTAMP,
    is_active SMALLINT NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX ix_cairoi_spans_trace_started ON cairoi_spans(trace_id, started_at);
CREATE INDEX ix_cairoi_spans_reporting ON cairoi_spans(app_id, environment, workflow_name, provider, model_name, operation_type, started_at);
CREATE INDEX ix_cairoi_spans_status ON cairoi_spans(status, started_at);
CREATE INDEX ix_cairoi_traces_reporting ON cairoi_traces(app_id, environment, workflow_name, started_at);
CREATE INDEX ix_cairoi_traces_status ON cairoi_traces(status, started_at);
CREATE INDEX ix_cairoi_api_keys_app ON cairoi_api_keys(app_id, is_active);
CREATE INDEX ix_cairoi_model_prices_lookup ON cairoi_model_prices(provider, model_name, is_active, effective_start, effective_end);
