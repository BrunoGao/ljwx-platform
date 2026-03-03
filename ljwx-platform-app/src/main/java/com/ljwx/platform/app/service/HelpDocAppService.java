package com.ljwx.platform.app.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.ljwx.platform.app.domain.HelpDoc;
import com.ljwx.platform.app.dto.help.HelpDocCreateDTO;
import com.ljwx.platform.app.dto.help.HelpDocUpdateDTO;
import com.ljwx.platform.app.mapper.HelpDocMapper;
import com.ljwx.platform.app.vo.help.HelpDocVO;
import com.ljwx.platform.core.context.CurrentTenantHolder;
import com.ljwx.platform.core.context.CurrentUserHolder;
import com.ljwx.platform.core.exception.BusinessException;
import com.ljwx.platform.core.snowflake.SnowflakeIdGenerator;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.BeanUtils;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Help doc app service
 */
@Service
@RequiredArgsConstructor
public class HelpDocAppService {

    private final HelpDocMapper helpDocMapper;
    private final SnowflakeIdGenerator idGenerator;

    /**
     * List help docs by category
     *
     * @param category category (nullable)
     * @return help doc list
     */
    public List<HelpDocVO> listHelpDocs(String category) {
        Long tenantId = CurrentTenantHolder.get();
        if (tenantId == null) {
            tenantId = 0L;
        }

        List<HelpDoc> docs = helpDocMapper.listByCategory(category, tenantId);

        return docs.stream().map(doc -> {
            HelpDocVO vo = new HelpDocVO();
            BeanUtils.copyProperties(doc, vo);
            return vo;
        }).collect(Collectors.toList());
    }

    /**
     * Get help doc by ID
     *
     * @param id help doc ID
     * @return help doc VO
     */
    public HelpDocVO getById(Long id) {
        HelpDoc doc = helpDocMapper.selectById(id);
        if (doc == null) {
            throw new BusinessException("Help doc not found");
        }

        HelpDocVO vo = new HelpDocVO();
        BeanUtils.copyProperties(doc, vo);
        return vo;
    }

    /**
     * Get help doc by route match
     *
     * @param routePath route path
     * @return help doc VO (nullable)
     */
    public HelpDocVO getByRoute(String routePath) {
        Long tenantId = CurrentTenantHolder.get();
        if (tenantId == null) {
            tenantId = 0L;
        }

        HelpDoc doc = helpDocMapper.findByRouteMatch(routePath, tenantId);
        if (doc == null) {
            return null;
        }

        HelpDocVO vo = new HelpDocVO();
        BeanUtils.copyProperties(doc, vo);
        return vo;
    }

    /**
     * Create help doc
     *
     * @param dto create DTO
     * @return help doc ID
     */
    @Transactional
    public Long create(HelpDocCreateDTO dto) {
        HelpDoc doc = new HelpDoc();
        BeanUtils.copyProperties(dto, doc);

        doc.setId(idGenerator.nextId());
        doc.setStatus(1);
        doc.setCreatedBy(CurrentUserHolder.getUserId());
        doc.setCreatedTime(LocalDateTime.now());
        doc.setUpdatedBy(CurrentUserHolder.getUserId());
        doc.setUpdatedTime(LocalDateTime.now());
        doc.setDeleted(false);
        doc.setVersion(1);

        try {
            helpDocMapper.insert(doc);
        } catch (DuplicateKeyException e) {
            throw new BusinessException("Document key already exists");
        }

        return doc.getId();
    }

    /**
     * Update help doc
     *
     * @param id help doc ID
     * @param dto update DTO
     */
    @Transactional
    public void update(Long id, HelpDocUpdateDTO dto) {
        HelpDoc doc = helpDocMapper.selectById(id);
        if (doc == null) {
            throw new BusinessException("Help doc not found");
        }

        BeanUtils.copyProperties(dto, doc);
        doc.setUpdatedBy(CurrentUserHolder.getUserId());
        doc.setUpdatedTime(LocalDateTime.now());

        helpDocMapper.updateById(doc);
    }

    /**
     * Delete help doc
     *
     * @param id help doc ID
     */
    @Transactional
    public void delete(Long id) {
        HelpDoc doc = helpDocMapper.selectById(id);
        if (doc == null) {
            throw new BusinessException("Help doc not found");
        }

        doc.setDeleted(true);
        doc.setUpdatedBy(CurrentUserHolder.getUserId());
        doc.setUpdatedTime(LocalDateTime.now());

        helpDocMapper.updateById(doc);
    }
}
