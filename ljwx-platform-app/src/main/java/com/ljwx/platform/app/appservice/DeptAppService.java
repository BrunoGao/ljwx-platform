package com.ljwx.platform.app.appservice;

import com.ljwx.platform.app.domain.dto.DeptCreateDTO;
import com.ljwx.platform.app.domain.dto.DeptQueryDTO;
import com.ljwx.platform.app.domain.dto.DeptUpdateDTO;
import com.ljwx.platform.app.domain.entity.SysDept;
import com.ljwx.platform.app.domain.vo.DeptTreeVO;
import com.ljwx.platform.app.domain.vo.DeptVO;
import com.ljwx.platform.app.infra.mapper.SysDeptMapper;
import com.ljwx.platform.core.context.CurrentTenantHolder;
import com.ljwx.platform.core.id.SnowflakeIdGenerator;
import com.ljwx.platform.core.result.ErrorCode;
import com.ljwx.platform.web.exception.BusinessException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 部门应用服务。
 * INSERT 时 tenant_id 由 CurrentTenantHolder 注入；SELECT 由 TenantLineInterceptor 自动过滤。
 */
@Service
@RequiredArgsConstructor
public class DeptAppService {

    private final SysDeptMapper deptMapper;
    private final SnowflakeIdGenerator idGenerator;
    private final CurrentTenantHolder tenantHolder;

    public List<DeptVO> listDepts(DeptQueryDTO query) {
        List<SysDept> depts = deptMapper.selectList(query);
        return depts.stream().map(this::toVO).collect(Collectors.toList());
    }

    public List<DeptTreeVO> getDeptTree() {
        List<SysDept> all = deptMapper.selectAll();
        return buildTree(all, 0L);
    }

    public DeptVO getDeptById(Long id) {
        SysDept dept = deptMapper.selectById(id);
        if (dept == null) {
            throw new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "部门不存在: " + id);
        }
        return toVO(dept);
    }

    @Transactional
    public Long createDept(DeptCreateDTO dto) {
        long id = idGenerator.nextId();
        SysDept dept = new SysDept();
        dept.setId(id);
        dept.setTenantId(tenantHolder.getTenantId());
        dept.setParentId(dto.getParentId());
        dept.setName(dto.getName());
        dept.setSort(dto.getSort() != null ? dto.getSort() : 0);
        dept.setLeader(dto.getLeader() != null ? dto.getLeader() : "");
        dept.setPhone(dto.getPhone() != null ? dto.getPhone() : "");
        dept.setEmail(dto.getEmail() != null ? dto.getEmail() : "");
        dept.setStatus(dto.getStatus() != null ? dto.getStatus() : 1);
        deptMapper.insert(dept);
        return id;
    }

    @Transactional
    public void updateDept(Long id, DeptUpdateDTO dto) {
        SysDept existing = deptMapper.selectById(id);
        if (existing == null) {
            throw new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "部门不存在: " + id);
        }
        existing.setParentId(dto.getParentId());
        existing.setName(dto.getName());
        if (dto.getSort() != null) existing.setSort(dto.getSort());
        if (dto.getLeader() != null) existing.setLeader(dto.getLeader());
        if (dto.getPhone() != null) existing.setPhone(dto.getPhone());
        if (dto.getEmail() != null) existing.setEmail(dto.getEmail());
        if (dto.getStatus() != null) existing.setStatus(dto.getStatus());
        existing.setVersion(dto.getVersion());
        deptMapper.updateById(existing);
    }

    @Transactional
    public void deleteDept(Long id) {
        long childCount = deptMapper.countChildren(id);
        if (childCount > 0) {
            throw new BusinessException(ErrorCode.PARAM_VALIDATION_FAILED, "存在子部门，无法删除");
        }
        deptMapper.deleteById(id);
    }

    private DeptVO toVO(SysDept dept) {
        DeptVO vo = new DeptVO();
        vo.setId(dept.getId());
        vo.setParentId(dept.getParentId());
        vo.setName(dept.getName());
        vo.setSort(dept.getSort());
        vo.setLeader(dept.getLeader());
        vo.setPhone(dept.getPhone());
        vo.setEmail(dept.getEmail());
        vo.setStatus(dept.getStatus());
        vo.setCreatedTime(dept.getCreatedTime());
        vo.setUpdatedTime(dept.getUpdatedTime());
        vo.setVersion(dept.getVersion());
        return vo;
    }

    private List<DeptTreeVO> buildTree(List<SysDept> all, Long parentId) {
        Map<Long, List<SysDept>> byParent = all.stream()
                .collect(Collectors.groupingBy(SysDept::getParentId));
        return buildChildren(byParent, parentId);
    }

    private List<DeptTreeVO> buildChildren(Map<Long, List<SysDept>> byParent, Long parentId) {
        List<SysDept> children = byParent.getOrDefault(parentId, new ArrayList<>());
        return children.stream().map(dept -> {
            DeptTreeVO node = new DeptTreeVO();
            node.setId(dept.getId());
            node.setParentId(dept.getParentId());
            node.setName(dept.getName());
            node.setSort(dept.getSort());
            node.setLeader(dept.getLeader());
            node.setStatus(dept.getStatus());
            node.setChildren(buildChildren(byParent, dept.getId()));
            return node;
        }).collect(Collectors.toList());
    }
}
