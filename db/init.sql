-- Eigenes Schema, getrennt von den internen n8n-Tabellen
CREATE SCHEMA IF NOT EXISTS automation;

CREATE TABLE automation.processed_attachments (
    id                    bigserial PRIMARY KEY,
    message_id            text        NOT NULL,
    attachment_sha256     char(64)    NOT NULL UNIQUE,  -- gleiche Rechnung in zwei Mails = Duplikat
    filename              text,
    status                text        NOT NULL DEFAULT 'pending'
                          CHECK (status IN ('pending', 'uploaded', 'failed', 'skipped')),
    paperless_task_id     uuid,
    paperless_document_id integer,
    error                 text,
    created_at            timestamptz NOT NULL DEFAULT now(),
    updated_at            timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX ON automation.processed_attachments (message_id);
