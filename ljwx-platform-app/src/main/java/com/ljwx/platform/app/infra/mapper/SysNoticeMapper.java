package com.ljwx.platform.app.infra.mapper;

import com.ljwx.platform.app.domain.dto.NoticeQueryDTO;
import com.ljwx.platform.app.domain.entity.SysNotice;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

/**
 * 系统通知 MyBatis Mapper。
 * TenantLineInterceptor 自动追加 WHERE tenant_id = ? 到所有 SELECT。
 */
@Mapper
public interface SysNoticeMapper {

    int insert(SysNotice notice);

    int updateById(SysNotice notice);

    SysNotice selectById(Long id);

    List<SysNotice> selectList(NoticeQueryDTO query);

    long countList(NoticeQueryDTO query);

    int deleteById(Long id);
}
