package com.ljwx.platform.app.infra.mapper;

import com.ljwx.platform.app.domain.entity.SysNoticeUser;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

/**
 * 通知用户关联 MyBatis Mapper。
 */
@Mapper
public interface SysNoticeUserMapper {

    int insert(SysNoticeUser noticeUser);

    SysNoticeUser selectByNoticeAndUser(@Param("noticeId") Long noticeId,
                                        @Param("userId") Long userId);

    long countUnread(@Param("userId") Long userId);

    int updateReadTime(SysNoticeUser noticeUser);
}
