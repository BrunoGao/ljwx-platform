package com.ljwx.platform.app.controller;

import com.ljwx.platform.app.appservice.NoticeAppService;
import com.ljwx.platform.app.domain.dto.NoticeCreateDTO;
import com.ljwx.platform.app.domain.dto.NoticeQueryDTO;
import com.ljwx.platform.app.domain.dto.NoticeUpdateDTO;
import com.ljwx.platform.app.domain.entity.SysNotice;
import com.ljwx.platform.core.result.PageResult;
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

/**
 * 系统通知/公告 Controller。
 * 权限按 spec/03-api.md §Notices 路由定义。
 *
 * <p>路由：
 * <ul>
 *   <li>GET  /api/notices       — notice:read  — 通知列表</li>
 *   <li>POST /api/notices        — notice:write — 发布通知</li>
 *   <li>PUT  /api/notices/{id}  — notice:write — 更新通知</li>
 * </ul>
 */
@RestController
@RequestMapping({"/api/v1/notices", "/api/notices"})
@RequiredArgsConstructor
public class NoticeController {

    private final NoticeAppService noticeAppService;

    /**
     * 查询通知/公告列表（分页）。
     */
    @PreAuthorize("hasAuthority('notice:read')")
    @GetMapping
    public Result<PageResult<SysNotice>> list(NoticeQueryDTO query) {
        return Result.ok(noticeAppService.listNotices(query));
    }

    /**
     * 发布通知/公告。
     */
    @PreAuthorize("hasAuthority('notice:write')")
    @PostMapping
    public Result<Long> create(@RequestBody @Valid NoticeCreateDTO dto) {
        return Result.ok(noticeAppService.createNotice(dto));
    }

    /**
     * 更新通知/公告。
     */
    @PreAuthorize("hasAuthority('notice:write')")
    @PutMapping("/{id}")
    public Result<Void> update(@PathVariable Long id,
                               @RequestBody @Valid NoticeUpdateDTO dto) {
        dto.setId(id);
        noticeAppService.updateNotice(dto);
        return Result.ok();
    }

    /**
     * 标记通知已读。
     */
    @PreAuthorize("hasAuthority('system:notice:read')")
    @PutMapping("/{id}/read")
    public Result<Void> markRead(@PathVariable Long id) {
        noticeAppService.markRead(id);
        return Result.ok();
    }

    /**
     * 获取通知详情。
     */
    @PreAuthorize("hasAuthority('notice:read')")
    @GetMapping("/{id}")
    public Result<SysNotice> getById(@PathVariable Long id) {
        return Result.ok(noticeAppService.getNotice(id));
    }

    /**
     * 删除通知。
     */
    @PreAuthorize("hasAuthority('notice:write')")
    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        noticeAppService.deleteNotice(id);
        return Result.ok();
    }

    /**
     * 获取当前用户未读通知数。
     */
    @PreAuthorize("hasAuthority('system:notice:list')")
    @GetMapping("/unread-count")
    public Result<Long> unreadCount() {
        return Result.ok(noticeAppService.getUnreadCount());
    }
}
