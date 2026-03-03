package com.ljwx.platform.app.controller;

import com.ljwx.platform.app.appservice.PostAppService;
import com.ljwx.platform.app.domain.dto.PostCreateDTO;
import com.ljwx.platform.app.domain.dto.PostQueryDTO;
import com.ljwx.platform.app.domain.dto.PostUpdateDTO;
import com.ljwx.platform.app.domain.vo.PostVO;
import com.ljwx.platform.core.result.Result;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 岗位管理 Controller
 */
@RestController
@RequestMapping("/api/v1/posts")
@RequiredArgsConstructor
public class PostController {

    private final PostAppService postAppService;

    /**
     * 查询岗位列表
     */
    @PreAuthorize("hasAuthority('system:post:list')")
    @GetMapping
    public Result<List<PostVO>> list(PostQueryDTO query) {
        List<PostVO> list = postAppService.list(query);
        return Result.ok(list);
    }

    /**
     * 根据 ID 查询岗位详情
     */
    @PreAuthorize("hasAuthority('system:post:query')")
    @GetMapping("/{id}")
    public Result<PostVO> getById(@PathVariable Long id) {
        PostVO postVO = postAppService.getById(id);
        return Result.ok(postVO);
    }

    /**
     * 创建岗位
     */
    @PreAuthorize("hasAuthority('system:post:add')")
    @PostMapping
    public Result<Long> create(@Valid @RequestBody PostCreateDTO dto) {
        Long id = postAppService.create(dto);
        return Result.ok(id);
    }

    /**
     * 更新岗位
     */
    @PreAuthorize("hasAuthority('system:post:edit')")
    @PutMapping("/{id}")
    public Result<Void> update(@PathVariable Long id, @Valid @RequestBody PostUpdateDTO dto) {
        postAppService.update(id, dto);
        return Result.ok();
    }

    /**
     * 删除岗位
     */
    @PreAuthorize("hasAuthority('system:post:delete')")
    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        postAppService.delete(id);
        return Result.ok();
    }
}
