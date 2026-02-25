package com.ljwx.platform.web.aop;

import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.reflect.MethodSignature;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;
import org.springframework.stereotype.Component;
import org.springframework.web.bind.annotation.RequestMapping;

/**
 * 慢接口监控切面。
 *
 * <p>切点：所有 {@code @RestController} 方法。
 * <ul>
 *   <li>超过 3000ms 输出 WARN 日志</li>
 *   <li>超过 10000ms 输出 ERROR 日志</li>
 * </ul>
 *
 * <p>日志包含：接口路径、方法名、执行时间、traceId（从 MDC 读取）。
 */
@Aspect
@Component
public class SlowApiAspect {

    private static final Logger log = LoggerFactory.getLogger(SlowApiAspect.class);
    private static final long WARN_THRESHOLD_MS = 3000;
    private static final long ERROR_THRESHOLD_MS = 10000;

    @Around("@within(org.springframework.web.bind.annotation.RestController)")
    public Object around(ProceedingJoinPoint joinPoint) throws Throwable {
        long startTime = System.currentTimeMillis();
        Object result = null;
        Throwable exception = null;

        try {
            result = joinPoint.proceed();
            return result;
        } catch (Throwable e) {
            exception = e;
            throw e;
        } finally {
            long duration = System.currentTimeMillis() - startTime;
            if (duration >= ERROR_THRESHOLD_MS) {
                logSlowApi("ERROR", joinPoint, duration);
            } else if (duration >= WARN_THRESHOLD_MS) {
                logSlowApi("WARN", joinPoint, duration);
            }
        }
    }

    private void logSlowApi(String level, ProceedingJoinPoint joinPoint, long duration) {
        MethodSignature signature = (MethodSignature) joinPoint.getSignature();
        String className = signature.getDeclaringType().getSimpleName();
        String methodName = signature.getName();
        String traceId = MDC.get("traceId");

        String path = extractPath(signature);
        String message = String.format(
                "Slow API detected | path=%s | method=%s.%s | duration=%dms | traceId=%s",
                path, className, methodName, duration, traceId
        );

        if ("ERROR".equals(level)) {
            log.error(message);
        } else {
            log.warn(message);
        }
    }

    private String extractPath(MethodSignature signature) {
        RequestMapping classMapping = signature.getDeclaringType().getAnnotation(RequestMapping.class);
        RequestMapping methodMapping = signature.getMethod().getAnnotation(RequestMapping.class);

        String classPath = (classMapping != null && classMapping.value().length > 0)
                ? classMapping.value()[0] : "";
        String methodPath = (methodMapping != null && methodMapping.value().length > 0)
                ? methodMapping.value()[0] : "";

        return classPath + methodPath;
    }
}
