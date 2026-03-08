package com.ljwx.platform.app.appservice;

import com.ljwx.platform.app.domain.dto.TenantDomainCreateDTO;
import com.ljwx.platform.app.domain.entity.TenantDomain;
import com.ljwx.platform.app.domain.vo.TenantDomainVO;
import com.ljwx.platform.app.infra.mapper.TenantDomainMapper;
import com.ljwx.platform.core.result.ErrorCode;
import com.ljwx.platform.security.util.SecurityUtils;
import com.ljwx.platform.web.exception.BusinessException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.BeanUtils;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.naming.Context;
import javax.naming.NamingEnumeration;
import javax.naming.directory.Attribute;
import javax.naming.directory.Attributes;
import javax.naming.directory.DirContext;
import javax.naming.directory.InitialDirContext;
import java.util.Hashtable;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * 租户域名应用服务
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class TenantDomainAppService {

    private final TenantDomainMapper tenantDomainMapper;

    /**
     * 查询当前租户域名列表
     *
     * @return 域名列表
     */
    public List<TenantDomainVO> list() {
        List<TenantDomain> domains = tenantDomainMapper.selectList();
        return domains.stream()
                .map(this::toVO)
                .collect(Collectors.toList());
    }

    /**
     * 根据 ID 查询域名详情
     *
     * @param id 域名 ID
     * @return 域名 VO
     */
    public TenantDomainVO getById(Long id) {
        TenantDomain domain = tenantDomainMapper.selectById(id);
        if (domain == null || domain.getDeleted()) {
            throw new BusinessException(ErrorCode.DOMAIN_NOT_FOUND);
        }
        return toVO(domain);
    }

    /**
     * 根据域名查询（用于缓存）
     *
     * @param domain 域名
     * @return 租户域名实体
     */
    public TenantDomain getByDomain(String domain) {
        return tenantDomainMapper.selectByDomain(domain);
    }

    /**
     * 创建域名
     *
     * @param dto 创建 DTO
     * @return 域名 ID
     */
    @Transactional(rollbackFor = Exception.class)
    public Long create(TenantDomainCreateDTO dto) {
        // BL-43-01: 检查域名唯一性
        TenantDomain existing = tenantDomainMapper.selectByDomainIncludeDeleted(dto.getDomain());
        if (existing != null && !existing.getDeleted()) {
            throw new BusinessException(ErrorCode.DOMAIN_EXISTS);
        }

        // BL-43-03: 如果设置为主域名，取消其他主域名
        if (Boolean.TRUE.equals(dto.getIsPrimary())) {
            Long currentTenantId = SecurityUtils.getCurrentTenantId();
            if (currentTenantId != null) {
                tenantDomainMapper.clearPrimaryByTenantId(currentTenantId);
            }
        }

        TenantDomain domain = new TenantDomain();
        domain.setDomain(dto.getDomain());
        domain.setIsPrimary(dto.getIsPrimary());
        domain.setRemark(dto.getRemark());
        domain.setStatus("ENABLED");
        domain.setVerified(false);
        domain.setVerifyToken("ljwx-verify-" + UUID.randomUUID().toString().substring(0, 16));

        tenantDomainMapper.insert(domain);
        return domain.getId();
    }

    /**
     * 删除域名（软删除）
     *
     * @param id 域名 ID
     */
    @Transactional(rollbackFor = Exception.class)
    public void delete(Long id) {
        TenantDomain domain = tenantDomainMapper.selectById(id);
        if (domain == null || domain.getDeleted()) {
            throw new BusinessException(ErrorCode.DOMAIN_NOT_FOUND);
        }

        // BL-43-04: 禁止删除主域名
        if (Boolean.TRUE.equals(domain.getIsPrimary())) {
            throw new BusinessException(ErrorCode.CANNOT_DELETE_PRIMARY_DOMAIN);
        }

        domain.setDeleted(true);
        tenantDomainMapper.updateById(domain);
    }

    /**
     * 设置为主域名
     *
     * @param id 域名 ID
     */
    @Transactional(rollbackFor = Exception.class)
    public void setPrimary(Long id) {
        TenantDomain domain = tenantDomainMapper.selectById(id);
        if (domain == null || domain.getDeleted()) {
            throw new BusinessException(ErrorCode.DOMAIN_NOT_FOUND);
        }

        // BL-43-03: 取消当前租户其他主域名
        tenantDomainMapper.clearPrimaryByTenantId(domain.getTenantId());

        domain.setIsPrimary(true);
        tenantDomainMapper.updateById(domain);
    }

    /**
     * 验证域名
     *
     * @param id 域名 ID
     */
    @Transactional(rollbackFor = Exception.class)
    public void verify(Long id) {
        TenantDomain domain = tenantDomainMapper.selectById(id);
        if (domain == null || domain.getDeleted()) {
            throw new BusinessException(ErrorCode.DOMAIN_NOT_FOUND);
        }

        if (!hasMatchingVerifyRecord(domain.getDomain(), domain.getVerifyToken())) {
            throw new BusinessException(ErrorCode.DOMAIN_VERIFY_FAILED);
        }

        domain.setVerified(true);
        domain.setVerifiedTime(LocalDateTime.now());
        tenantDomainMapper.updateById(domain);
    }

    /**
     * 转换为 VO
     */
    private TenantDomainVO toVO(TenantDomain domain) {
        TenantDomainVO vo = new TenantDomainVO();
        BeanUtils.copyProperties(domain, vo);
        return vo;
    }

    private boolean hasMatchingVerifyRecord(String domain, String verifyToken) {
        String recordName = "_ljwx-verify." + domain;
        Hashtable<String, String> env = new Hashtable<>();
        env.put(Context.INITIAL_CONTEXT_FACTORY, "com.sun.jndi.dns.DnsContextFactory");

        DirContext context = null;
        try {
            context = new InitialDirContext(env);
            Attributes attributes = context.getAttributes(recordName, new String[]{"TXT"});
            Attribute txt = attributes.get("TXT");
            if (txt == null) {
                return false;
            }

            NamingEnumeration<?> values = txt.getAll();
            while (values.hasMore()) {
                String candidate = String.valueOf(values.next()).replace("\"", "").trim();
                if (verifyToken.equals(candidate)) {
                    return true;
                }
            }
            return false;
        } catch (Exception e) {
            log.warn("Tenant domain TXT lookup failed for {}: {}", recordName, e.getMessage());
            throw new BusinessException(ErrorCode.DOMAIN_VERIFY_FAILED);
        } finally {
            if (context != null) {
                try {
                    context.close();
                } catch (Exception ignored) {
                }
            }
        }
    }
}
