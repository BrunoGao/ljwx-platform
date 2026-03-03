package com.ljwx.platform.app.dto.help;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * Help doc create DTO
 */
@Data
public class HelpDocCreateDTO {

    /**
     * Document unique key
     */
    @NotBlank(message = "Document key cannot be blank")
    @Size(max = 100, message = "Document key cannot exceed 100 characters")
    @Pattern(regexp = "^[a-z][a-z0-9_-]*$", message = "Document key must start with lowercase letter and contain only lowercase letters, numbers, underscores, and hyphens")
    private String docKey;

    /**
     * Document title
     */
    @NotBlank(message = "Title cannot be blank")
    @Size(min = 1, max = 200, message = "Title must be between 1 and 200 characters")
    private String title;

    /**
     * Markdown content
     */
    @NotBlank(message = "Content cannot be blank")
    @Size(min = 1, max = 50000, message = "Content must be between 1 and 50000 characters")
    private String content;

    /**
     * Category
     */
    @NotBlank(message = "Category cannot be blank")
    @Size(max = 50, message = "Category cannot exceed 50 characters")
    @Pattern(regexp = "[a-zA-Z0-9_-]+", message = "Category can only contain letters, numbers, underscores, and hyphens")
    private String category;

    /**
     * Associated route (must start with /)
     */
    @Size(max = 500, message = "Route match cannot exceed 500 characters")
    @Pattern(regexp = "^/.*", message = "Route match must start with /")
    private String routeMatch;

    /**
     * Sort order
     */
    @Min(value = 0, message = "Sort order must be >= 0")
    private Integer sortOrder;
}
