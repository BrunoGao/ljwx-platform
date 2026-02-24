package com.ljwx.platform.app.appservice;

import com.ljwx.platform.app.domain.dto.LoginLogQueryDTO;
import com.ljwx.platform.app.domain.entity.SysLoginLog;
import com.ljwx.platform.app.domain.vo.LoginLogVO;
import com.ljwx.platform.app.infra.mapper.SysLoginLogMapper;
import com.ljwx.platform.core.id.SnowflakeIdGenerator;
import com.ljwx.platform.core.result.PageResult;
import lombok.RequiredArgsConstructor;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import java.time.OffsetDateTime;
import java.util.List;

/**
 * 登录日志应用服务。
 *
 * <p>异步写入登录日志，不阻塞登录响应。
 * 使用专用线程池 logTaskExecutor（core=2, max=4, queue=1024）。
 */
@Service
@RequiredArgsConstructor
public class LoginLogAppService {

    private final SysLoginLogMapper loginLogMapper;
    private final SnowflakeIdGenerator idGenerator;

    /**
     * 异步记录登录日志（成功或失败）。
     * 密码字段不传入此方法，日志中不含敏感信息。
     *
     * @param username  登录用户名
     * @param ipAddress 客户端 IP
     * @param userAgent 客户端 User-Agent
     * @param status    1=成功，0=失败
     * @param message   提示消息
     */
    @Async("logTaskExecutor")
    public void recordLogin(String username, String ipAddress, String userAgent,
                            int status, String message) {
        SysLoginLog log = new SysLoginLog();
        log.setId(idGenerator.nextId());
        log.setUsername(username);
        log.setIpAddress(ipAddress != null ? ipAddress : "");
        log.setUserAgent(userAgent != null ? userAgent : "");
        log.setStatus(status);
        log.setMessage(message != null ? message : "");
        log.setLoginTime(OffsetDateTime.now());
        loginLogMapper.insert(log);
    }

    /**
     * 分页查询登录日志。
     * TenantLineInterceptor 自动注入 tenant_id，无需手动设置。
     */
    public PageResult<LoginLogVO> listLoginLogs(LoginLogQueryDTO query) {
        List<LoginLogVO> list = loginLogMapper.selectList(query);
        long total = loginLogMapper.countList(query);
        return new PageResult<>(list, total);
    }
}
