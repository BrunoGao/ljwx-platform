package com.ljwx.platform.app.appservice;

import com.ljwx.platform.app.domain.dto.NoticeCreateDTO;
import com.ljwx.platform.app.domain.dto.NoticeQueryDTO;
import com.ljwx.platform.app.domain.dto.NoticeUpdateDTO;
import com.ljwx.platform.app.domain.entity.SysNotice;
import com.ljwx.platform.app.domain.entity.SysNoticeUser;
import com.ljwx.platform.app.infra.mapper.SysNoticeMapper;
import com.ljwx.platform.app.infra.mapper.SysNoticeUserMapper;
import com.ljwx.platform.core.context.CurrentTenantHolder;
import com.ljwx.platform.core.context.CurrentUserHolder;
import com.ljwx.platform.core.id.SnowflakeIdGenerator;
import com.ljwx.platform.core.result.ErrorCode;
import com.ljwx.platform.core.result.PageResult;
import com.ljwx.platform.web.exception.BusinessException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 系统通知/公告应用服务。
 *
 * <p>tenant_id 由 TenantLineInterceptor（MyBatis Interceptor）自动注入，Service 层禁止手动设置。
 * 当通知状态变为"已发布"（status=1）时，自动设置 publish_time。
 */
@Service
@RequiredArgsConstructor
public class NoticeAppService {

    private final SysNoticeMapper noticeMapper;
    private final SysNoticeUserMapper noticeUserMapper;
    private final SnowflakeIdGenerator idGenerator;
    private final CurrentTenantHolder tenantHolder;
    private final CurrentUserHolder userHolder;

    /**
     * 分页查询通知列表。
     * TenantLineInterceptor 自动注入 tenant_id，无需手动设置。
     */
    public PageResult<SysNotice> listNotices(NoticeQueryDTO query) {
        List<SysNotice> records = noticeMapper.selectList(query);
        long total = noticeMapper.countList(query);
        return new PageResult<>(records, total);
    }

    /**
     * 创建通知/公告。
     * tenant_id 由 TenantLineInterceptor 自动注入，禁止手动设置。
     *
     * @param dto 创建参数
     * @return 新建通知的 ID
     */
    @Transactional
    public Long createNotice(NoticeCreateDTO dto) {
        long id = idGenerator.nextId();

        SysNotice notice = new SysNotice();
        notice.setId(id);
        notice.setNoticeTitle(dto.getNoticeTitle());
        notice.setNoticeType(dto.getNoticeType());
        notice.setNoticeContent(dto.getNoticeContent());

        int status = dto.getStatus() != null ? dto.getStatus() : 0;
        notice.setStatus(status);
        // 发布时设置发布时间
        if (status == 1) {
            notice.setPublishTime(LocalDateTime.now());
        }

        noticeMapper.insert(notice);
        return id;
    }

    /**
     * 更新通知/公告。
     * 当状态从草稿/撤回变为发布时，自动设置 publish_time。
     *
     * @param dto 更新参数
     */
    @Transactional
    public void updateNotice(NoticeUpdateDTO dto) {
        SysNotice existing = noticeMapper.selectById(dto.getId());
        if (existing == null) {
            throw new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "通知不存在");
        }

        if (dto.getNoticeTitle() != null) {
            existing.setNoticeTitle(dto.getNoticeTitle());
        }
        if (dto.getNoticeType() != null) {
            existing.setNoticeType(dto.getNoticeType());
        }
        if (dto.getNoticeContent() != null) {
            existing.setNoticeContent(dto.getNoticeContent());
        }
        if (dto.getStatus() != null) {
            existing.setStatus(dto.getStatus());
            // 首次发布：自动设置 publishTime
            if (dto.getStatus() == 1 && existing.getPublishTime() == null) {
                existing.setPublishTime(LocalDateTime.now());
            }
        }
        if (dto.getVersion() != null) {
            existing.setVersion(dto.getVersion());
        }

        noticeMapper.updateById(existing);
    }

    /**
     * 标记通知已读。若已有记录则更新 read_time，否则新建记录。
     */
    @Transactional
    public void markRead(Long noticeId) {
        Long userId = userHolder.getUserId();
        if (userId == null) return;
        SysNoticeUser existing = noticeUserMapper.selectByNoticeAndUser(noticeId, userId);
        if (existing != null) {
            if (existing.getReadTime() == null) {
                existing.setReadTime(LocalDateTime.now());
                noticeUserMapper.updateReadTime(existing);
            }
        } else {
            SysNoticeUser nu = new SysNoticeUser();
            nu.setId(idGenerator.nextId());
            nu.setNoticeId(noticeId);
            nu.setUserId(userId);
            nu.setReadTime(LocalDateTime.now());
            nu.setTenantId(tenantHolder.getTenantId());
            noticeUserMapper.insert(nu);
        }
    }

    /**
     * 获取当前用户未读通知数。
     */
    public long getUnreadCount() {
        Long userId = userHolder.getUserId();
        if (userId == null) return 0L;
        return noticeUserMapper.countUnread(userId);
    }
}
