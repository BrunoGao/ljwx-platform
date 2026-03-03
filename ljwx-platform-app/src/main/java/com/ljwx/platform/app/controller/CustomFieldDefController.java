package com.ljwx.platform.app.controller;

import com.ljwx.platform.app.dto.form.CustomFieldDefCreateDTO;
import com.ljwx.platform.app.dto.form.CustomFieldDefUpdateDTO;
import com.ljwx.platform.app.service.CustomFieldDefAppService;
import com.ljwx.platform.app.vo.form.CustomFieldDefVO;
import com.ljwx.platform.core.result.Result;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Custom field definition controller
 */
@RestController
@RequestMapping("/api/v1/custom-fields")
@RequiredArgsConstructor
public class CustomFieldDefController {

    private final CustomFieldDefAppService customFieldDefAppService;

    /**
     * List custom fields by entity type
     */
    @PreAuthorize("hasAuthority('system:customfield:list')")
    @GetMapping
    public Result<List<CustomFieldDefVO>> list(@RequestParam String entityType) {
        List<CustomFieldDefVO> list = customFieldDefAppService.listByEntityType(entityType);
        return Result.ok(list);
    }

    /**
     * Create custom field definition
     */
    @PreAuthorize("hasAuthority('system:customfield:add')")
    @PostMapping
    public Result<Long> create(@Valid @RequestBody CustomFieldDefCreateDTO dto) {
        Long id = customFieldDefAppService.create(dto);
        return Result.ok(id);
    }

    /**
     * Update custom field definition
     */
    @PreAuthorize("hasAuthority('system:customfield:edit')")
    @PutMapping("/{id}")
    public Result<Void> update(@PathVariable Long id, @Valid @RequestBody CustomFieldDefUpdateDTO dto) {
        customFieldDefAppService.update(id, dto);
        return Result.ok();
    }

    /**
     * Delete custom field definition
     */
    @PreAuthorize("hasAuthority('system:customfield:delete')")
    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        customFieldDefAppService.delete(id);
        return Result.ok();
    }
}
