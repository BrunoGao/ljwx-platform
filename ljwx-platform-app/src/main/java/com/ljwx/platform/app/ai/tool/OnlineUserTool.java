package com.ljwx.platform.app.ai.tool;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.HashMap;
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

    /**
     * 获取当前在线用户数
     * 权限约束：仅 system:online:list
     *
     * @return 在线用户数
     */
    public Map<String, Object> getOnlineUserCount() {
        Map<String, Object> result = new HashMap<>();
        // 简化实现：返回占位数据
        // 实际应从 Redis 或 Session 管理器获取
        result.put("onlineCount", 0);
        result.put("timestamp", System.currentTimeMillis());
        return result;
    }
}
