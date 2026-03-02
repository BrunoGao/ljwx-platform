-- V042: Add tenant lifecycle management fields to sys_tenant

ALTER TABLE sys_tenant
    ADD COLUMN lifecycle_status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    ADD COLUMN frozen_reason VARCHAR(500),
    ADD COLUMN frozen_time TIMESTAMP,
    ADD COLUMN cancelled_reason VARCHAR(500),
    ADD COLUMN cancelled_time TIMESTAMP;

COMMENT ON COLUMN sys_tenant.lifecycle_status IS 'Tenant lifecycle status: ACTIVE/FROZEN/CANCELLED';
COMMENT ON COLUMN sys_tenant.frozen_reason IS 'Reason for freezing the tenant';
COMMENT ON COLUMN sys_tenant.frozen_time IS 'Timestamp when tenant was frozen';
COMMENT ON COLUMN sys_tenant.cancelled_reason IS 'Reason for cancelling the tenant';
COMMENT ON COLUMN sys_tenant.cancelled_time IS 'Timestamp when tenant was cancelled';
