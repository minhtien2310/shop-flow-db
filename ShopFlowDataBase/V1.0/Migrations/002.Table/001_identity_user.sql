-- "user" là từ khóa SQL — cần dấu ngoặc kép.
CREATE TABLE IF NOT EXISTS identity."user"
(
    user_id       UUID PRIMARY KEY     DEFAULT gen_random_uuid(),
    email         VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role          VARCHAR(20)  NOT NULL DEFAULT 'ADMIN',
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT uq_user_email UNIQUE (email)
);

CREATE INDEX IF NOT EXISTS idx_user_role ON identity."user" (role);
