package com.ljwx.platform.data.annotation;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * 数据变更审计注解。
 *
 * <p>标注在 Mapper 方法上，表示该方法执行的 UPDATE / DELETE 操作需要记录变更历史。
 * DataChangeInterceptor（data 模块）会拦截这些方法，对比变更前后的数据，
 * 并将差异异步写入 sys_data_change_log 表。
 *
 * <p>示例：
 * <pre>
 * &#64;AuditChange(tableName = "sys_user", idField = "id")
 * int updateUser(SysUser user);
 * </pre>
 */
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
public @interface AuditChange {

    /**
     * 表名。
     *
     * @return 表名
     */
    String tableName();

    /**
     * 主键字段名，默认为 "id"。
     *
     * @return 主键字段名
     */
    String idField() default "id";
}
