package com.ljwx.platform.app.appservice;

import com.ljwx.platform.app.domain.dto.MenuCreateDTO;
import com.ljwx.platform.app.domain.dto.MenuUpdateDTO;
import com.ljwx.platform.app.domain.entity.SysMenu;
import com.ljwx.platform.app.domain.vo.MenuTreeVO;
import com.ljwx.platform.app.domain.vo.MenuVO;
import com.ljwx.platform.app.infra.mapper.SysMenuMapper;
import com.ljwx.platform.core.context.CurrentTenantHolder;
import com.ljwx.platform.core.id.SnowflakeIdGenerator;
import com.ljwx.platform.core.result.ErrorCode;
import com.ljwx.platform.web.exception.BusinessException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Comparator;
import java.util.List;
import java.util.stream.Collectors;

/**
 * 菜单应用服务（CRUD + 树形构建）。
 *
 * <p>tenant_id 不在 DTO 中传递，由 TenantLineInterceptor 自动注入 SELECT 查询，
 * INSERT 时由 CurrentTenantHolder 手动设置到实体上。
 */
@Service
@RequiredArgsConstructor
public class MenuAppService {

    private final SysMenuMapper menuMapper;
    private final SnowflakeIdGenerator idGenerator;
    private final CurrentTenantHolder tenantHolder;

    public List<MenuVO> listMenus() {
        return menuMapper.selectAll().stream()
                .map(this::toVO)
                .collect(Collectors.toList());
    }

    public List<MenuTreeVO> getMenuTree() {
        List<MenuTreeVO> all = menuMapper.selectAll().stream()
                .map(this::toTreeVO)
                .collect(Collectors.toList());
        return buildTree(all, 0L);
    }

    public MenuVO getMenu(Long id) {
        SysMenu menu = menuMapper.selectById(id);
        if (menu == null) {
            throw new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "菜单不存在");
        }
        return toVO(menu);
    }

    @Transactional
    public Long createMenu(MenuCreateDTO dto) {
        long id = idGenerator.nextId();
        SysMenu menu = new SysMenu();
        menu.setId(id);
        menu.setTenantId(tenantHolder.getTenantId());
        menu.setParentId(dto.getParentId());
        menu.setName(dto.getName());
        menu.setPath(dto.getPath() != null ? dto.getPath() : "");
        menu.setComponent(dto.getComponent() != null ? dto.getComponent() : "");
        menu.setIcon(dto.getIcon() != null ? dto.getIcon() : "");
        menu.setSort(dto.getSort() != null ? dto.getSort() : 0);
        menu.setMenuType(dto.getMenuType());
        menu.setPermission(dto.getPermission() != null ? dto.getPermission() : "");
        menu.setVisible(dto.getVisible() != null ? dto.getVisible() : 1);
        menuMapper.insert(menu);
        return id;
    }

    @Transactional
    public void updateMenu(Long id, MenuUpdateDTO dto) {
        SysMenu menu = menuMapper.selectById(id);
        if (menu == null) {
            throw new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "菜单不存在");
        }
        if (dto.getParentId()   != null) { menu.setParentId(dto.getParentId());     }
        if (dto.getName()       != null) { menu.setName(dto.getName());             }
        if (dto.getPath()       != null) { menu.setPath(dto.getPath());             }
        if (dto.getComponent()  != null) { menu.setComponent(dto.getComponent());   }
        if (dto.getIcon()       != null) { menu.setIcon(dto.getIcon());             }
        if (dto.getSort()       != null) { menu.setSort(dto.getSort());             }
        if (dto.getMenuType()   != null) { menu.setMenuType(dto.getMenuType());     }
        if (dto.getPermission() != null) { menu.setPermission(dto.getPermission()); }
        if (dto.getVisible()    != null) { menu.setVisible(dto.getVisible());       }
        if (dto.getVersion()    != null) { menu.setVersion(dto.getVersion());       }
        menuMapper.updateById(menu);
    }

    @Transactional
    public void deleteMenu(Long id) {
        menuMapper.deleteById(id);
    }

    // ─── private helpers ────────────────────────────────────────────────────

    private List<MenuTreeVO> buildTree(List<MenuTreeVO> all, Long parentId) {
        List<MenuTreeVO> nodes = all.stream()
                .filter(m -> parentId.equals(m.getParentId()))
                .sorted(Comparator.comparingInt(m -> m.getSort() != null ? m.getSort() : 0))
                .collect(Collectors.toList());
        nodes.forEach(m -> m.setChildren(buildTree(all, m.getId())));
        return nodes;
    }

    private MenuVO toVO(SysMenu m) {
        MenuVO vo = new MenuVO();
        vo.setId(m.getId());
        vo.setParentId(m.getParentId());
        vo.setName(m.getName());
        vo.setPath(m.getPath());
        vo.setComponent(m.getComponent());
        vo.setIcon(m.getIcon());
        vo.setSort(m.getSort());
        vo.setMenuType(m.getMenuType());
        vo.setPermission(m.getPermission());
        vo.setVisible(m.getVisible());
        vo.setCreatedTime(m.getCreatedTime());
        vo.setUpdatedTime(m.getUpdatedTime());
        return vo;
    }

    private MenuTreeVO toTreeVO(SysMenu m) {
        MenuTreeVO vo = new MenuTreeVO();
        vo.setId(m.getId());
        vo.setParentId(m.getParentId());
        vo.setName(m.getName());
        vo.setPath(m.getPath());
        vo.setComponent(m.getComponent());
        vo.setIcon(m.getIcon());
        vo.setSort(m.getSort());
        vo.setMenuType(m.getMenuType());
        vo.setPermission(m.getPermission());
        vo.setVisible(m.getVisible());
        return vo;
    }
}
