package com.ljwx.platform.app.domain.entity;

import com.ljwx.platform.data.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 操作日志实体，对应 sys_operation_log 表。
 *
 * <p>通过异步线程池（core=2, max=4, queue=1024）写入，
 * 日志体超 4096 字节截断，敏感字段已脱敏。
 */
@Data
@EqualsAndHashCode(callSuper = true)
public class SysOperationLog extends BaseEntity {

    /** 主键ID（Snowflake） */
    private Long id;

    /** 操作模块/描述 */
    private String title;

    /**
     * 业务类型：
     * 0-其他, 1-新增, 2-修改, 3-删除, 4-查询, 5-导出
     */
    private Integer businessType;

    /** 请求方法全限定名（如 com.ljwx.platform.app.controller.UserController#list） */
    private String method;

    /** HTTP 请求方式（GET / POST / PUT / DELETE） */
    private String requestMethod;

    /** 请求 URL */
    private String requestUrl;

    /**
     * 请求参数（超 4096 字节截断，敏感字段已脱敏：
     * password → ***, phone → 中间四位 *, idCard → 中间段 *）
     */
    private String requestParam;

    /** 返回参数（超 4096 字节截断） */
    private String responseResult;

    /** 操作状态：0-正常, 1-异常 */
    private Integer status;

    /** 错误消息（status=1 时记录） */
    private String errorMsg;

    /** 操作人员 ID */
    private Long operatorId;

    /** 操作人员账号 */
    private String operatorName;

    /** 操作人员 IP */
    private String operatorIp;

    /** 操作耗时（毫秒） */
    private Long costTime;
}
