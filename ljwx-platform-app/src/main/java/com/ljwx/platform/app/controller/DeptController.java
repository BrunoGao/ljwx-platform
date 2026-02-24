package com.ljwx.platform.app.controller;

import com.ljwx.platform.app.appservice.DeptAppService;
import com.ljwx.platform.app.domain.dto.DeptCreateDTO;
import com.ljwx.platform.app.domain.dto.DeptQueryDTO;
import com.ljwx.platform.app.domain.dto.DeptUpdateDTO;
import com.ljwx.platform.app.domain.vo.DeptTreeVO;
import com.ljwx.platform.app.domain.vo.DeptVO;
import com.ljwx.platform.core.result.Result;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * 部门管理 Controller。
 * 权限按 spec/phase/phase-21.md §API 路由定义。
 */
@RestController
@RequestMapping("/api/v1/depts")
@RequiredArgsConstructor
public class DeptController {

    private final DeptAppService deptAppService;

    @PreAuthorize("hasAuthority('system:dept:list')")
    @GetMapping
    public Result<List<DeptVO>> list(DeptQueryDTO query) {
        return Result.ok(deptAppService.listDepts(query));
    }

    @PreAuthorize("hasAuthority('system:dept:list')")
    @GetMapping("/tree")
    public Result<List<DeptTreeVO>> tree() {
        return Result.ok(deptAppService.getDeptTree());
    }

    @PreAuthorize("hasAuthority('system:dept:detail')")
    @GetMapping("/{id}")
    public Result<DeptVO> getById(@PathVariable Long id) {
        return Result.ok(deptAppService.getDeptById(id));
    }

    @PreAuthorize("hasAuthority('system:dept:create')")
    @PostMapping
    public Result<Long> create(@RequestBody @Valid DeptCreateDTO dto) {
        return Result.ok(deptAppService.createDept(dto));
    }

    @PreAuthorize("hasAuthority('system:dept:update')")
    @PutMapping("/{id}")
    public Result<Void> update(@PathVariable Long id,
                               @RequestBody @Valid DeptUpdateDTO dto) {
        deptAppService.updateDept(id, dto);
        return Result.ok();
    }

    @PreAuthorize("hasAuthority('system:dept:delete')")
    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        deptAppService.deleteDept(id);
        return Result.ok();
    }
}
