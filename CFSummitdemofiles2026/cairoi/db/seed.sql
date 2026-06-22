-- Apache Derby seed reference.
-- The setup page performs idempotent seeding in CFML.

INSERT INTO cairoi_applications (app_id, app_name, owner_name, environment, is_active)
VALUES ('demo-app', 'CAIROI Demo App', 'Local Developer', 'dev', 1);

INSERT INTO cairoi_api_keys (app_id, api_key_hash, api_key_preview, is_active)
VALUES ('demo-app', 'cd26c5b1cb98378f63601ce3ea019fed5c9dba1ba9dcbf28146cd0df37adba45', 'cairoi-dev...', 1);

INSERT INTO cairoi_applications (app_id, app_name, owner_name, environment, is_active)
VALUES ('inventory-ai', 'InventoryAI MCP Demo', 'CFSummit 2026 Demos', 'dev', 1);

INSERT INTO cairoi_api_keys (app_id, api_key_hash, api_key_preview, is_active)
VALUES ('inventory-ai', 'ea3a8732b8f36dafe7b1724dc6acda7c43282e248efd9e38d39a119f2a56031b', 'cairoi-inventory...', 1);

INSERT INTO cairoi_applications (app_id, app_name, owner_name, environment, is_active)
VALUES ('cfcase', 'CF Cases Mystery Demo', 'CFSummit 2026 Demos', 'conference', 1);

INSERT INTO cairoi_api_keys (app_id, api_key_hash, api_key_preview, is_active)
VALUES ('cfcase', 'ad41c826bc06918aaae1918edc886be7f61052629322ebaf4ca857d26678fa18', 'cairoi-cfcase...', 1);

INSERT INTO cairoi_applications (app_id, app_name, owner_name, environment, is_active)
VALUES ('onboardiq', 'OnboardIQ RAG Guardrail Demo', 'CFSummit 2026 Demos', 'conference', 1);

INSERT INTO cairoi_api_keys (app_id, api_key_hash, api_key_preview, is_active)
VALUES ('onboardiq', '7a4d22dc82368e56f83b94512cec7936bf0132cd438413f9deaf3d2ecd080490', 'cairoi-onboardiq...', 1);

INSERT INTO cairoi_applications (app_id, app_name, owner_name, environment, is_active)
VALUES ('donut-rag', 'Glaze Against The Machine Donut RAG Demo', 'CFSummit 2026 Demos', 'conference', 1);

INSERT INTO cairoi_api_keys (app_id, api_key_hash, api_key_preview, is_active)
VALUES ('donut-rag', '50d7f372578a3e5a2b02cc5c963892c84625f88fe29e80d3d149adc32dc9d4b6', 'cairoi-donut-rag...', 1);

INSERT INTO cairoi_applications (app_id, app_name, owner_name, environment, is_active)
VALUES ('code-review-local', 'CodeReview.cf Local Review Demo', 'CFSummit 2026 Demos', 'conference', 1);

INSERT INTO cairoi_api_keys (app_id, api_key_hash, api_key_preview, is_active)
VALUES ('code-review-local', '90ffea3c9a5c411075b034c9d4be8f3eeaced7ab4095a406d86b420775fccacb', 'cairoi-code-review...', 1);

INSERT INTO cairoi_model_prices (provider, model_name, input_cost_per_1m, output_cost_per_1m, currency)
VALUES ('openai', 'gpt-5-nano', 0.05, 0.40, 'USD');

INSERT INTO cairoi_model_prices (provider, model_name, input_cost_per_1m, output_cost_per_1m, currency)
VALUES ('openai', 'gpt-5-mini', 0.25, 2.00, 'USD');

INSERT INTO cairoi_model_prices (provider, model_name, input_cost_per_1m, output_cost_per_1m, currency)
VALUES ('openai', 'gpt-4o-mini', 0.15, 0.60, 'USD');

INSERT INTO cairoi_model_prices (provider, model_name, input_cost_per_1m, output_cost_per_1m, currency)
VALUES ('openai', 'text-embedding-3-small', 0.02, 0.00, 'USD');

INSERT INTO cairoi_model_prices (provider, model_name, input_cost_per_1m, output_cost_per_1m, currency)
VALUES ('anthropic', 'claude-haiku-4-5-20251001', 1.00, 5.00, 'USD');

INSERT INTO cairoi_model_prices (provider, model_name, input_cost_per_1m, output_cost_per_1m, currency)
VALUES ('ollama', 'llama3.2', 0.00, 0.00, 'USD');

INSERT INTO cairoi_model_prices (provider, model_name, input_cost_per_1m, output_cost_per_1m, currency)
VALUES ('ollama', 'nomic-embed-text', 0.00, 0.00, 'USD');
