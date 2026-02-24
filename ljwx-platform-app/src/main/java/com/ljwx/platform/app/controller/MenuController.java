package com.ljwx.platform.app.controller;

import com.ljwx.platform.app.appservice.MenuAppService;
import com.ljwx.platform.app.domain.dto.MenuCreateDTO;
import com.ljwx.platform.app.domain.dto.MenuUpdateDTO;
import com.ljwx.platform.app.domain.vo.MenuTreeVO;
import com.ljwx.platform.app.domain.vo.MenuVO;
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

import java.util.List;

/**
 * 菜单管理 Controller。
 */
@RestController
@RequestMapping("/api/v1/menus")
@RequiredArgsConstructor
public class MenuController {

    private final MenuAppService menuAppService;

    @PreAuthorize("hasAuthority('system:menu:list')")
    @GetMapping
    public Result<List<MenuVO>> list() {
        return Result.ok(menuAppService.listMenus());
    }

    @PreAuthorize("hasAuthority('system:menu:list')")
    @GetMapping("/tree")
    public Result<List<MenuTreeVO>> tree() {
        return Result.ok(menuAppService.getMenuTree());
    }

    @PreAuthorize("hasAuthority('system:menu:detail')")
    @GetMapping("/{id}")
    public Result<MenuVO> getById(@PathVariable Long id) {
        return Result.ok(menuAppService.getMenu(id));
    }

    @PreAuthorize("hasAuthority('system:menu:create')")
    @PostMapping
    public Result<Long> create(@RequestBody @Valid MenuCreateDTO dto) {
        return Result.ok(menuAppService.createMenu(dto));
    }

    @PreAuthorize("hasAuthority('system:menu:update')")
    @PutMapping("/{id}")
    public Result<Void> update(@PathVariable Long id,
                               @RequestBody @Valid MenuUpdateDTO dto) {
        menuAppService.updateMenu(id, dto);
        return Result.ok();
    }

    @PreAuthorize("hasAuthority('system:menu:delete')")
    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        menuAppService.deleteMenu(id);
        return Result.ok();
    }
}
