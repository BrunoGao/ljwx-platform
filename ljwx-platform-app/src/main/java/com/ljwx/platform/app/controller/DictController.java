package com.ljwx.platform.app.controller;

import com.ljwx.platform.app.appservice.DictAppService;
import com.ljwx.platform.app.domain.dto.DictCreateDTO;
import com.ljwx.platform.app.domain.dto.DictDataCreateDTO;
import com.ljwx.platform.app.domain.dto.DictDataUpdateDTO;
import com.ljwx.platform.app.domain.dto.DictQueryDTO;
import com.ljwx.platform.app.domain.dto.DictUpdateDTO;
import com.ljwx.platform.app.domain.entity.SysDictData;
import com.ljwx.platform.app.domain.entity.SysDictType;
import com.ljwx.platform.core.result.PageResult;
import com.ljwx.platform.core.result.Result;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.DeleteMapping;
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
@RequestMapping({"/api/v1/dicts", "/api/dicts"})
@RequiredArgsConstructor
public class DictController {

    private final DictAppService dictAppService;

    @PreAuthorize("hasAuthority('dict:read')")
    @GetMapping({"", "/types"})
    public Result<PageResult<SysDictType>> list(DictQueryDTO query) {
        return Result.ok(dictAppService.listDictTypes(query));
    }

    @PreAuthorize("hasAuthority('dict:write')")
    @PostMapping({"", "/types"})
    public Result<Long> create(@RequestBody @Valid DictCreateDTO dto) {
        return Result.ok(dictAppService.createDictType(dto));
    }

    @PreAuthorize("hasAuthority('dict:read')")
    @GetMapping({"/{id}", "/types/{id}"})
    public Result<SysDictType> detail(@PathVariable Long id) {
        return Result.ok(dictAppService.getDictTypeById(id));
    }

    @PreAuthorize("hasAuthority('dict:write')")
    @PutMapping({"/{id}", "/types/{id}"})
    public Result<Void> update(@PathVariable Long id,
                               @RequestBody @Valid DictUpdateDTO dto) {
        dto.setId(id);
        dictAppService.updateDictType(dto);
        return Result.ok();
    }

    @PreAuthorize("hasAuthority('dict:write')")
    @DeleteMapping({"/{id}", "/types/{id}"})
    public Result<Void> delete(@PathVariable Long id) {
        dictAppService.deleteDictType(id);
        return Result.ok();
    }

    @PreAuthorize("hasAuthority('dict:read')")
    @GetMapping({"/type/{dictType}", "/data/{dictType}"})
    public Result<List<SysDictData>> getDictDataByType(@PathVariable String dictType) {
        return Result.ok(dictAppService.getDictDataByType(dictType));
    }

    @PreAuthorize("hasAuthority('dict:write')")
    @PostMapping("/data")
    public Result<Long> createData(@RequestBody @Valid DictDataCreateDTO dto) {
        return Result.ok(dictAppService.createDictData(dto));
    }

    @PreAuthorize("hasAuthority('dict:write')")
    @PutMapping("/data/{id}")
    public Result<Void> updateData(@PathVariable Long id,
                                   @RequestBody @Valid DictDataUpdateDTO dto) {
        dto.setId(id);
        dictAppService.updateDictData(dto);
        return Result.ok();
    }

    @PreAuthorize("hasAuthority('dict:write')")
    @DeleteMapping("/data/{id}")
    public Result<Void> deleteData(@PathVariable Long id) {
        dictAppService.deleteDictData(id);
        return Result.ok();
    }
}
