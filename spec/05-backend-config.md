# 后端配置

> 版本号见 CLAUDE.md "版本锁定"段。

## application.yml 骨架

```yaml
server:
  port: 8080
  servlet:
    context-path: /

spring:
  application:
    name: ljwx-platform
  datasource:
    url: jdbc:postgresql://${DB_HOST:localhost}:${DB_PORT:5432}/${DB_NAME:ljwx_platform}
    username: ${DB_USERNAME:postgres}
    password: ${DB_PASSWORD:postgres}
    driver-class-name: org.postgresql.Driver
  flyway:
    enabled: true
    locations: classpath:db/migration
    baseline-on-migrate: false
  quartz:
    job-store-type: jdbc
    jdbc:
      initialize-schema: never
    properties:
      org.quartz:
        scheduler:
          instanceName: LjwxScheduler
          instanceId: AUTO
        jobStore:
          class: org.quartz.impl.jdbcjobstore.JobStoreTX
          driverDelegateClass: org.quartz.impl.jdbcjobstore.PostgreSQLDelegate
          tablePrefix: QRTZ_
          isClustered: true
          clusterCheckinInterval: 15000
        threadPool:
          threadCount: 10
  servlet:
    multipart:
      max-file-size: 50MB
      max-request-size: 50MB
  cache:
    type: caffeine
    caffeine:
      spec: maximumSize=500,expireAfterWrite=600s

mybatis:
  mapper-locations: classpath*:mapper/**/*.xml
  configuration:
    map-underscore-to-camel-case: true
    default-enum-type-handler: org.apache.ibatis.type.EnumTypeHandler

springdoc:
  api-docs:
    path: /v3/api-docs
  swagger-ui:
    path: /swagger-ui.html

ljwx:
  jwt:
    secret: ${JWT_SECRET:your-256-bit-secret-key-here-change-in-production}
    access-token-expiration: 1800
    refresh-token-expiration: 604800
  file:
    base-path: ${FILE_BASE_PATH:./uploads}

management:
  endpoints:
    web:
      exposure:
        include: health,info,flyway
  endpoint:
    health:
      show-details: when-authorized

logging:
  level:
    com.ljwx.platform: DEBUG
    org.springframework.security: DEBUG
```
