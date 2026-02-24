package com.ljwx.platform.app.controller;

import com.ljwx.platform.app.appservice.UserAppService;
import com.ljwx.platform.app.domain.dto.UserCreateDTO;
import com.ljwx.platform.app.domain.dto.UserQueryDTO;
import com.ljwx.platform.app.domain.dto.UserUpdateDTO;
import com.ljwx.platform.app.domain.vo.UserVO;
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
 * 用户管理 Controller。
 */
@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final UserAppService userAppService;

    @PreAuthorize("hasAuthority('user:read')")
    @GetMapping
    public Result<PageResult<UserVO>> list(UserQueryDTO query) {
        return Result.ok(userAppService.listUsers(query));
    }

    @PreAuthorize("hasAuthority('user:read')")
    @GetMapping("/{id}")
    public Result<UserVO> getById(@PathVariable Long id) {
        return Result.ok(userAppService.getUser(id));
    }

    @PreAuthorize("hasAuthority('user:write')")
    @PostMapping
    public Result<Long> create(@RequestBody @Valid UserCreateDTO dto) {
        return Result.ok(userAppService.createUser(dto));
    }

    @PreAuthorize("hasAuthority('user:write')")
    @PutMapping("/{id}")
    public Result<Void> update(@PathVariable Long id,
                               @RequestBody @Valid UserUpdateDTO dto) {
        userAppService.updateUser(id, dto);
        return Result.ok();
    }

    @PreAuthorize("hasAuthority('user:delete')")
    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        userAppService.deleteUser(id);
        return Result.ok();
    }
}
