-- Backfill migration for environments baselined at version 52.
-- V042 may be marked as applied by baseline, so ensure lifecycle fields exist.

DO
$$
BEGIN
    IF (SELECT COUNT(*)
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'sys_tenant'
          AND column_name = 'lifecycle_status') = 0 THEN
        ALTER TABLE sys_tenant
            ADD COLUMN lifecycle_status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE';
    END IF;

    IF (SELECT COUNT(*)
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'sys_tenant'
          AND column_name = 'frozen_reason') = 0 THEN
        ALTER TABLE sys_tenant
            ADD COLUMN frozen_reason VARCHAR(500);
    END IF;

    IF (SELECT COUNT(*)
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'sys_tenant'
          AND column_name = 'frozen_time') = 0 THEN
        ALTER TABLE sys_tenant
            ADD COLUMN frozen_time TIMESTAMP;
    END IF;

    IF (SELECT COUNT(*)
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'sys_tenant'
          AND column_name = 'cancelled_reason') = 0 THEN
        ALTER TABLE sys_tenant
            ADD COLUMN cancelled_reason VARCHAR(500);
    END IF;

    IF (SELECT COUNT(*)
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'sys_tenant'
          AND column_name = 'cancelled_time') = 0 THEN
        ALTER TABLE sys_tenant
            ADD COLUMN cancelled_time TIMESTAMP;
    END IF;
END
$$;

-- Ensure NOT NULL rows are normalized in pre-existing baseline databases.
UPDATE sys_tenant
SET lifecycle_status = 'ACTIVE'
WHERE lifecycle_status IS NULL;

COMMENT ON COLUMN sys_tenant.lifecycle_status IS 'Tenant lifecycle status: ACTIVE/FROZEN/CANCELLED';
COMMENT ON COLUMN sys_tenant.frozen_reason IS 'Reason for freezing the tenant';
COMMENT ON COLUMN sys_tenant.frozen_time IS 'Timestamp when tenant was frozen';
COMMENT ON COLUMN sys_tenant.cancelled_reason IS 'Reason for cancelling the tenant';
COMMENT ON COLUMN sys_tenant.cancelled_time IS 'Timestamp when tenant was cancelled';
