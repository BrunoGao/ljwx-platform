package com.ljwx.platform.app.ai.tool;

import com.ljwx.platform.app.appservice.OnlineUserAppService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Map;

/**
 * 在线用户工具 - 提供在线用户查询
 *
 * @author LJWX Platform
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class OnlineUserTool {

    private final OnlineUserAppService onlineUserAppService;

    /**
     * 获取当前在线用户数
     * 权限约束：仅 system:online:list
     *
     * @return 在线用户数
     */
    public Map<String, Object> getOnlineUserCount() {
        List<Map<String, String>> onlineUsers = onlineUserAppService.listOnlineUsers();
        return Map.of(
                "onlineCount", onlineUsers.size(),
                "users", onlineUsers.stream().limit(10).toList(),
                "timestamp", System.currentTimeMillis()
        );
    }
}
