package com.ljwx.platform.app.domain.entity;

import com.ljwx.platform.data.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 文件管理实体，对应 sys_file 表。
 *
 * <p>文件以 Snowflake ID 命名，存储路径为：
 * {@code ${ljwx.file.base-path}/tenant_{tenantId}/{yyyy}/{MM}/{dd}/{snowflakeId}.{ext}}
 * <p>上传限制 50 MB，后缀白名单：jpg, jpeg, png, gif, webp, svg, pdf, doc, docx,
 * xls, xlsx, ppt, pptx, txt, csv, zip, rar, 7z, mp4, mp3。
 */
@Data
@EqualsAndHashCode(callSuper = true)
public class SysFile extends BaseEntity {

    /** 主键ID（Snowflake，同时作为存储文件名） */
    private Long id;

    /** 原始文件名（用户上传时的文件名） */
    private String fileName;

    /** 存储路径（相对于 base-path，含 tenant_id + 日期目录） */
    private String filePath;

    /** 文件大小（字节） */
    private Long fileSize;

    /** 文件后缀（如 jpg、pdf，不含点号） */
    private String fileType;

    /** MIME 类型（如 image/jpeg、application/pdf） */
    private String contentType;
}
