package com.ljwx.platform.app.controller;

import com.ljwx.platform.app.domain.dto.FrontendErrorDTO;
import com.ljwx.platform.app.domain.entity.SysFrontendError;
import com.ljwx.platform.app.infra.mapper.SysFrontendErrorMapper;
import com.ljwx.platform.core.id.SnowflakeIdGenerator;
import com.ljwx.platform.core.result.Result;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 前端错误监控 Controller。
 */
@RestController
@RequestMapping("/api/v1/frontend-errors")
@RequiredArgsConstructor
public class FrontendErrorController {

    private final SysFrontendErrorMapper frontendErrorMapper;
    private final SnowflakeIdGenerator idGenerator;

    /**
     * 接收前端错误上报。
     *
     * <p>权限：已登录即可（{@code isAuthenticated()}），无需具体权限。
     */
    @PreAuthorize("isAuthenticated()")
    @PostMapping
    public Result<Void> report(@RequestBody @Valid FrontendErrorDTO dto) {
        SysFrontendError error = new SysFrontendError();
        error.setId(idGenerator.nextId());
        error.setErrorMessage(dto.getErrorMessage());
        error.setStackTrace(dto.getStackTrace());
        error.setPageUrl(dto.getPageUrl());
        error.setUserAgent(dto.getUserAgent());

        frontendErrorMapper.insert(error);
        return Result.ok();
    }
}
