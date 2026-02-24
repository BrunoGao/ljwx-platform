package com.ljwx.platform.app.appservice;

import com.ljwx.platform.app.domain.dto.UserCreateDTO;
import com.ljwx.platform.app.domain.dto.UserQueryDTO;
import com.ljwx.platform.app.domain.dto.UserUpdateDTO;
import com.ljwx.platform.app.domain.entity.SysUser;
import com.ljwx.platform.app.domain.vo.UserVO;
import com.ljwx.platform.app.infra.mapper.SysUserMapper;
import com.ljwx.platform.core.context.CurrentTenantHolder;
import com.ljwx.platform.core.context.CurrentUserHolder;
import com.ljwx.platform.core.id.SnowflakeIdGenerator;
import com.ljwx.platform.core.result.ErrorCode;
import com.ljwx.platform.core.result.PageResult;
import com.ljwx.platform.web.exception.BusinessException;
import lombok.RequiredArgsConstructor;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.ss.usermodel.WorkbookFactory;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

/**
 * 用户应用服务（CRUD）。
 *
 * <p>tenant_id 不在 DTO 中传递，由 TenantLineInterceptor 自动注入 SELECT 查询，
 * INSERT 时由 CurrentTenantHolder 手动设置到实体上。
 */
@Service
@RequiredArgsConstructor
public class UserAppService {

    private final SysUserMapper userMapper;
    private final PasswordEncoder passwordEncoder;
    private final SnowflakeIdGenerator idGenerator;
    private final CurrentTenantHolder tenantHolder;
    private final CurrentUserHolder userHolder;

    public PageResult<UserVO> listUsers(UserQueryDTO query) {
        List<SysUser> users = userMapper.selectList(query);
        long total = userMapper.countList(query);
        List<UserVO> vos = users.stream().map(this::toVO).collect(Collectors.toList());
        return new PageResult<>(vos, total);
    }

    public UserVO getUser(Long id) {
        SysUser user = userMapper.selectById(id);
        if (user == null) {
            throw new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "用户不存在");
        }
        return toVO(user);
    }

    @Transactional
    public Long createUser(UserCreateDTO dto) {
        Long tenantId = tenantHolder.getTenantId();
        Long currentUserId = resolveCurrentUserId();

        long id = idGenerator.nextId();
        SysUser user = new SysUser();
        user.setId(id);
        user.setTenantId(tenantId);
        user.setUsername(dto.getUsername());
        user.setPassword(passwordEncoder.encode(dto.getPassword()));
        user.setNickname(dto.getNickname());
        user.setEmail(dto.getEmail());
        user.setPhone(dto.getPhone());
        user.setStatus(1);
        // createdBy/Time, updatedBy/Time 由 AuditFieldInterceptor 自动填充

        userMapper.insert(user);

        if (dto.getRoleIds() != null && !dto.getRoleIds().isEmpty()) {
            for (Long roleId : dto.getRoleIds()) {
                userMapper.insertUserRole(idGenerator.nextId(), id, roleId,
                        tenantId, currentUserId, currentUserId);
            }
        }

        return id;
    }

    @Transactional
    public void updateUser(Long id, UserUpdateDTO dto) {
        SysUser user = userMapper.selectById(id);
        if (user == null) {
            throw new BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "用户不存在");
        }

        if (dto.getNickname() != null) { user.setNickname(dto.getNickname()); }
        if (dto.getEmail()    != null) { user.setEmail(dto.getEmail());       }
        if (dto.getPhone()    != null) { user.setPhone(dto.getPhone());       }
        if (dto.getStatus()   != null) { user.setStatus(dto.getStatus());     }
        // version：客户端未传时沿用 DB 当前值（跳过乐观锁）
        if (dto.getVersion()  != null) { user.setVersion(dto.getVersion());   }
        // updatedBy/Time 由 AuditFieldInterceptor 自动刷新

        userMapper.updateById(user);

        if (dto.getRoleIds() != null) {
            Long tenantId = tenantHolder.getTenantId();
            Long currentUserId = resolveCurrentUserId();
            userMapper.deleteUserRoles(id);
            for (Long roleId : dto.getRoleIds()) {
                userMapper.insertUserRole(idGenerator.nextId(), id, roleId,
                        tenantId, currentUserId, currentUserId);
            }
        }
    }

    @Transactional
    public void deleteUser(Long id) {
        userMapper.deleteById(id);
        userMapper.deleteUserRoles(id);
    }

    /**
     * 查询所有用户（不分页，用于导出）。
     */
    public List<UserVO> listAllUsers(UserQueryDTO query) {
        // 设置大 pageSize 以获取全量数据（导出场景）
        query.setPageSize(10000);
        query.setPageNum(1);
        List<SysUser> users = userMapper.selectList(query);
        return users.stream().map(this::toVO).collect(Collectors.toList());
    }

    /**
     * 从 Excel 导入用户。
     * 列顺序：用户名(0)、昵称(1)、邮箱(2)、手机号(3)、初始密码(4)
     *
     * @return 成功导入的行数
     */
    @Transactional
    public int importUsers(MultipartFile file) throws IOException {
        Long tenantId = tenantHolder.getTenantId();
        int count = 0;
        try (Workbook wb = WorkbookFactory.create(file.getInputStream())) {
            Sheet sheet = wb.getSheetAt(0);
            // 跳过表头行（第 0 行）
            for (int i = 1; i <= sheet.getLastRowNum(); i++) {
                Row row = sheet.getRow(i);
                if (row == null) continue;
                String username = getCellString(row, 0);
                if (username == null || username.isBlank()) continue;
                String nickname  = getCellString(row, 1);
                String email     = getCellString(row, 2);
                String phone     = getCellString(row, 3);
                String password  = getCellString(row, 4);
                if (password == null || password.isBlank()) {
                    password = "Admin@12345";
                }
                long id = idGenerator.nextId();
                SysUser user = new SysUser();
                user.setId(id);
                user.setTenantId(tenantId);
                user.setUsername(username);
                user.setPassword(passwordEncoder.encode(password));
                user.setNickname(nickname != null ? nickname : username);
                user.setEmail(email != null ? email : "");
                user.setPhone(phone != null ? phone : "");
                user.setStatus(1);
                userMapper.insert(user);
                count++;
            }
        }
        return count;
    }

    private String getCellString(Row row, int col) {
        var cell = row.getCell(col);
        if (cell == null) return null;
        return switch (cell.getCellType()) {
            case STRING  -> cell.getStringCellValue().trim();
            case NUMERIC -> String.valueOf((long) cell.getNumericCellValue());
            default      -> null;
        };
    }

    private UserVO toVO(SysUser user) {
        UserVO vo = new UserVO();
        vo.setId(user.getId());
        vo.setUsername(user.getUsername());
        vo.setNickname(user.getNickname());
        vo.setEmail(user.getEmail());
        vo.setPhone(user.getPhone());
        vo.setAvatar(user.getAvatar());
        vo.setStatus(user.getStatus());
        vo.setCreatedTime(user.getCreatedTime());
        vo.setUpdatedTime(user.getUpdatedTime());
        vo.setRoles(userMapper.selectRolesForUser(user.getId()));
        return vo;
    }

    private Long resolveCurrentUserId() {
        Long uid = userHolder.getUserId();
        return uid != null ? uid : 0L;
    }
}
