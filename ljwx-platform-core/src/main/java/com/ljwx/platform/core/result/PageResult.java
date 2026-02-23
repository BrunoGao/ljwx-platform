package com.ljwx.platform.core.result;

import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.util.List;

/**
 * 分页结果封装。
 *
 * <p>通过 {@link Result#ok(Object)} 包装后返回给前端：
 * <pre>
 * {
 *   "code": 200,
 *   "data": {
 *     "records": [...],
 *     "total": 100
 *   }
 * }
 * </pre>
 */
@Data
@NoArgsConstructor
public class PageResult<T> implements Serializable {

    private List<T> records;
    private long total;

    public PageResult(List<T> records, long total) {
        this.records = records;
        this.total = total;
    }
}
