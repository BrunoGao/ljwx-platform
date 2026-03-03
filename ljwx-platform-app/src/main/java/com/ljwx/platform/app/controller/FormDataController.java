package com.ljwx.platform.app.controller;

import com.ljwx.platform.app.dto.form.FormDataCreateDTO;
import com.ljwx.platform.app.dto.form.FormDataQueryDTO;
import com.ljwx.platform.app.dto.form.FormDataUpdateDTO;
import com.ljwx.platform.app.service.FormDataAppService;
import com.ljwx.platform.app.vo.form.FormDataVO;
import com.ljwx.platform.core.result.PageResult;
import com.ljwx.platform.core.result.Result;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

/**
 * Form data controller
 */
@RestController
@RequestMapping("/api/v1/form-data")
@RequiredArgsConstructor
public class FormDataController {

    private final FormDataAppService formDataAppService;

    /**
     * Paginated list of form data (metadata filtering only)
     */
    @PreAuthorize("hasAuthority('form:data:list')")
    @GetMapping
    public Result<PageResult<FormDataVO>> list(@Valid FormDataQueryDTO query) {
        PageResult<FormDataVO> result = formDataAppService.list(query);
        return Result.ok(result);
    }

    /**
     * Get form data by ID
     */
    @PreAuthorize("hasAuthority('form:data:query')")
    @GetMapping("/{id}")
    public Result<FormDataVO> getById(@PathVariable Long id) {
        FormDataVO vo = formDataAppService.getById(id);
        return Result.ok(vo);
    }

    /**
     * Submit form data
     */
    @PreAuthorize("hasAuthority('form:data:add')")
    @PostMapping
    public Result<Long> create(@Valid @RequestBody FormDataCreateDTO dto) {
        Long id = formDataAppService.create(dto);
        return Result.ok(id);
    }

    /**
     * Update form data
     */
    @PreAuthorize("hasAuthority('form:data:edit')")
    @PutMapping("/{id}")
    public Result<Void> update(@PathVariable Long id, @Valid @RequestBody FormDataUpdateDTO dto) {
        formDataAppService.update(id, dto);
        return Result.ok();
    }
}
