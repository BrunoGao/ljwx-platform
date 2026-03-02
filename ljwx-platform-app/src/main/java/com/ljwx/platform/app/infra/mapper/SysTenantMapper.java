package com.ljwx.platform.app.infra.mapper;

import com.ljwx.platform.app.domain.entity.SysTenant;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.time.LocalDateTime;

/**
 * 租户 MyBatis Mapper。
 */
@Mapper
public interface SysTenantMapper {

    int insert(SysTenant tenant);

    int updateById(SysTenant tenant);

    SysTenant selectById(Long id);

    /**
     * 更新租户生命周期状态为 FROZEN。
     *
     * @param id           租户 ID
     * @param reason       冻结原因
     * @param frozenTime   冻结时间
     * @return 更新行数
     */
    int updateToFrozen(@Param("id") Long id,
                       @Param("reason") String reason,
                       @Param("frozenTime") LocalDateTime frozenTime);

    /**
     * 更新租户生命周期状态为 ACTIVE（解冻）。
     *
     * @param id 租户 ID
     * @return 更新行数
     */
    int updateToActive(@Param("id") Long id);

    /**
     * 更新租户生命周期状态为 CANCELLED。
     *
     * @param id              租户 ID
     * @param reason          注销原因
     * @param cancelledTime   注销时间
     * @return 更新行数
     */
    int updateToCancelled(@Param("id") Long id,
                          @Param("reason") String reason,
                          @Param("cancelledTime") LocalDateTime cancelledTime);
}
