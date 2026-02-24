package com.ljwx.platform.app.appservice;

import com.ljwx.platform.app.domain.dto.TenantPackageCreateDTO;
import com.ljwx.platform.app.domain.dto.TenantPackageQueryDTO;
import com.ljwx.platform.app.domain.dto.TenantPackageUpdateDTO;
import com.ljwx.platform.app.domain.entity.SysTenantPackage;
import com.ljwx.platform.app.domain.vo.TenantPackageVO;
import com.ljwx.platform.app.infra.mapper.SysTenantPackageMapper;
import com.ljwx.platform.core.context.CurrentTenantHolder;
import com.ljwx.platform.core.id.SnowflakeIdGenerator;
import com.ljwx.platform.core.result.ErrorCode;
import com.ljwx.platform.core.result.PageResult;
import com.ljwx.platform.web.exception.BusinessException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

/**
 * 租户套餐应用服务。
 *
 * <p>tenant_id 不在 DTO 中传递，INSERT 时由 CurrentTenantHolder 注入，
 * SELECT 时由 TenantLineInterceptor 自动追加。
 */
@Service
@RequiredArgsConstructor
public class TenantPackageAppService {

    private final SysTenantPackageMapper packageMapper;
    private final SnowflakeIdGenerator idGenerator;
    private final CurrentTenantHolder tenantHolder;

    public PageResult<TenantPackageVO> listPackages(TenantPackageQueryDTO query) {
        List<TenantPackageVO> rows = packageMapper.selectList(query).stream()
                .map(this::toVO)
                .collect(Collectors.toList());
        long total = packageMapper.countList(query);
        return new PageResult<>(rows, total);
    }

    public TenantPackageVO getPackage(Long id) {
        SysTenantPackage pkg = packageMapper.selectById(id);
        if (pkg == null) {
            throw new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "套餐不存在");
        }
        return toVO(pkg);
    }

    @Transactional
    public Long createPackage(TenantPackageCreateDTO dto) {
        long id = idGenerator.nextId();
        SysTenantPackage pkg = new SysTenantPackage();
        pkg.setId(id);
        pkg.setTenantId(tenantHolder.getTenantId());
        pkg.setName(dto.getName());
        pkg.setMenuIds(dto.getMenuIds() != null ? dto.getMenuIds() : "");
        pkg.setMaxUsers(dto.getMaxUsers() != null ? dto.getMaxUsers() : 100);
        pkg.setMaxStorageMb(dto.getMaxStorageMb() != null ? dto.getMaxStorageMb() : 1024);
        pkg.setStatus(1);
        packageMapper.insert(pkg);
        return id;
    }

    @Transactional
    public void updatePackage(Long id, TenantPackageUpdateDTO dto) {
        SysTenantPackage pkg = packageMapper.selectById(id);
        if (pkg == null) {
            throw new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "套餐不存在");
        }
        if (dto.getName()         != null) { pkg.setName(dto.getName());               }
        if (dto.getMenuIds()      != null) { pkg.setMenuIds(dto.getMenuIds());         }
        if (dto.getMaxUsers()     != null) { pkg.setMaxUsers(dto.getMaxUsers());       }
        if (dto.getMaxStorageMb() != null) { pkg.setMaxStorageMb(dto.getMaxStorageMb()); }
        if (dto.getStatus()       != null) { pkg.setStatus(dto.getStatus());           }
        if (dto.getVersion()      != null) { pkg.setVersion(dto.getVersion());         }
        packageMapper.updateById(pkg);
    }

    @Transactional
    public void deletePackage(Long id) {
        packageMapper.deleteById(id);
    }

    // ─── private helpers ────────────────────────────────────────────────────

    private TenantPackageVO toVO(SysTenantPackage pkg) {
        TenantPackageVO vo = new TenantPackageVO();
        vo.setId(pkg.getId());
        vo.setName(pkg.getName());
        vo.setMenuIds(pkg.getMenuIds());
        vo.setMaxUsers(pkg.getMaxUsers());
        vo.setMaxStorageMb(pkg.getMaxStorageMb());
        vo.setStatus(pkg.getStatus());
        vo.setCreatedTime(pkg.getCreatedTime());
        vo.setUpdatedTime(pkg.getUpdatedTime());
        return vo;
    }
}
