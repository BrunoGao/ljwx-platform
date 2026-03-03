package com.ljwx.platform.app.domain;

import com.baomidou.mybatisplus.annotation.TableName;
import com.ljwx.platform.app.domain.entity.SysTenant;

/**
 * Backward-compatible tenant alias for legacy service imports.
 */
@TableName("sys_tenant")
public class Tenant extends SysTenant {
}
