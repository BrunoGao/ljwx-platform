package com.ljwx.platform.app.service;

import com.ljwx.platform.app.dto.MsgTemplateDTO;
import com.ljwx.platform.app.dto.MsgTemplateQueryDTO;
import com.ljwx.platform.app.infra.mapper.MsgTemplateMapper;
import com.ljwx.platform.app.vo.MsgTemplateVO;
import com.ljwx.platform.core.domain.MsgTemplate;
import com.ljwx.platform.core.result.ErrorCode;
import com.ljwx.platform.core.result.PageResult;
import com.ljwx.platform.web.exception.BusinessException;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.BeanUtils;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * 消息模板服务
 *
 * @author LJWX Platform
 * @since Phase 50
 */
@Service
@RequiredArgsConstructor
public class MsgTemplateService {

    private final MsgTemplateMapper msgTemplateMapper;

    /**
     * 创建消息模板
     *
     * @param dto 消息模板DTO
     * @return 模板ID
     */
    @Transactional(rollbackFor = Exception.class)
    public Long create(MsgTemplateDTO dto) {
        // 检查模板编码是否已存在
        MsgTemplate existing = msgTemplateMapper.selectByTemplateCode(dto.getTemplateCode());
        if (existing != null) {
            throw new BusinessException(ErrorCode.PARAM_VALIDATION_FAILED, "模板编码已存在: " + dto.getTemplateCode());
        }

        MsgTemplate template = new MsgTemplate();
        BeanUtils.copyProperties(dto, template);
        msgTemplateMapper.insert(template);
        return template.getId();
    }

    /**
     * 更新消息模板
     *
     * @param id  模板ID
     * @param dto 消息模板DTO
     */
    @Transactional(rollbackFor = Exception.class)
    public void update(Long id, MsgTemplateDTO dto) {
        MsgTemplate template = msgTemplateMapper.selectById(id);
        if (template == null) {
            throw new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "消息模板不存在");
        }

        // 检查模板编码是否与其他模板冲突
        if (!template.getTemplateCode().equals(dto.getTemplateCode())) {
            MsgTemplate existing = msgTemplateMapper.selectByTemplateCode(dto.getTemplateCode());
            if (existing != null && !existing.getId().equals(id)) {
                throw new BusinessException(ErrorCode.PARAM_VALIDATION_FAILED, "模板编码已存在: " + dto.getTemplateCode());
            }
        }

        BeanUtils.copyProperties(dto, template);
        msgTemplateMapper.updateById(template);
    }

    /**
     * 删除消息模板
     *
     * @param id 模板ID
     */
    @Transactional(rollbackFor = Exception.class)
    public void delete(Long id) {
        MsgTemplate template = msgTemplateMapper.selectById(id);
        if (template == null) {
            throw new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "消息模板不存在");
        }
        msgTemplateMapper.deleteById(id);
    }

    /**
     * 根据ID查询消息模板
     *
     * @param id 模板ID
     * @return 消息模板VO
     */
    public MsgTemplateVO getById(Long id) {
        MsgTemplate template = msgTemplateMapper.selectById(id);
        if (template == null) {
            throw new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "消息模板不存在");
        }

        MsgTemplateVO vo = new MsgTemplateVO();
        BeanUtils.copyProperties(template, vo);
        return vo;
    }

    /**
     * 分页查询消息模板列表
     *
     * @param query 查询条件
     * @return 分页结果
     */
    public PageResult<MsgTemplateVO> list(MsgTemplateQueryDTO query) {
        List<MsgTemplateVO> list = msgTemplateMapper.selectTemplateList(query);
        long total = msgTemplateMapper.countTemplates(query);
        return new PageResult<>(list, total);
    }

    /**
     * 根据模板编码查询
     *
     * @param templateCode 模板编码
     * @return 消息模板
     */
    public MsgTemplate getByTemplateCode(String templateCode) {
        return msgTemplateMapper.selectByTemplateCode(templateCode);
    }
}
