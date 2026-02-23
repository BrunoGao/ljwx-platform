package com.ljwx.platform.app.domain.dto;

/**
 * 文件查询 DTO。
 */
public class FileQueryDTO {

    /** 页码，默认 1 */
    private int pageNum = 1;

    /** 每页条数，默认 10 */
    private int pageSize = 10;

    /** 原始文件名（模糊匹配） */
    private String fileName;

    /** 文件后缀（如 jpg、pdf，不含点号） */
    private String fileType;

    public int getPageNum() { return pageNum; }
    public void setPageNum(int pageNum) { this.pageNum = pageNum; }

    public int getPageSize() { return pageSize; }
    public void setPageSize(int pageSize) { this.pageSize = pageSize; }

    public String getFileName() { return fileName; }
    public void setFileName(String fileName) { this.fileName = fileName; }

    public String getFileType() { return fileType; }
    public void setFileType(String fileType) { this.fileType = fileType; }

    public int getOffset() { return (pageNum - 1) * pageSize; }
}
