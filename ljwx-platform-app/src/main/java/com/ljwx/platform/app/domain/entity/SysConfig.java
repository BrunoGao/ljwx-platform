package com.ljwx.platform.app.domain.entity;

import com.ljwx.platform.data.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 系统配置实体，对应 sys_config 表。
 */
@Data
@EqualsAndHashCode(callSuper = true)
public class SysConfig extends BaseEntity {

    /** 主键ID（Snowflake） */
    private Long id;

    /** 参数名称 */
    private String configName;

    /** 参数键名（唯一标识） */
    private String configKey;

    /** 参数键值 */
    private String configValue;

    /** 系统内置：1-是，0-否 */
    private Integer configType;

    /** 备注 */
    private String remark;
}
