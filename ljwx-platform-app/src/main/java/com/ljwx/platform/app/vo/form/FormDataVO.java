package com.ljwx.platform.app.vo.form;

import lombok.Data;

import java.time.LocalDateTime;
import java.util.Map;

/**
 * Form data VO
 */
@Data
public class FormDataVO {

    /**
     * Primary key
     */
    private Long id;

    /**
     * Form definition ID
     */
    private Long formDefId;

    /**
     * Form field values
     */
    private Map<String, Object> fieldValues;

    /**
     * Creator user ID
     */
    private Long creatorId;

    /**
     * Created time
     */
    private LocalDateTime createdTime;

    /**
     * Updated time
     */
    private LocalDateTime updatedTime;
}
