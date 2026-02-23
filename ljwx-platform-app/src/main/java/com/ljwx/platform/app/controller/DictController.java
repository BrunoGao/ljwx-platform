package com.ljwx.platform.app.controller;

import com.ljwx.platform.app.appservice.DictAppService;
import com.ljwx.platform.app.domain.dto.DictCreateDTO;
import com.ljwx.platform.app.domain.dto.DictQueryDTO;
import com.ljwx.platform.app.domain.dto.DictUpdateDTO;
import com.ljwx.platform.app.domain.entity.SysDictData;
import com.ljwx.platform.app.domain.entity.SysDictType;
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

import java.util.List;

/**
 * 字典管理 Controller。
 * 权限按 spec/03-api.md §Dicts 路由定义。
 */
@RestController
@RequestMapping("/api/dicts")
@RequiredArgsConstructor
public class DictController {

    private final DictAppService dictAppService;

    @PreAuthorize("hasAuthority('dict:read')")
    @GetMapping
    public Result<PageResult<SysDictType>> list(DictQueryDTO query) {
        return Result.ok(dictAppService.listDictTypes(query));
    }

    @PreAuthorize("hasAuthority('dict:write')")
    @PostMapping
    public Result<Long> create(@RequestBody @Valid DictCreateDTO dto) {
        return Result.ok(dictAppService.createDictType(dto));
    }

    @PreAuthorize("hasAuthority('dict:write')")
    @PutMapping("/{id}")
    public Result<Void> update(@PathVariable Long id,
                               @RequestBody @Valid DictUpdateDTO dto) {
        dto.setId(id);
        dictAppService.updateDictType(dto);
        return Result.ok();
    }

    @PreAuthorize("hasAuthority('dict:read')")
    @GetMapping("/type/{type}")
    public Result<List<SysDictData>> getDictDataByType(@PathVariable String type) {
        return Result.ok(dictAppService.getDictDataByType(type));
    }
}
