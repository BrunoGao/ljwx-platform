-- Phase 51: Message Center - Records
-- Create msg_record and msg_user_inbox tables

-- Table: msg_record
CREATE TABLE msg_record (
    id                  BIGINT          NOT NULL,
    template_id         BIGINT,
    message_type        VARCHAR(20)     NOT NULL,
    receiver_id         BIGINT,
    receiver_address    VARCHAR(200),
    subject             VARCHAR(200)    NOT NULL,
    content             TEXT            NOT NULL,
    send_status         VARCHAR(20)     NOT NULL,
    send_time           TIMESTAMP,
    error_message       TEXT,
    tenant_id           BIGINT          NOT NULL DEFAULT 0,
    created_by          BIGINT          NOT NULL DEFAULT 0,
    created_time        TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by          BIGINT          NOT NULL DEFAULT 0,
    updated_time        TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted             BOOLEAN         NOT NULL DEFAULT FALSE,
    version             INT             NOT NULL DEFAULT 1,
    PRIMARY KEY (id)
);

-- Indexes for msg_record
CREATE INDEX idx_msg_record_template_id ON msg_record(template_id);
CREATE INDEX idx_msg_record_message_type ON msg_record(message_type);
CREATE INDEX idx_msg_record_receiver_id ON msg_record(receiver_id);
CREATE INDEX idx_msg_record_send_status ON msg_record(send_status);
CREATE INDEX idx_msg_record_tenant_id ON msg_record(tenant_id);
CREATE INDEX idx_msg_record_created_time ON msg_record(created_time);

-- Table: msg_user_inbox
CREATE TABLE msg_user_inbox (
    id                  BIGINT          NOT NULL,
    user_id             BIGINT          NOT NULL,
    message_id          BIGINT          NOT NULL,
    title               VARCHAR(200)    NOT NULL,
    content             TEXT            NOT NULL,
    is_read             BOOLEAN         NOT NULL DEFAULT FALSE,
    read_time           TIMESTAMP,
    tenant_id           BIGINT          NOT NULL DEFAULT 0,
    created_by          BIGINT          NOT NULL DEFAULT 0,
    created_time        TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by          BIGINT          NOT NULL DEFAULT 0,
    updated_time        TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted             BOOLEAN         NOT NULL DEFAULT FALSE,
    version             INT             NOT NULL DEFAULT 1,
    PRIMARY KEY (id)
);

-- Indexes for msg_user_inbox
CREATE INDEX idx_msg_user_inbox_user_id ON msg_user_inbox(user_id);
CREATE INDEX idx_msg_user_inbox_message_id ON msg_user_inbox(message_id);
CREATE INDEX idx_msg_user_inbox_is_read ON msg_user_inbox(is_read);
CREATE INDEX idx_msg_user_inbox_tenant_id ON msg_user_inbox(tenant_id);
CREATE INDEX idx_msg_user_inbox_created_time ON msg_user_inbox(created_time);

-- Foreign keys
ALTER TABLE msg_record ADD CONSTRAINT fk_msg_record_template
    FOREIGN KEY (template_id) REFERENCES msg_template(id);

ALTER TABLE msg_user_inbox ADD CONSTRAINT fk_msg_user_inbox_user
    FOREIGN KEY (user_id) REFERENCES sys_user(id);

ALTER TABLE msg_user_inbox ADD CONSTRAINT fk_msg_user_inbox_message
    FOREIGN KEY (message_id) REFERENCES msg_record(id);
