package com.ljwx.platform.app.infra.mapper;

import com.ljwx.platform.app.domain.vo.PermissionVO;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

/**
 * sys_permission Mapper（只读）。
 */
@Mapper
public interface SysPermissionMapper {

    /** 查询当前租户下全部权限（含 resource/action 计算列）。 */
    List<PermissionVO> selectAll();
}
