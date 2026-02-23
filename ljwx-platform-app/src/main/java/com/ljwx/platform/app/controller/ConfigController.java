package com.ljwx.platform.app.controller;

import com.ljwx.platform.app.appservice.ConfigAppService;
import com.ljwx.platform.app.domain.dto.ConfigCreateDTO;
import com.ljwx.platform.app.domain.dto.ConfigQueryDTO;
import com.ljwx.platform.app.domain.dto.ConfigUpdateDTO;
import com.ljwx.platform.app.domain.entity.SysConfig;
import com.ljwx.platform.core.result.PageResult;
import com.ljwx.platform.core.result.Result;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 系统配置管理 Controller。
 * 权限按 spec/03-api.md §Configs 路由定义。
 */
@RestController
@RequestMapping("/api/configs")
@RequiredArgsConstructor
public class ConfigController {

    private final ConfigAppService configAppService;

    @PreAuthorize("hasAuthority('config:read')")
    @GetMapping
    public Result<PageResult<SysConfig>> list(ConfigQueryDTO query) {
        return Result.ok(configAppService.listConfigs(query));
    }

    @PreAuthorize("hasAuthority('config:write')")
    @PostMapping
    public Result<Long> create(@RequestBody @Valid ConfigCreateDTO dto) {
        return Result.ok(configAppService.createConfig(dto));
    }

    @PreAuthorize("hasAuthority('config:write')")
    @PutMapping("/{id}")
    public Result<Void> update(@PathVariable Long id,
                               @RequestBody @Valid ConfigUpdateDTO dto) {
        dto.setId(id);
        configAppService.updateConfig(dto);
        return Result.ok();
    }

    @PreAuthorize("hasAuthority('config:read')")
    @GetMapping("/key/{key}")
    public Result<SysConfig> getByKey(@PathVariable String key) {
        return Result.ok(configAppService.getConfigByKey(key));
    }
}
