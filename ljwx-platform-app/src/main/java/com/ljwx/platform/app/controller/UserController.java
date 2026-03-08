package com.ljwx.platform.app.controller;

import com.ljwx.platform.app.appservice.UserAppService;
import com.ljwx.platform.app.domain.dto.UserCreateDTO;
import com.ljwx.platform.app.domain.dto.UserQueryDTO;
import com.ljwx.platform.app.domain.dto.UserUpdateDTO;
import com.ljwx.platform.app.domain.vo.UserVO;
import com.ljwx.platform.core.result.PageResult;
import com.ljwx.platform.core.result.Result;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.List;

/**
 * 用户管理 Controller。
 */
@RestController
@RequestMapping({"/api/v1/users", "/api/users"})
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

    /**
     * 导出用户列表为 Excel。
     */
    @PreAuthorize("hasAuthority('system:user:export')")
    @GetMapping("/export")
    public void export(UserQueryDTO query, HttpServletResponse response) throws IOException {
        List<UserVO> users = userAppService.listAllUsers(query);
        response.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
        response.setHeader("Content-Disposition",
                "attachment; filename*=UTF-8''" + URLEncoder.encode("用户列表.xlsx", StandardCharsets.UTF_8));
        try (Workbook wb = new XSSFWorkbook()) {
            Sheet sheet = wb.createSheet("用户列表");
            Row header = sheet.createRow(0);
            header.createCell(0).setCellValue("用户名");
            header.createCell(1).setCellValue("昵称");
            header.createCell(2).setCellValue("邮箱");
            header.createCell(3).setCellValue("手机号");
            header.createCell(4).setCellValue("状态");
            header.createCell(5).setCellValue("创建时间");
            int rowIdx = 1;
            for (UserVO u : users) {
                Row row = sheet.createRow(rowIdx++);
                row.createCell(0).setCellValue(u.getUsername());
                row.createCell(1).setCellValue(u.getNickname() != null ? u.getNickname() : "");
                row.createCell(2).setCellValue(u.getEmail() != null ? u.getEmail() : "");
                row.createCell(3).setCellValue(u.getPhone() != null ? u.getPhone() : "");
                row.createCell(4).setCellValue(u.getStatus() == 1 ? "启用" : "禁用");
                row.createCell(5).setCellValue(u.getCreatedTime() != null ? u.getCreatedTime().toString() : "");
            }
            wb.write(response.getOutputStream());
        }
    }

    /**
     * 导入用户（Excel，multipart/form-data）。
     */
    @PreAuthorize("hasAuthority('system:user:import')")
    @PostMapping("/import")
    public Result<String> importUsers(@RequestParam("file") MultipartFile file) throws IOException {
        int count = userAppService.importUsers(file);
        return Result.ok("成功导入 " + count + " 条用户数据");
    }
}
