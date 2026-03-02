package com.ljwx.platform.app.appservice;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.ljwx.platform.app.domain.dto.TenantBrandUpdateDTO;
import com.ljwx.platform.app.domain.entity.TenantBrand;
import com.ljwx.platform.app.domain.vo.TenantBrandVO;
import com.ljwx.platform.app.infra.mapper.TenantBrandMapper;
import com.ljwx.platform.app.util.CssSanitizer;
import com.ljwx.platform.core.context.CurrentTenantHolder;
import com.ljwx.platform.core.result.ErrorCode;
import com.ljwx.platform.web.exception.BusinessException;
import com.ljwx.platform.core.id.SnowflakeIdGenerator;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.BeanUtils;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

/**
 * 租户品牌配置应用服务
 *
 * @author LJWX Platform
 * @since Phase 38
 */
@Service
@RequiredArgsConstructor
public class TenantBrandAppService {

    private final TenantBrandMapper tenantBrandMapper;
    private final SnowflakeIdGenerator idGenerator;
    private final ObjectMapper objectMapper;
    private final CurrentTenantHolder currentTenantHolder;

    /**
     * 查询当前租户品牌配置
     *
     * @return 品牌配置 VO
     */
    public TenantBrandVO getBrand() {
        Long tenantId = currentTenantHolder.getTenantId();
        if (tenantId == null) {
            throw new BusinessException(ErrorCode.PARAM_VALIDATION_FAILED, "租户 ID 不能为空");
        }

        TenantBrand brand = tenantBrandMapper.selectByTenantId(tenantId);

        // 如果不存在，创建默认配置
        if (brand == null) {
            brand = createDefaultBrand(tenantId);
        }

        return toVO(brand);
    }

    /**
     * 更新品牌配置
     *
     * @param dto 更新 DTO
     */
    @Transactional
    public void updateBrand(TenantBrandUpdateDTO dto) {
        Long tenantId = currentTenantHolder.getTenantId();
        if (tenantId == null) {
            throw new BusinessException(ErrorCode.PARAM_VALIDATION_FAILED, "租户 ID 不能为空");
        }

        // 校验页脚链接数量
        if (dto.getFooterLinks() != null && dto.getFooterLinks().size() > 10) {
            throw new BusinessException(ErrorCode.PARAM_VALIDATION_FAILED, "页脚链接最多 10 个");
        }

        // 过滤自定义 CSS
        if (dto.getCustomCss() != null && !dto.getCustomCss().isBlank()) {
            String sanitizedCss = CssSanitizer.sanitize(dto.getCustomCss());
            dto.setCustomCss(sanitizedCss);
        }

        TenantBrand brand = tenantBrandMapper.selectByTenantId(tenantId);

        if (brand == null) {
            // 创建新配置
            brand = new TenantBrand();
            brand.setId(idGenerator.nextId());
            BeanUtils.copyProperties(dto, brand);

            // 转换 FooterLink 为 JSON
            if (dto.getFooterLinks() != null) {
                try {
                    brand.setFooterLinks(objectMapper.writeValueAsString(dto.getFooterLinks()));
                } catch (JsonProcessingException e) {
                    throw new BusinessException(ErrorCode.SYSTEM_ERROR, "页脚链接序列化失败");
                }
            }

            tenantBrandMapper.insert(brand);
        } else {
            // 更新配置
            BeanUtils.copyProperties(dto, brand);

            // 转换 FooterLink 为 JSON
            if (dto.getFooterLinks() != null) {
                try {
                    brand.setFooterLinks(objectMapper.writeValueAsString(dto.getFooterLinks()));
                } catch (JsonProcessingException e) {
                    throw new BusinessException(ErrorCode.SYSTEM_ERROR, "页脚链接序列化失败");
                }
            }

            tenantBrandMapper.updateById(brand);
        }
    }

    /**
     * 创建默认品牌配置
     *
     * @param tenantId 租户 ID
     * @return 默认品牌配置
     */
    @Transactional
    protected TenantBrand createDefaultBrand(Long tenantId) {
        TenantBrand brand = new TenantBrand();
        brand.setId(idGenerator.nextId());
        brand.setBrandName("LJWX Platform");
        brand.setLogoUrl("/assets/logo.png");
        brand.setFaviconUrl("/assets/favicon.ico");
        brand.setPrimaryColor("#1890ff");
        brand.setSecondaryColor("#52c41a");
        brand.setBackgroundColor("#f0f2f5");
        brand.setLoginBgUrl("/assets/login-bg.jpg");
        brand.setLoginSlogan("智能化企业管理平台");
        brand.setCopyrightText("Copyright © 2026 LJWX Platform. All rights reserved.");
        brand.setFooterLinks("[]");

        tenantBrandMapper.insert(brand);
        return brand;
    }

    /**
     * 转换为 VO
     *
     * @param brand 实体
     * @return VO
     */
    private TenantBrandVO toVO(TenantBrand brand) {
        TenantBrandVO vo = new TenantBrandVO();
        BeanUtils.copyProperties(brand, vo);

        // 转换 FooterLink JSON 为对象
        if (brand.getFooterLinks() != null && !brand.getFooterLinks().isBlank()) {
            try {
                List<TenantBrandVO.FooterLinkVO> links = objectMapper.readValue(
                    brand.getFooterLinks(),
                    new TypeReference<List<TenantBrandVO.FooterLinkVO>>() {}
                );
                vo.setFooterLinks(links);
            } catch (JsonProcessingException e) {
                vo.setFooterLinks(new ArrayList<>());
            }
        } else {
            vo.setFooterLinks(new ArrayList<>());
        }

        return vo;
    }
}
