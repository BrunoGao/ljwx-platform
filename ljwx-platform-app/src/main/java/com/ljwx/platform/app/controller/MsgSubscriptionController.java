package com.ljwx.platform.app.controller;

import com.ljwx.platform.app.dto.MsgSubscriptionDTO;
import com.ljwx.platform.app.dto.MsgSubscriptionQueryDTO;
import com.ljwx.platform.app.service.MsgSubscriptionService;
import com.ljwx.platform.app.vo.MsgSubscriptionVO;
import com.ljwx.platform.core.result.PageResult;
import com.ljwx.platform.core.result.Result;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

/**
 * 消息订阅控制器
 *
 * @author LJWX Platform
 * @since Phase 52
 */
@RestController
@RequestMapping("/api/v1/message/subscriptions")
@RequiredArgsConstructor
public class MsgSubscriptionController {

    private final MsgSubscriptionService msgSubscriptionService;

    /**
     * 创建订阅
     *
     * @param dto 订阅信息
     * @return 订阅 ID
     */
    @PreAuthorize("@ss.hasPermission('system:message:subscription:add')")
    @PostMapping
    public Result<Long> create(@Valid @RequestBody MsgSubscriptionDTO dto) {
        Long id = msgSubscriptionService.create(dto);
        return Result.ok(id);
    }

    /**
     * 更新订阅
     *
     * @param id  订阅 ID
     * @param dto 订阅信息
     * @return 成功响应
     */
    @PreAuthorize("@ss.hasPermission('system:message:subscription:edit')")
    @PutMapping("/{id}")
    public Result<Void> update(@PathVariable Long id, @Valid @RequestBody MsgSubscriptionDTO dto) {
        msgSubscriptionService.update(id, dto);
        return Result.ok();
    }

    /**
     * 删除订阅
     *
     * @param id 订阅 ID
     * @return 成功响应
     */
    @PreAuthorize("@ss.hasPermission('system:message:subscription:delete')")
    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        msgSubscriptionService.delete(id);
        return Result.ok();
    }

    /**
     * 查询订阅详情
     *
     * @param id 订阅 ID
     * @return 订阅详情
     */
    @PreAuthorize("@ss.hasPermission('system:message:subscription:query')")
    @GetMapping("/{id}")
    public Result<MsgSubscriptionVO> getById(@PathVariable Long id) {
        MsgSubscriptionVO vo = msgSubscriptionService.getById(id);
        return Result.ok(vo);
    }

    /**
     * 分页查询订阅列表
     *
     * @param query 查询条件
     * @return 分页结果
     */
    @PreAuthorize("@ss.hasPermission('system:message:subscription:list')")
    @GetMapping
    public Result<PageResult<MsgSubscriptionVO>> list(MsgSubscriptionQueryDTO query) {
        PageResult<MsgSubscriptionVO> result = msgSubscriptionService.list(query);
        return Result.ok(result);
    }

    /**
     * 更新订阅状态
     *
     * @param id     订阅 ID
     * @param status 新状态
     * @return 成功响应
     */
    @PreAuthorize("@ss.hasPermission('system:message:subscription:edit')")
    @PutMapping("/{id}/status")
    public Result<Void> updateStatus(@PathVariable Long id, @RequestParam String status) {
        msgSubscriptionService.updateStatus(id, status);
        return Result.ok();
    }
}
