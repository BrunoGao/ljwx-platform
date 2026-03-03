package com.ljwx.platform.app.controller;

import com.ljwx.platform.app.dto.help.HelpDocCreateDTO;
import com.ljwx.platform.app.dto.help.HelpDocUpdateDTO;
import com.ljwx.platform.app.service.HelpDocAppService;
import com.ljwx.platform.app.vo.help.HelpDocVO;
import com.ljwx.platform.web.result.Result;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Help doc controller
 */
@RestController
@RequestMapping("/api/v1/help-docs")
@RequiredArgsConstructor
public class HelpDocController {

    private final HelpDocAppService helpDocAppService;

    /**
     * List help docs
     *
     * @param category category (optional)
     * @return help doc list
     */
    @PreAuthorize("hasAuthority('system:help:list')")
    @GetMapping
    public Result<List<HelpDocVO>> list(@RequestParam(required = false) String category) {
        List<HelpDocVO> docs = helpDocAppService.listHelpDocs(category);
        return Result.ok(docs);
    }

    /**
     * Get help doc by ID
     *
     * @param id help doc ID
     * @return help doc VO
     */
    @PreAuthorize("hasAuthority('system:help:query')")
    @GetMapping("/{id}")
    public Result<HelpDocVO> getById(@PathVariable Long id) {
        HelpDocVO doc = helpDocAppService.getById(id);
        return Result.ok(doc);
    }

    /**
     * Get help doc by route (public endpoint, no authentication required)
     * Note: This endpoint is configured as permitAll in SecurityConfig
     *
     * @param path route path
     * @return help doc VO
     */
    @GetMapping("/route")
    public Result<HelpDocVO> getByRoute(@RequestParam String path) {
        HelpDocVO doc = helpDocAppService.getByRoute(path);
        return Result.ok(doc);
    }

    /**
     * Create help doc
     *
     * @param dto create DTO
     * @return help doc ID
     */
    @PreAuthorize("hasAuthority('system:help:add')")
    @PostMapping
    public Result<Long> create(@Valid @RequestBody HelpDocCreateDTO dto) {
        Long id = helpDocAppService.create(dto);
        return Result.ok(id);
    }

    /**
     * Update help doc
     *
     * @param id help doc ID
     * @param dto update DTO
     * @return success result
     */
    @PreAuthorize("hasAuthority('system:help:edit')")
    @PutMapping("/{id}")
    public Result<Void> update(@PathVariable Long id, @Valid @RequestBody HelpDocUpdateDTO dto) {
        helpDocAppService.update(id, dto);
        return Result.ok();
    }

    /**
     * Delete help doc
     *
     * @param id help doc ID
     * @return success result
     */
    @PreAuthorize("hasAuthority('system:help:delete')")
    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        helpDocAppService.delete(id);
        return Result.ok();
    }
}
