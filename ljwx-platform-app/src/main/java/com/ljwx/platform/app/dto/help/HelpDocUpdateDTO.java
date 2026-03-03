package com.ljwx.platform.app.dto.help;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * Help doc update DTO
 */
@Data
public class HelpDocUpdateDTO {

    /**
     * Document title
     */
    @NotBlank(message = "Title cannot be blank")
    @Size(max = 200, message = "Title cannot exceed 200 characters")
    private String title;

    /**
     * Markdown content
     */
    @NotBlank(message = "Content cannot be blank")
    private String content;

    /**
     * Category
     */
    @NotBlank(message = "Category cannot be blank")
    @Size(max = 50, message = "Category cannot exceed 50 characters")
    private String category;

    /**
     * Associated route
     */
    @Size(max = 500, message = "Route match cannot exceed 500 characters")
    private String routeMatch;

    /**
     * Sort order
     */
    @Min(value = 0, message = "Sort order must be >= 0")
    private Integer sortOrder;

    /**
     * Status: 1 enabled, 0 disabled
     */
    @NotNull(message = "Status cannot be null")
    @Min(value = 0, message = "Status must be 0 or 1")
    @Max(value = 1, message = "Status must be 0 or 1")
    private Integer status;
}
