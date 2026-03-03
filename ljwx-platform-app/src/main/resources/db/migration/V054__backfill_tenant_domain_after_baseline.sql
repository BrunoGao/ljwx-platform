-- Backfill migration for environments baselined at version 52.
-- V043 may be marked as applied by baseline, so ensure tenant domain table exists.

DO $$
BEGIN
    IF to_regclass('public.sys_tenant_domain') IS NULL THEN
        EXECUTE $DDL$
            CREATE TABLE sys_tenant_domain (
                id              BIGINT          NOT NULL,
                domain          VARCHAR(200)    NOT NULL,
                tenant_id       BIGINT          NOT NULL,
                status          VARCHAR(20)     NOT NULL DEFAULT 'ENABLED',
                is_primary      BOOLEAN         NOT NULL DEFAULT FALSE,
                verified        BOOLEAN         NOT NULL DEFAULT FALSE,
                verified_time   TIMESTAMP,
                verify_token    VARCHAR(100),
                remark          VARCHAR(500),
                created_by      BIGINT          NOT NULL DEFAULT 0,
                created_time    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_by      BIGINT          NOT NULL DEFAULT 0,
                updated_time    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
                deleted         BOOLEAN         NOT NULL DEFAULT FALSE,
                version         INT             NOT NULL DEFAULT 1,
                PRIMARY KEY (id)
            )
        $DDL$;
    END IF;
END
$$;

DO $$
BEGIN
    IF to_regclass('public.uk_tenant_domain_domain_deleted') IS NULL THEN
        EXECUTE 'CREATE UNIQUE INDEX uk_tenant_domain_domain_deleted ON sys_tenant_domain (domain, deleted)';
    END IF;

    IF to_regclass('public.idx_tenant_domain_tenant_id') IS NULL THEN
        EXECUTE 'CREATE INDEX idx_tenant_domain_tenant_id ON sys_tenant_domain (tenant_id)';
    END IF;

    IF to_regclass('public.idx_tenant_domain_status') IS NULL THEN
        EXECUTE 'CREATE INDEX idx_tenant_domain_status ON sys_tenant_domain (status)';
    END IF;
END
$$;
