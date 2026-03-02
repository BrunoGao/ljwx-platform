package com.ljwx.platform.app.controller;

import com.ljwx.platform.app.appservice.TenantBrandAppService;
import com.ljwx.platform.app.domain.dto.TenantBrandUpdateDTO;
import com.ljwx.platform.app.domain.vo.TenantBrandVO;
import com.ljwx.platform.core.result.Result;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

/**
 * 租户品牌配置控制器
 *
 * @author LJWX Platform
 * @since Phase 38
 */
@RestController
@RequestMapping("/api/v1/tenant/brand")
@RequiredArgsConstructor
public class TenantBrandController {

    private final TenantBrandAppService tenantBrandAppService;

    /**
     * 查询当前租户品牌配置
     *
     * @return 品牌配置 VO
     */
    @PreAuthorize("hasAuthority('tenant:brand:list')")
    @GetMapping
    public Result<TenantBrandVO> getBrand() {
        TenantBrandVO vo = tenantBrandAppService.getBrand();
        return Result.ok(vo);
    }

    /**
     * 更新品牌配置
     *
     * @param dto 更新 DTO
     * @return 成功响应
     */
    @PreAuthorize("hasAuthority('tenant:brand:edit')")
    @PutMapping
    public Result<Void> updateBrand(@Valid @RequestBody TenantBrandUpdateDTO dto) {
        tenantBrandAppService.updateBrand(dto);
        return Result.ok();
    }
}
