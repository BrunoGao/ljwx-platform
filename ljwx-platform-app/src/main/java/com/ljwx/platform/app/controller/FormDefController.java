package com.ljwx.platform.app.controller;

import com.ljwx.platform.app.dto.form.FormDefCreateDTO;
import com.ljwx.platform.app.dto.form.FormDefQueryDTO;
import com.ljwx.platform.app.dto.form.FormDefUpdateDTO;
import com.ljwx.platform.app.service.FormDefAppService;
import com.ljwx.platform.app.vo.form.FormDefVO;
import com.ljwx.platform.core.result.PageResult;
import com.ljwx.platform.core.result.Result;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

/**
 * Form definition controller
 */
@RestController
@RequestMapping("/api/v1/form-defs")
@RequiredArgsConstructor
public class FormDefController {

    private final FormDefAppService formDefAppService;

    /**
     * Paginated list of form definitions
     */
    @PreAuthorize("hasAuthority('form:def:list')")
    @GetMapping
    public Result<PageResult<FormDefVO>> list(FormDefQueryDTO query) {
        PageResult<FormDefVO> result = formDefAppService.list(query);
        return Result.ok(result);
    }

    /**
     * Get form definition by ID
     */
    @PreAuthorize("hasAuthority('form:def:query')")
    @GetMapping("/{id}")
    public Result<FormDefVO> getById(@PathVariable Long id) {
        FormDefVO vo = formDefAppService.getById(id);
        return Result.ok(vo);
    }

    /**
     * Create form definition
     */
    @PreAuthorize("hasAuthority('form:def:add')")
    @PostMapping
    public Result<Long> create(@Valid @RequestBody FormDefCreateDTO dto) {
        Long id = formDefAppService.create(dto);
        return Result.ok(id);
    }

    /**
     * Update form definition
     */
    @PreAuthorize("hasAuthority('form:def:edit')")
    @PutMapping("/{id}")
    public Result<Void> update(@PathVariable Long id, @Valid @RequestBody FormDefUpdateDTO dto) {
        formDefAppService.update(id, dto);
        return Result.ok();
    }

    /**
     * Delete form definition
     */
    @PreAuthorize("hasAuthority('form:def:delete')")
    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        formDefAppService.delete(id);
        return Result.ok();
    }
}
