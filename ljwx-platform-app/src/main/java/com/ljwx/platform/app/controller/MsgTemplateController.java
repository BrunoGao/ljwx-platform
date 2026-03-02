package com.ljwx.platform.app.controller;

import com.ljwx.platform.app.dto.MsgTemplateDTO;
import com.ljwx.platform.app.dto.MsgTemplateQueryDTO;
import com.ljwx.platform.app.service.MsgTemplateService;
import com.ljwx.platform.app.vo.MsgTemplateVO;
import com.ljwx.platform.core.result.PageResult;
import com.ljwx.platform.core.result.Result;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

/**
 * 消息模板控制器
 *
 * @author LJWX Platform
 * @since Phase 50
 */
@RestController
@RequestMapping("/api/v1/messages/templates")
@RequiredArgsConstructor
public class MsgTemplateController {

    private final MsgTemplateService msgTemplateService;

    /**
     * 创建消息模板
     *
     * @param dto 消息模板DTO
     * @return 模板ID
     */
    @PreAuthorize("hasAuthority('system:message:template:add')")
    @PostMapping
    public Result<Long> create(@Valid @RequestBody MsgTemplateDTO dto) {
        Long id = msgTemplateService.create(dto);
        return Result.ok(id);
    }

    /**
     * 更新消息模板
     *
     * @param id  模板ID
     * @param dto 消息模板DTO
     * @return 成功响应
     */
    @PreAuthorize("hasAuthority('system:message:template:edit')")
    @PutMapping("/{id}")
    public Result<Void> update(@PathVariable Long id, @Valid @RequestBody MsgTemplateDTO dto) {
        msgTemplateService.update(id, dto);
        return Result.ok();
    }

    /**
     * 删除消息模板
     *
     * @param id ���板ID
     * @return 成功响应
     */
    @PreAuthorize("hasAuthority('system:message:template:delete')")
    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        msgTemplateService.delete(id);
        return Result.ok();
    }

    /**
     * 查询消息模板详情
     *
     * @param id 模板ID
     * @return 消息模板VO
     */
    @PreAuthorize("hasAuthority('system:message:template:query')")
    @GetMapping("/{id}")
    public Result<MsgTemplateVO> getById(@PathVariable Long id) {
        MsgTemplateVO vo = msgTemplateService.getById(id);
        return Result.ok(vo);
    }

    /**
     * 分页查询消息模板列表
     *
     * @param query 查询条件
     * @return 分页结果
     */
    @PreAuthorize("hasAuthority('system:message:template:list')")
    @GetMapping
    public Result<PageResult<MsgTemplateVO>> list(MsgTemplateQueryDTO query) {
        PageResult<MsgTemplateVO> result = msgTemplateService.list(query);
        return Result.ok(result);
    }
}
