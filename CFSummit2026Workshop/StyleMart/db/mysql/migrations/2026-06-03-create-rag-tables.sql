-- RAG tables for Session 5: Retrieval-Augmented Generation
-- Tracks ingested documents and their chunks for auditability

CREATE TABLE IF NOT EXISTS rag_documents (
    document_id      VARCHAR(64) PRIMARY KEY,
    doc_type         VARCHAR(32) NOT NULL,
    category         VARCHAR(64),
    source_path      VARCHAR(512) NOT NULL UNIQUE,
    loader           VARCHAR(32) NOT NULL,
    splitter         VARCHAR(32) NOT NULL,
    chunk_size       INT NOT NULL CHECK (chunk_size > 0),
    chunk_overlap    INT NOT NULL CHECK (chunk_overlap >= 0),
    content_hash     VARCHAR(64) NOT NULL,
    ingested_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS rag_chunks (
    chunk_id         VARCHAR(64) PRIMARY KEY,
    document_id      VARCHAR(64) NOT NULL,
    chunk_index      INT NOT NULL CHECK (chunk_index >= 0),
    chunk_text       TEXT NOT NULL,
    metadata_json    JSON NOT NULL,
    vector_ref       VARCHAR(256) NOT NULL UNIQUE,
    created_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_chunks_document
        FOREIGN KEY (document_id) REFERENCES rag_documents(document_id) ON DELETE CASCADE,

    CONSTRAINT ux_rag_chunks_doc_index UNIQUE (document_id, chunk_index)
);

CREATE INDEX ix_rag_docs_type ON rag_documents(doc_type);
CREATE INDEX ix_rag_chunks_docid ON rag_chunks(document_id);

-- Note: unique body constraint omitted — seed data has duplicate review text by design.
-- De-duplication is handled at the application layer (ProductService.cfc checks user+product).
