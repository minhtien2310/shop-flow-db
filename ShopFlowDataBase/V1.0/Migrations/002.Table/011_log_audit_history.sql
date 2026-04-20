CREATE TABLE IF NOT EXISTS log.audit_history
(
    audit_history_id BIGSERIAL
        CONSTRAINT audit_history_pkey PRIMARY KEY,
    table_name       VARCHAR(250) NOT NULL,
    record_id        VARCHAR(100) NOT NULL,
    old_values       JSON         NOT NULL,
    new_values       JSON         NOT NULL,
    action           VARCHAR(50)  NOT NULL,
    created_by  VARCHAR(100) NOT NULL,
    created_date  TIMESTAMP  NOT NULL DEFAULT now(),
    updated_by    VARCHAR(100),
    updated_date  TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_audit_history_table_name_record_id
    ON log.audit_history (table_name, record_id);
