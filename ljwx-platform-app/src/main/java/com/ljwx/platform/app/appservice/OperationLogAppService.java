package com.ljwx.platform.app.appservice;

import com.ljwx.platform.app.domain.dto.OperationLogQueryDTO;
import com.ljwx.platform.app.domain.entity.SysOperationLog;
import com.ljwx.platform.app.infra.mapper.SysOperationLogMapper;
import com.ljwx.platform.core.id.SnowflakeIdGenerator;
import com.ljwx.platform.core.result.PageResult;
import lombok.RequiredArgsConstructor;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.regex.Pattern;

/**
 * 操作日志应用服务。
 *
 * <p>主要职责：
 * <ol>
 *   <li>异步写入操作日志，使用专用线程池（core=2, max=4, queue=1024）</li>
 *   <li>日志体超 4096 字节自动截断</li>
 *   <li>敏感字段脱敏：password → ***, phone → 中间四位 *, idCard → 中间段 *</li>
 *   <li>分页查询操作日志（TenantLineInterceptor 自动注入 tenant_id）</li>
 * </ol>
 */
@Service
@RequiredArgsConstructor
public class OperationLogAppService {

    /** 请求/响应体最大长度（超出截断） */
    private static final int MAX_BODY_LENGTH = 4096;

    private static final Pattern PASSWORD_PATTERN = Pattern.compile(
            "(\"password\"\\s*:\\s*\")([^\"]*)(\")", Pattern.CASE_INSENSITIVE);
    private static final Pattern PHONE_PATTERN = Pattern.compile(
            "(1[3-9]\\d)(\\d{4})(\\d{4})");
    private static final Pattern ID_CARD_PATTERN = Pattern.compile(
            "(\\d{6})(\\d{8})(\\d{3}[0-9Xx])");

    private final SysOperationLogMapper operationLogMapper;
    private final SnowflakeIdGenerator idGenerator;

    /**
     * 异步保存操作日志（使用专用线程池 logTaskExecutor，core=2, max=4, queue=1024）。
     *
     * <p>日志体超 4096 字节截断，敏感字段已脱敏后才写入。
     * tenant_id 由 TenantLineInterceptor 自动注入，禁止在此处手动设置。
     *
     * @param log 待保存的操作日志实体（id 由此方法分配）
     */
    @Async("logTaskExecutor")
    public void saveOperationLog(SysOperationLog log) {
        log.setId(idGenerator.nextId());

        // 截断并脱敏请求参数
        if (log.getRequestParam() != null) {
            String sanitized = desensitize(log.getRequestParam());
            log.setRequestParam(truncate(sanitized, MAX_BODY_LENGTH));
        }

        // 截断响应结果
        if (log.getResponseResult() != null) {
            log.setResponseResult(truncate(log.getResponseResult(), MAX_BODY_LENGTH));
        }

        operationLogMapper.insert(log);
    }

    /**
     * 分页查询操作日志列表。
     * TenantLineInterceptor 自动注入 tenant_id，无需手动设置。
     */
    public PageResult<SysOperationLog> listOperationLogs(OperationLogQueryDTO query) {
        List<SysOperationLog> records = operationLogMapper.selectList(query);
        long total = operationLogMapper.countList(query);
        return new PageResult<>(records, total);
    }

    /**
     * 导出操作日志（返回列表，不设页大小限制；调用方可进一步处理为文件）。
     */
    public List<SysOperationLog> exportLogs(OperationLogQueryDTO query) {
        query.setPageSize(Integer.MAX_VALUE);
        query.setPageNum(1);
        return operationLogMapper.selectList(query);
    }

    // ── 私有工具方法 ─────────────────────────────────────────────

    /**
     * 将字符串截断为指定最大长度，超出部分追加省略标记。
     */
    private static String truncate(String text, int maxLength) {
        if (text == null || text.length() <= maxLength) {
            return text;
        }
        return text.substring(0, maxLength) + "...[truncated]";
    }

    /**
     * 对日志内容进行敏感字段脱敏。
     *
     * <ul>
     *   <li>password → ***</li>
     *   <li>手机号（11位1开头） → 前3位 + **** + 后4位</li>
     *   <li>身份证号（18位） → 前6位 + ******** + 后4位</li>
     * </ul>
     */
    static String desensitize(String text) {
        if (text == null || text.isEmpty()) {
            return text;
        }
        // password 字段脱敏
        text = PASSWORD_PATTERN.matcher(text).replaceAll("$1***$3");
        // 手机号脱敏：中间四位 *
        text = PHONE_PATTERN.matcher(text).replaceAll("$1****$3");
        // 身份证脱敏：中间段 *
        text = ID_CARD_PATTERN.matcher(text).replaceAll("$1********$3");
        return text;
    }
}
