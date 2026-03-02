package com.ljwx.platform.core.security;

import org.aspectj.lang.annotation.Aspect;
import org.springframework.stereotype.Component;

/**
 * 数据脱敏切面。
 * 用于扩展脱敏功能，如日志记录、审计等。
 * 当前版本主要依赖 DataMaskSerializer 实现脱敏。
 */
@Aspect
@Component
public class DataMaskAspect {

    /**
     * 预留：可用于方法级别的脱敏控制
     */
    public DataMaskAspect() {
        // 当前版本使用 Jackson 序列化器实现脱敏
        // 此切面预留用于未来扩展
    }
}
