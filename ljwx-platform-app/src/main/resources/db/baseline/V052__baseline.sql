--
-- PostgreSQL database dump
--

\restrict DahdbKxydmjkiS4Gaa5RrzAqJ7JZZkvN57delNi41l3PWQy0s1eI8IZr1FE34vy

-- Dumped from database version 14.20 (Homebrew)
-- Dumped by pg_dump version 14.22 (Homebrew)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: notify_outbox_event(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.notify_outbox_event() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    PERFORM pg_notify('outbox_event_channel', NEW.id::text);
    RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: cache_invalidation_event; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cache_invalidation_event (
    id bigint NOT NULL,
    cache_name character varying(100) NOT NULL,
    cache_key character varying(500) NOT NULL,
    event_type character varying(20) NOT NULL,
    source_pod character varying(100) NOT NULL,
    tenant_id bigint DEFAULT 0 NOT NULL,
    created_by bigint DEFAULT 0 NOT NULL,
    created_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by bigint DEFAULT 0 NOT NULL,
    updated_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    version integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE cache_invalidation_event; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.cache_invalidation_event IS 'Cache invalidation event log for multi-level cache synchronization';


--
-- Name: COLUMN cache_invalidation_event.cache_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.cache_invalidation_event.cache_name IS 'Cache name identifier';


--
-- Name: COLUMN cache_invalidation_event.cache_key; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.cache_invalidation_event.cache_key IS 'Cache key to invalidate';


--
-- Name: COLUMN cache_invalidation_event.event_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.cache_invalidation_event.event_type IS 'Event type: EVICT or CLEAR';


--
-- Name: COLUMN cache_invalidation_event.source_pod; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.cache_invalidation_event.source_pod IS 'Pod identifier that initiated the invalidation';


--
-- Name: msg_record; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.msg_record (
    id bigint NOT NULL,
    template_id bigint,
    message_type character varying(20) NOT NULL,
    receiver_id bigint,
    receiver_address character varying(200),
    subject character varying(200) NOT NULL,
    content text NOT NULL,
    send_status character varying(20) NOT NULL,
    send_time timestamp without time zone,
    error_message text,
    tenant_id bigint DEFAULT 0 NOT NULL,
    created_by bigint DEFAULT 0 NOT NULL,
    created_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by bigint DEFAULT 0 NOT NULL,
    updated_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    version integer DEFAULT 1 NOT NULL
);


--
-- Name: msg_subscription; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.msg_subscription (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    template_id bigint NOT NULL,
    channel character varying(20) NOT NULL,
    status character varying(20) NOT NULL,
    preference jsonb,
    tenant_id bigint DEFAULT 0 NOT NULL,
    created_by bigint DEFAULT 0 NOT NULL,
    created_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by bigint DEFAULT 0 NOT NULL,
    updated_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    version integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE msg_subscription; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.msg_subscription IS '消息订阅表';


--
-- Name: COLUMN msg_subscription.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.msg_subscription.id IS '主键（雪花 ID）';


--
-- Name: COLUMN msg_subscription.user_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.msg_subscription.user_id IS '用户 ID';


--
-- Name: COLUMN msg_subscription.template_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.msg_subscription.template_id IS '模板 ID';


--
-- Name: COLUMN msg_subscription.channel; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.msg_subscription.channel IS '订阅渠道: EMAIL / SMS / WECHAT / PUSH';


--
-- Name: COLUMN msg_subscription.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.msg_subscription.status IS '订阅状态: ACTIVE / INACTIVE';


--
-- Name: COLUMN msg_subscription.preference; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.msg_subscription.preference IS '订阅偏好（频率、时段等）';


--
-- Name: COLUMN msg_subscription.tenant_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.msg_subscription.tenant_id IS '租户 ID';


--
-- Name: COLUMN msg_subscription.created_by; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.msg_subscription.created_by IS '创建人';


--
-- Name: COLUMN msg_subscription.created_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.msg_subscription.created_time IS '创建时间';


--
-- Name: COLUMN msg_subscription.updated_by; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.msg_subscription.updated_by IS '更新人';


--
-- Name: COLUMN msg_subscription.updated_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.msg_subscription.updated_time IS '更新时间';


--
-- Name: COLUMN msg_subscription.deleted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.msg_subscription.deleted IS '软删除标记';


--
-- Name: COLUMN msg_subscription.version; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.msg_subscription.version IS '乐观锁版本号';


--
-- Name: msg_user_inbox; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.msg_user_inbox (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    message_id bigint NOT NULL,
    title character varying(200) NOT NULL,
    content text NOT NULL,
    is_read boolean DEFAULT false NOT NULL,
    read_time timestamp without time zone,
    tenant_id bigint DEFAULT 0 NOT NULL,
    created_by bigint DEFAULT 0 NOT NULL,
    created_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by bigint DEFAULT 0 NOT NULL,
    updated_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    version integer DEFAULT 1 NOT NULL
);


--
-- Name: open_app_secret; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.open_app_secret (
    id bigint NOT NULL,
    app_id bigint NOT NULL,
    secret_key character varying(128) NOT NULL,
    secret_version integer DEFAULT 1 NOT NULL,
    status character varying(20) NOT NULL,
    expire_time timestamp without time zone,
    tenant_id bigint DEFAULT 0 NOT NULL,
    created_by bigint DEFAULT 0 NOT NULL,
    created_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by bigint DEFAULT 0 NOT NULL,
    updated_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    version integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE open_app_secret; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.open_app_secret IS 'Open API Secret Management';


--
-- Name: COLUMN open_app_secret.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.open_app_secret.id IS 'Primary Key (Snowflake ID)';


--
-- Name: COLUMN open_app_secret.app_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.open_app_secret.app_id IS 'Application ID';


--
-- Name: COLUMN open_app_secret.secret_key; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.open_app_secret.secret_key IS 'Encrypted Secret Key';


--
-- Name: COLUMN open_app_secret.secret_version; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.open_app_secret.secret_version IS 'Secret Version Number';


--
-- Name: COLUMN open_app_secret.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.open_app_secret.status IS 'Status: ACTIVE / EXPIRED';


--
-- Name: COLUMN open_app_secret.expire_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.open_app_secret.expire_time IS 'Expiration Time';


--
-- Name: qrtz_blob_triggers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.qrtz_blob_triggers (
    sched_name character varying(120) NOT NULL,
    trigger_name character varying(200) NOT NULL,
    trigger_group character varying(200) NOT NULL,
    blob_data bytea
);


--
-- Name: qrtz_calendars; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.qrtz_calendars (
    sched_name character varying(120) NOT NULL,
    calendar_name character varying(200) NOT NULL,
    calendar bytea NOT NULL
);


--
-- Name: qrtz_cron_triggers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.qrtz_cron_triggers (
    sched_name character varying(120) NOT NULL,
    trigger_name character varying(200) NOT NULL,
    trigger_group character varying(200) NOT NULL,
    cron_expression character varying(120) NOT NULL,
    time_zone_id character varying(80)
);


--
-- Name: qrtz_fired_triggers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.qrtz_fired_triggers (
    sched_name character varying(120) NOT NULL,
    entry_id character varying(95) NOT NULL,
    trigger_name character varying(200) NOT NULL,
    trigger_group character varying(200) NOT NULL,
    instance_name character varying(200) NOT NULL,
    fired_time bigint NOT NULL,
    sched_time bigint NOT NULL,
    priority integer NOT NULL,
    state character varying(16) NOT NULL,
    job_name character varying(200),
    job_group character varying(200),
    is_nonconcurrent boolean,
    requests_recovery boolean
);


--
-- Name: qrtz_job_details; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.qrtz_job_details (
    sched_name character varying(120) NOT NULL,
    job_name character varying(200) NOT NULL,
    job_group character varying(200) NOT NULL,
    description character varying(250),
    job_class_name character varying(250) NOT NULL,
    is_durable boolean NOT NULL,
    is_nonconcurrent boolean NOT NULL,
    is_update_data boolean NOT NULL,
    requests_recovery boolean NOT NULL,
    job_data bytea
);


--
-- Name: qrtz_locks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.qrtz_locks (
    sched_name character varying(120) NOT NULL,
    lock_name character varying(40) NOT NULL
);


--
-- Name: qrtz_paused_trigger_grps; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.qrtz_paused_trigger_grps (
    sched_name character varying(120) NOT NULL,
    trigger_group character varying(200) NOT NULL
);


--
-- Name: qrtz_scheduler_state; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.qrtz_scheduler_state (
    sched_name character varying(120) NOT NULL,
    instance_name character varying(200) NOT NULL,
    last_checkin_time bigint NOT NULL,
    checkin_interval bigint NOT NULL
);


--
-- Name: qrtz_simple_triggers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.qrtz_simple_triggers (
    sched_name character varying(120) NOT NULL,
    trigger_name character varying(200) NOT NULL,
    trigger_group character varying(200) NOT NULL,
    repeat_count bigint NOT NULL,
    repeat_interval bigint NOT NULL,
    times_triggered bigint NOT NULL
);


--
-- Name: qrtz_simprop_triggers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.qrtz_simprop_triggers (
    sched_name character varying(120) NOT NULL,
    trigger_name character varying(200) NOT NULL,
    trigger_group character varying(200) NOT NULL,
    str_prop_1 character varying(512),
    str_prop_2 character varying(512),
    str_prop_3 character varying(512),
    int_prop_1 integer,
    int_prop_2 integer,
    long_prop_1 bigint,
    long_prop_2 bigint,
    dec_prop_1 numeric(13,4),
    dec_prop_2 numeric(13,4),
    bool_prop_1 boolean,
    bool_prop_2 boolean
);


--
-- Name: qrtz_triggers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.qrtz_triggers (
    sched_name character varying(120) NOT NULL,
    trigger_name character varying(200) NOT NULL,
    trigger_group character varying(200) NOT NULL,
    job_name character varying(200) NOT NULL,
    job_group character varying(200) NOT NULL,
    description character varying(250),
    next_fire_time bigint,
    prev_fire_time bigint,
    priority integer,
    trigger_state character varying(16) NOT NULL,
    trigger_type character varying(8) NOT NULL,
    start_time bigint NOT NULL,
    end_time bigint,
    calendar_name character varying(200),
    misfire_instr smallint,
    job_data bytea
);


--
-- Name: sys_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sys_config (
    id bigint NOT NULL,
    config_name character varying(100) NOT NULL,
    config_key character varying(100) NOT NULL,
    config_value character varying(500) NOT NULL,
    config_type smallint DEFAULT 1 NOT NULL,
    remark character varying(500),
    tenant_id bigint DEFAULT 0 NOT NULL,
    created_by bigint DEFAULT 0 NOT NULL,
    created_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by bigint DEFAULT 0 NOT NULL,
    updated_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    version integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE sys_config; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.sys_config IS '系统配置表';


--
-- Name: COLUMN sys_config.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_config.id IS '主键ID（Snowflake）';


--
-- Name: COLUMN sys_config.config_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_config.config_name IS '参数名称';


--
-- Name: COLUMN sys_config.config_key; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_config.config_key IS '参数键名（唯一标识）';


--
-- Name: COLUMN sys_config.config_value; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_config.config_value IS '参数键值';


--
-- Name: COLUMN sys_config.config_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_config.config_type IS '系统内置：1-是，0-否';


--
-- Name: COLUMN sys_config.remark; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_config.remark IS '备注';


--
-- Name: COLUMN sys_config.tenant_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_config.tenant_id IS '租户ID，由 TenantLineInterceptor 自动注入';


--
-- Name: COLUMN sys_config.deleted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_config.deleted IS '软删除标志';


--
-- Name: COLUMN sys_config.version; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_config.version IS '乐观锁版本号';


--
-- Name: sys_data_change_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sys_data_change_log (
    id bigint NOT NULL,
    table_name character varying(64) NOT NULL,
    record_id bigint NOT NULL,
    field_name character varying(64) NOT NULL,
    old_value text DEFAULT ''::text NOT NULL,
    new_value text DEFAULT ''::text NOT NULL,
    operate_type character varying(16) NOT NULL,
    tenant_id bigint DEFAULT 0 NOT NULL,
    created_by bigint DEFAULT 0 NOT NULL,
    created_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by bigint DEFAULT 0 NOT NULL,
    updated_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    version integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE sys_data_change_log; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.sys_data_change_log IS '数据变更审计日志';


--
-- Name: COLUMN sys_data_change_log.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_data_change_log.id IS '主键ID（Snowflake）';


--
-- Name: COLUMN sys_data_change_log.table_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_data_change_log.table_name IS '表名';


--
-- Name: COLUMN sys_data_change_log.record_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_data_change_log.record_id IS '记录ID';


--
-- Name: COLUMN sys_data_change_log.field_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_data_change_log.field_name IS '字段名';


--
-- Name: COLUMN sys_data_change_log.old_value; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_data_change_log.old_value IS '变更前值';


--
-- Name: COLUMN sys_data_change_log.new_value; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_data_change_log.new_value IS '变更后值';


--
-- Name: COLUMN sys_data_change_log.operate_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_data_change_log.operate_type IS '操作类型（UPDATE / DELETE）';


--
-- Name: sys_dept; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sys_dept (
    id bigint NOT NULL,
    parent_id bigint DEFAULT 0 NOT NULL,
    name character varying(64) NOT NULL,
    sort integer DEFAULT 0 NOT NULL,
    leader character varying(64) DEFAULT ''::character varying NOT NULL,
    phone character varying(20) DEFAULT ''::character varying NOT NULL,
    email character varying(100) DEFAULT ''::character varying NOT NULL,
    status smallint DEFAULT 1 NOT NULL,
    tenant_id bigint DEFAULT 0 NOT NULL,
    created_by bigint DEFAULT 0 NOT NULL,
    created_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by bigint DEFAULT 0 NOT NULL,
    updated_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    version integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE sys_dept; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.sys_dept IS '部门表';


--
-- Name: COLUMN sys_dept.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_dept.id IS '部门ID（Snowflake）';


--
-- Name: COLUMN sys_dept.parent_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_dept.parent_id IS '父部门ID，0=根节点';


--
-- Name: COLUMN sys_dept.name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_dept.name IS '部门名称';


--
-- Name: COLUMN sys_dept.sort; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_dept.sort IS '显示排序';


--
-- Name: COLUMN sys_dept.leader; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_dept.leader IS '负责人';


--
-- Name: COLUMN sys_dept.phone; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_dept.phone IS '联系电话';


--
-- Name: COLUMN sys_dept.email; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_dept.email IS '邮箱';


--
-- Name: COLUMN sys_dept.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_dept.status IS '状态：1=正常，0=停用';


--
-- Name: COLUMN sys_dept.tenant_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_dept.tenant_id IS '租户ID，由 TenantLineInterceptor 自动注入';


--
-- Name: COLUMN sys_dept.deleted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_dept.deleted IS '软删除标志';


--
-- Name: COLUMN sys_dept.version; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_dept.version IS '乐观锁版本号';


--
-- Name: sys_dict_data; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sys_dict_data (
    id bigint NOT NULL,
    dict_type character varying(100) NOT NULL,
    dict_label character varying(100) NOT NULL,
    dict_value character varying(100) NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    status smallint DEFAULT 1 NOT NULL,
    css_class character varying(100),
    list_class character varying(100),
    is_default boolean DEFAULT false NOT NULL,
    remark character varying(500),
    tenant_id bigint DEFAULT 0 NOT NULL,
    created_by bigint DEFAULT 0 NOT NULL,
    created_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by bigint DEFAULT 0 NOT NULL,
    updated_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    version integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE sys_dict_data; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.sys_dict_data IS '字典数据表';


--
-- Name: COLUMN sys_dict_data.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_dict_data.id IS '主键ID（Snowflake）';


--
-- Name: COLUMN sys_dict_data.dict_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_dict_data.dict_type IS '字典类型，外键关联 sys_dict_type.dict_type';


--
-- Name: COLUMN sys_dict_data.dict_label; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_dict_data.dict_label IS '字典标签（显示名称）';


--
-- Name: COLUMN sys_dict_data.dict_value; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_dict_data.dict_value IS '字典键值';


--
-- Name: COLUMN sys_dict_data.sort_order; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_dict_data.sort_order IS '显示顺序';


--
-- Name: COLUMN sys_dict_data.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_dict_data.status IS '状态：1-正常，0-停用';


--
-- Name: COLUMN sys_dict_data.css_class; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_dict_data.css_class IS '样式属性（前端使用）';


--
-- Name: COLUMN sys_dict_data.list_class; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_dict_data.list_class IS '表格回显样式（前端使用）';


--
-- Name: COLUMN sys_dict_data.is_default; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_dict_data.is_default IS '是否默认值';


--
-- Name: COLUMN sys_dict_data.remark; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_dict_data.remark IS '备注';


--
-- Name: COLUMN sys_dict_data.tenant_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_dict_data.tenant_id IS '租户ID，由 TenantLineInterceptor 自动注入';


--
-- Name: COLUMN sys_dict_data.deleted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_dict_data.deleted IS '软删除标志';


--
-- Name: COLUMN sys_dict_data.version; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_dict_data.version IS '乐观锁版本号';


--
-- Name: sys_dict_type; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sys_dict_type (
    id bigint NOT NULL,
    dict_name character varying(100) NOT NULL,
    dict_type character varying(100) NOT NULL,
    status smallint DEFAULT 1 NOT NULL,
    remark character varying(500),
    tenant_id bigint DEFAULT 0 NOT NULL,
    created_by bigint DEFAULT 0 NOT NULL,
    created_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by bigint DEFAULT 0 NOT NULL,
    updated_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    version integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE sys_dict_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.sys_dict_type IS '字典类型表';


--
-- Name: COLUMN sys_dict_type.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_dict_type.id IS '主键ID（Snowflake）';


--
-- Name: COLUMN sys_dict_type.dict_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_dict_type.dict_name IS '字典名称';


--
-- Name: COLUMN sys_dict_type.dict_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_dict_type.dict_type IS '字典类型（唯一标识，如 sys_user_sex）';


--
-- Name: COLUMN sys_dict_type.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_dict_type.status IS '状态：1-正常，0-停用';


--
-- Name: COLUMN sys_dict_type.remark; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_dict_type.remark IS '备注';


--
-- Name: COLUMN sys_dict_type.tenant_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_dict_type.tenant_id IS '租户ID，由 TenantLineInterceptor 自动注入';


--
-- Name: COLUMN sys_dict_type.deleted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_dict_type.deleted IS '软删除标志';


--
-- Name: COLUMN sys_dict_type.version; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_dict_type.version IS '乐观锁版本号';


--
-- Name: sys_file; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sys_file (
    id bigint NOT NULL,
    file_name character varying(255) DEFAULT ''::character varying NOT NULL,
    file_path character varying(1000) DEFAULT ''::character varying NOT NULL,
    file_size bigint DEFAULT 0 NOT NULL,
    file_type character varying(50) DEFAULT ''::character varying NOT NULL,
    content_type character varying(200) DEFAULT ''::character varying NOT NULL,
    tenant_id bigint DEFAULT 0 NOT NULL,
    created_by bigint DEFAULT 0 NOT NULL,
    created_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by bigint DEFAULT 0 NOT NULL,
    updated_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    version integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE sys_file; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.sys_file IS '文件管理表';


--
-- Name: COLUMN sys_file.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_file.id IS '主键ID（Snowflake）';


--
-- Name: COLUMN sys_file.file_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_file.file_name IS '原始文件名';


--
-- Name: COLUMN sys_file.file_path; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_file.file_path IS '存储路径（相对于 base-path）';


--
-- Name: COLUMN sys_file.file_size; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_file.file_size IS '文件大小（字节）';


--
-- Name: COLUMN sys_file.file_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_file.file_type IS '文件后缀（如 jpg、pdf）';


--
-- Name: COLUMN sys_file.content_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_file.content_type IS 'MIME 类型';


--
-- Name: COLUMN sys_file.tenant_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_file.tenant_id IS '租户ID，路径含 tenant_id，由 TenantLineInterceptor 注入';


--
-- Name: COLUMN sys_file.deleted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_file.deleted IS '软删除标志';


--
-- Name: COLUMN sys_file.version; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_file.version IS '乐观锁版本号';


--
-- Name: sys_frontend_error; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sys_frontend_error (
    id bigint NOT NULL,
    error_message character varying(1000) NOT NULL,
    stack_trace text DEFAULT ''::text NOT NULL,
    page_url character varying(500) DEFAULT ''::character varying NOT NULL,
    user_agent character varying(500) DEFAULT ''::character varying NOT NULL,
    tenant_id bigint DEFAULT 0 NOT NULL,
    created_by bigint DEFAULT 0 NOT NULL,
    created_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by bigint DEFAULT 0 NOT NULL,
    updated_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    version integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE sys_frontend_error; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.sys_frontend_error IS '前端错误监控表';


--
-- Name: COLUMN sys_frontend_error.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_frontend_error.id IS '主键';


--
-- Name: COLUMN sys_frontend_error.error_message; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_frontend_error.error_message IS '错误信息';


--
-- Name: COLUMN sys_frontend_error.stack_trace; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_frontend_error.stack_trace IS '堆栈信息';


--
-- Name: COLUMN sys_frontend_error.page_url; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_frontend_error.page_url IS '发生页面';


--
-- Name: COLUMN sys_frontend_error.user_agent; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_frontend_error.user_agent IS '浏览器信息';


--
-- Name: sys_import_export_task; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sys_import_export_task (
    id bigint NOT NULL,
    task_type character varying(20) NOT NULL,
    business_type character varying(50) NOT NULL,
    file_name character varying(200) NOT NULL,
    file_url character varying(500),
    status character varying(20) NOT NULL,
    total_count integer DEFAULT 0 NOT NULL,
    success_count integer DEFAULT 0 NOT NULL,
    failure_count integer DEFAULT 0 NOT NULL,
    error_message text,
    tenant_id bigint DEFAULT 0 NOT NULL,
    created_by bigint DEFAULT 0 NOT NULL,
    created_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by bigint DEFAULT 0 NOT NULL,
    updated_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    version integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE sys_import_export_task; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.sys_import_export_task IS 'Import/Export task table';


--
-- Name: COLUMN sys_import_export_task.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_import_export_task.id IS 'Primary key (Snowflake ID)';


--
-- Name: COLUMN sys_import_export_task.task_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_import_export_task.task_type IS 'Task type: IMPORT / EXPORT';


--
-- Name: COLUMN sys_import_export_task.business_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_import_export_task.business_type IS 'Business type: USER / ROLE / DEPT / MENU';


--
-- Name: COLUMN sys_import_export_task.file_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_import_export_task.file_name IS 'File name';


--
-- Name: COLUMN sys_import_export_task.file_url; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_import_export_task.file_url IS 'File URL (MinIO)';


--
-- Name: COLUMN sys_import_export_task.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_import_export_task.status IS 'Status: PENDING / PROCESSING / SUCCESS / FAILURE';


--
-- Name: COLUMN sys_import_export_task.total_count; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_import_export_task.total_count IS 'Total record count';


--
-- Name: COLUMN sys_import_export_task.success_count; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_import_export_task.success_count IS 'Success record count';


--
-- Name: COLUMN sys_import_export_task.failure_count; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_import_export_task.failure_count IS 'Failure record count';


--
-- Name: COLUMN sys_import_export_task.error_message; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_import_export_task.error_message IS 'Error message';


--
-- Name: sys_job; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sys_job (
    id bigint NOT NULL,
    job_name character varying(200) NOT NULL,
    job_group character varying(200) DEFAULT 'DEFAULT'::character varying NOT NULL,
    job_class_name character varying(500) NOT NULL,
    cron_expression character varying(120) NOT NULL,
    description character varying(500),
    status smallint DEFAULT 1 NOT NULL,
    tenant_id bigint DEFAULT 0 NOT NULL,
    created_by bigint DEFAULT 0 NOT NULL,
    created_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by bigint DEFAULT 0 NOT NULL,
    updated_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    version integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE sys_job; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.sys_job IS '定时任务表';


--
-- Name: COLUMN sys_job.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_job.id IS '任务ID（Snowflake）';


--
-- Name: COLUMN sys_job.job_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_job.job_name IS '任务名称';


--
-- Name: COLUMN sys_job.job_group; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_job.job_group IS '任务分组';


--
-- Name: COLUMN sys_job.job_class_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_job.job_class_name IS '任务执行类全路径';


--
-- Name: COLUMN sys_job.cron_expression; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_job.cron_expression IS 'Cron 表达式';


--
-- Name: COLUMN sys_job.description; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_job.description IS '任务描述';


--
-- Name: COLUMN sys_job.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_job.status IS '状态：1-正常，0-暂停';


--
-- Name: COLUMN sys_job.tenant_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_job.tenant_id IS '租户ID，由 TenantLineInterceptor 自动注入';


--
-- Name: COLUMN sys_job.deleted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_job.deleted IS '软删除标志';


--
-- Name: COLUMN sys_job.version; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_job.version IS '乐观锁版本号';


--
-- Name: sys_login_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sys_login_log (
    id bigint NOT NULL,
    username character varying(100) DEFAULT ''::character varying NOT NULL,
    ip character varying(50) DEFAULT ''::character varying NOT NULL,
    location character varying(255) DEFAULT ''::character varying NOT NULL,
    browser character varying(100) DEFAULT ''::character varying NOT NULL,
    os character varying(100) DEFAULT ''::character varying NOT NULL,
    status smallint DEFAULT 0 NOT NULL,
    msg character varying(500) DEFAULT ''::character varying NOT NULL,
    tenant_id bigint DEFAULT 0 NOT NULL,
    created_by bigint DEFAULT 0 NOT NULL,
    created_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by bigint DEFAULT 0 NOT NULL,
    updated_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    version integer DEFAULT 1 NOT NULL,
    ip_address character varying(64) DEFAULT ''::character varying NOT NULL,
    user_agent character varying(500) DEFAULT ''::character varying NOT NULL,
    login_time timestamp with time zone DEFAULT now() NOT NULL,
    message character varying(255) DEFAULT ''::character varying NOT NULL
);


--
-- Name: TABLE sys_login_log; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.sys_login_log IS '登录日志表';


--
-- Name: COLUMN sys_login_log.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_login_log.id IS '主键ID（Snowflake）';


--
-- Name: COLUMN sys_login_log.username; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_login_log.username IS '登录账号';


--
-- Name: COLUMN sys_login_log.ip; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_login_log.ip IS '登录IP';


--
-- Name: COLUMN sys_login_log.location; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_login_log.location IS '登录地点';


--
-- Name: COLUMN sys_login_log.browser; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_login_log.browser IS '浏览器类型';


--
-- Name: COLUMN sys_login_log.os; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_login_log.os IS '操作系统';


--
-- Name: COLUMN sys_login_log.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_login_log.status IS '登录状态：0-成功,1-失败';


--
-- Name: COLUMN sys_login_log.msg; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_login_log.msg IS '提示消息';


--
-- Name: COLUMN sys_login_log.tenant_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_login_log.tenant_id IS '租户ID，由 TenantLineInterceptor 自动注入';


--
-- Name: COLUMN sys_login_log.deleted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_login_log.deleted IS '软删除标志';


--
-- Name: COLUMN sys_login_log.version; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_login_log.version IS '乐观锁版本号';


--
-- Name: COLUMN sys_login_log.ip_address; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_login_log.ip_address IS '登录IP地址';


--
-- Name: COLUMN sys_login_log.user_agent; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_login_log.user_agent IS '客户端User-Agent';


--
-- Name: COLUMN sys_login_log.login_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_login_log.login_time IS '登录时间';


--
-- Name: COLUMN sys_login_log.message; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_login_log.message IS '提示消息';


--
-- Name: sys_menu; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sys_menu (
    id bigint NOT NULL,
    parent_id bigint DEFAULT 0 NOT NULL,
    name character varying(64) NOT NULL,
    path character varying(200) DEFAULT ''::character varying NOT NULL,
    component character varying(200) DEFAULT ''::character varying NOT NULL,
    icon character varying(100) DEFAULT ''::character varying NOT NULL,
    sort integer DEFAULT 0 NOT NULL,
    menu_type smallint DEFAULT 0 NOT NULL,
    permission character varying(100) DEFAULT ''::character varying NOT NULL,
    visible smallint DEFAULT 1 NOT NULL,
    tenant_id bigint DEFAULT 0 NOT NULL,
    created_by bigint DEFAULT 0 NOT NULL,
    created_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by bigint DEFAULT 0 NOT NULL,
    updated_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    version integer DEFAULT 1 NOT NULL
);


--
-- Name: sys_notice; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sys_notice (
    id bigint NOT NULL,
    notice_title character varying(255) DEFAULT ''::character varying NOT NULL,
    notice_type smallint DEFAULT 1 NOT NULL,
    notice_content text,
    status smallint DEFAULT 0 NOT NULL,
    publish_time timestamp without time zone,
    tenant_id bigint DEFAULT 0 NOT NULL,
    created_by bigint DEFAULT 0 NOT NULL,
    created_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by bigint DEFAULT 0 NOT NULL,
    updated_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    version integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE sys_notice; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.sys_notice IS '系统通知/公告表';


--
-- Name: COLUMN sys_notice.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_notice.id IS '主键ID（Snowflake）';


--
-- Name: COLUMN sys_notice.notice_title; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_notice.notice_title IS '通知标题';


--
-- Name: COLUMN sys_notice.notice_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_notice.notice_type IS '通知类型：1-通知,2-公告';


--
-- Name: COLUMN sys_notice.notice_content; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_notice.notice_content IS '通知内容';


--
-- Name: COLUMN sys_notice.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_notice.status IS '状态：0-草稿,1-已发布,2-已撤回';


--
-- Name: COLUMN sys_notice.publish_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_notice.publish_time IS '发布时间';


--
-- Name: COLUMN sys_notice.tenant_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_notice.tenant_id IS '租户ID，由 TenantLineInterceptor 自动注入';


--
-- Name: COLUMN sys_notice.deleted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_notice.deleted IS '软删除标志';


--
-- Name: COLUMN sys_notice.version; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_notice.version IS '乐观锁版本号';


--
-- Name: sys_notice_user; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sys_notice_user (
    id bigint NOT NULL,
    notice_id bigint NOT NULL,
    user_id bigint NOT NULL,
    read_time timestamp with time zone,
    tenant_id bigint DEFAULT 0 NOT NULL,
    created_by bigint DEFAULT 0 NOT NULL,
    created_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by bigint DEFAULT 0 NOT NULL,
    updated_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    version integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE sys_notice_user; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.sys_notice_user IS '通知用户关联表（记录已读状态）';


--
-- Name: COLUMN sys_notice_user.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_notice_user.id IS '记录ID（Snowflake）';


--
-- Name: COLUMN sys_notice_user.notice_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_notice_user.notice_id IS '通知ID';


--
-- Name: COLUMN sys_notice_user.user_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_notice_user.user_id IS '用户ID';


--
-- Name: COLUMN sys_notice_user.read_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_notice_user.read_time IS '阅读时间，NULL 表示未读';


--
-- Name: COLUMN sys_notice_user.tenant_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_notice_user.tenant_id IS '租户ID，由 TenantLineInterceptor 自动注入';


--
-- Name: COLUMN sys_notice_user.deleted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_notice_user.deleted IS '软删除标志';


--
-- Name: COLUMN sys_notice_user.version; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_notice_user.version IS '乐观锁版本号';


--
-- Name: sys_operation_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sys_operation_log (
    id bigint NOT NULL,
    title character varying(255) DEFAULT ''::character varying NOT NULL,
    business_type smallint DEFAULT 0 NOT NULL,
    method character varying(255) DEFAULT ''::character varying NOT NULL,
    request_method character varying(10) DEFAULT ''::character varying NOT NULL,
    request_url character varying(500) DEFAULT ''::character varying NOT NULL,
    request_param text,
    response_result text,
    status smallint DEFAULT 0 NOT NULL,
    error_msg character varying(2000),
    operator_id bigint DEFAULT 0 NOT NULL,
    operator_name character varying(100) DEFAULT ''::character varying NOT NULL,
    operator_ip character varying(50) DEFAULT ''::character varying NOT NULL,
    cost_time bigint DEFAULT 0 NOT NULL,
    tenant_id bigint DEFAULT 0 NOT NULL,
    created_by bigint DEFAULT 0 NOT NULL,
    created_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by bigint DEFAULT 0 NOT NULL,
    updated_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    version integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE sys_operation_log; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.sys_operation_log IS '操作日志表';


--
-- Name: COLUMN sys_operation_log.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_operation_log.id IS '主键ID（Snowflake）';


--
-- Name: COLUMN sys_operation_log.title; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_operation_log.title IS '操作模块/描述';


--
-- Name: COLUMN sys_operation_log.business_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_operation_log.business_type IS '业务类型：0-其他,1-新增,2-修改,3-删除,4-查询,5-导出';


--
-- Name: COLUMN sys_operation_log.method; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_operation_log.method IS '请求方法全限定名';


--
-- Name: COLUMN sys_operation_log.request_method; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_operation_log.request_method IS 'HTTP请求方式';


--
-- Name: COLUMN sys_operation_log.request_url; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_operation_log.request_url IS '请求URL';


--
-- Name: COLUMN sys_operation_log.request_param; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_operation_log.request_param IS '请求参数（超4096字节截断，已脱敏）';


--
-- Name: COLUMN sys_operation_log.response_result; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_operation_log.response_result IS '返回参数（超4096字节截断）';


--
-- Name: COLUMN sys_operation_log.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_operation_log.status IS '操作状态：0-正常,1-异常';


--
-- Name: COLUMN sys_operation_log.error_msg; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_operation_log.error_msg IS '错误消息';


--
-- Name: COLUMN sys_operation_log.operator_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_operation_log.operator_id IS '操作人员ID';


--
-- Name: COLUMN sys_operation_log.operator_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_operation_log.operator_name IS '操作人员账号';


--
-- Name: COLUMN sys_operation_log.operator_ip; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_operation_log.operator_ip IS '操作人员IP';


--
-- Name: COLUMN sys_operation_log.cost_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_operation_log.cost_time IS '操作耗时（毫秒）';


--
-- Name: COLUMN sys_operation_log.tenant_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_operation_log.tenant_id IS '租户ID，由 TenantLineInterceptor 自动注入';


--
-- Name: COLUMN sys_operation_log.deleted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_operation_log.deleted IS '软删除标志';


--
-- Name: COLUMN sys_operation_log.version; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_operation_log.version IS '乐观锁版本号';


--
-- Name: sys_outbox_event; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sys_outbox_event (
    id bigint NOT NULL,
    aggregate_type character varying(100) NOT NULL,
    aggregate_id bigint NOT NULL,
    event_type character varying(100) NOT NULL,
    payload jsonb NOT NULL,
    status character varying(20) NOT NULL,
    retry_count integer DEFAULT 0 NOT NULL,
    max_retry integer DEFAULT 3 NOT NULL,
    next_retry_time timestamp without time zone,
    sent_time timestamp without time zone,
    error_message text,
    tenant_id bigint DEFAULT 0 NOT NULL,
    created_by bigint DEFAULT 0 NOT NULL,
    created_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by bigint DEFAULT 0 NOT NULL,
    updated_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    version integer DEFAULT 1 NOT NULL
);


--
-- Name: sys_permission; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sys_permission (
    id bigint NOT NULL,
    code character varying(100) NOT NULL,
    name character varying(200),
    remark character varying(500),
    tenant_id bigint DEFAULT 0 NOT NULL,
    created_by bigint DEFAULT 0 NOT NULL,
    created_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by bigint DEFAULT 0 NOT NULL,
    updated_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    version integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE sys_permission; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.sys_permission IS '权限表（resource:action 格式）';


--
-- Name: COLUMN sys_permission.code; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_permission.code IS '权限字符串，如 user:read';


--
-- Name: COLUMN sys_permission.deleted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_permission.deleted IS '软删除标志';


--
-- Name: COLUMN sys_permission.version; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_permission.version IS '乐观锁版本号';


--
-- Name: sys_role; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sys_role (
    id bigint NOT NULL,
    name character varying(100) NOT NULL,
    code character varying(50) NOT NULL,
    status smallint DEFAULT 1 NOT NULL,
    remark character varying(500),
    tenant_id bigint DEFAULT 0 NOT NULL,
    created_by bigint DEFAULT 0 NOT NULL,
    created_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by bigint DEFAULT 0 NOT NULL,
    updated_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    version integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE sys_role; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.sys_role IS '角色表';


--
-- Name: COLUMN sys_role.code; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_role.code IS '角色编码（租户内唯一）';


--
-- Name: COLUMN sys_role.deleted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_role.deleted IS '软删除标志';


--
-- Name: COLUMN sys_role.version; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_role.version IS '乐观锁版本号';


--
-- Name: sys_role_permission; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sys_role_permission (
    id bigint NOT NULL,
    role_id bigint NOT NULL,
    permission_id bigint NOT NULL,
    tenant_id bigint DEFAULT 0 NOT NULL,
    created_by bigint DEFAULT 0 NOT NULL,
    created_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by bigint DEFAULT 0 NOT NULL,
    updated_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    version integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE sys_role_permission; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.sys_role_permission IS '角色-权限关联表';


--
-- Name: sys_task_execution_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sys_task_execution_log (
    id bigint NOT NULL,
    task_name character varying(100) NOT NULL,
    task_group character varying(50) NOT NULL,
    task_params text,
    status character varying(20) NOT NULL,
    start_time timestamp without time zone NOT NULL,
    end_time timestamp without time zone,
    duration integer,
    result text,
    error_message text,
    error_stack text,
    server_ip character varying(50),
    server_name character varying(100),
    tenant_id bigint DEFAULT 0 NOT NULL,
    created_by bigint DEFAULT 0 NOT NULL,
    created_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by bigint DEFAULT 0 NOT NULL,
    updated_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    version integer DEFAULT 1 NOT NULL
)
PARTITION BY RANGE (start_time);


--
-- Name: sys_task_execution_log_2026_03; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sys_task_execution_log_2026_03 (
    id bigint NOT NULL,
    task_name character varying(100) NOT NULL,
    task_group character varying(50) NOT NULL,
    task_params text,
    status character varying(20) NOT NULL,
    start_time timestamp without time zone NOT NULL,
    end_time timestamp without time zone,
    duration integer,
    result text,
    error_message text,
    error_stack text,
    server_ip character varying(50),
    server_name character varying(100),
    tenant_id bigint DEFAULT 0 NOT NULL,
    created_by bigint DEFAULT 0 NOT NULL,
    created_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by bigint DEFAULT 0 NOT NULL,
    updated_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    version integer DEFAULT 1 NOT NULL
);


--
-- Name: sys_task_execution_log_2026_04; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sys_task_execution_log_2026_04 (
    id bigint NOT NULL,
    task_name character varying(100) NOT NULL,
    task_group character varying(50) NOT NULL,
    task_params text,
    status character varying(20) NOT NULL,
    start_time timestamp without time zone NOT NULL,
    end_time timestamp without time zone,
    duration integer,
    result text,
    error_message text,
    error_stack text,
    server_ip character varying(50),
    server_name character varying(100),
    tenant_id bigint DEFAULT 0 NOT NULL,
    created_by bigint DEFAULT 0 NOT NULL,
    created_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by bigint DEFAULT 0 NOT NULL,
    updated_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    version integer DEFAULT 1 NOT NULL
);


--
-- Name: sys_task_execution_log_2026_05; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sys_task_execution_log_2026_05 (
    id bigint NOT NULL,
    task_name character varying(100) NOT NULL,
    task_group character varying(50) NOT NULL,
    task_params text,
    status character varying(20) NOT NULL,
    start_time timestamp without time zone NOT NULL,
    end_time timestamp without time zone,
    duration integer,
    result text,
    error_message text,
    error_stack text,
    server_ip character varying(50),
    server_name character varying(100),
    tenant_id bigint DEFAULT 0 NOT NULL,
    created_by bigint DEFAULT 0 NOT NULL,
    created_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by bigint DEFAULT 0 NOT NULL,
    updated_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    version integer DEFAULT 1 NOT NULL
);


--
-- Name: sys_task_execution_log_2026_06; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sys_task_execution_log_2026_06 (
    id bigint NOT NULL,
    task_name character varying(100) NOT NULL,
    task_group character varying(50) NOT NULL,
    task_params text,
    status character varying(20) NOT NULL,
    start_time timestamp without time zone NOT NULL,
    end_time timestamp without time zone,
    duration integer,
    result text,
    error_message text,
    error_stack text,
    server_ip character varying(50),
    server_name character varying(100),
    tenant_id bigint DEFAULT 0 NOT NULL,
    created_by bigint DEFAULT 0 NOT NULL,
    created_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by bigint DEFAULT 0 NOT NULL,
    updated_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    version integer DEFAULT 1 NOT NULL
);


--
-- Name: sys_tenant; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sys_tenant (
    id bigint NOT NULL,
    name character varying(100) NOT NULL,
    code character varying(50) NOT NULL,
    status smallint DEFAULT 1 NOT NULL,
    remark character varying(500),
    tenant_id bigint DEFAULT 0 NOT NULL,
    created_by bigint DEFAULT 0 NOT NULL,
    created_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by bigint DEFAULT 0 NOT NULL,
    updated_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    version integer DEFAULT 1 NOT NULL,
    package_id bigint DEFAULT 0 NOT NULL
);


--
-- Name: TABLE sys_tenant; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.sys_tenant IS '租户表';


--
-- Name: COLUMN sys_tenant.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_tenant.id IS '租户ID（Snowflake）';


--
-- Name: COLUMN sys_tenant.name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_tenant.name IS '租户名称';


--
-- Name: COLUMN sys_tenant.code; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_tenant.code IS '租户唯一编码';


--
-- Name: COLUMN sys_tenant.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_tenant.status IS '状态：1-启用，0-禁用';


--
-- Name: COLUMN sys_tenant.tenant_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_tenant.tenant_id IS '所属租户（自身为0，表示系统级）';


--
-- Name: COLUMN sys_tenant.deleted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_tenant.deleted IS '软删除标志';


--
-- Name: COLUMN sys_tenant.version; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_tenant.version IS '乐观锁版本号';


--
-- Name: COLUMN sys_tenant.package_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_tenant.package_id IS '关联套餐ID';


--
-- Name: sys_tenant_package; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sys_tenant_package (
    id bigint NOT NULL,
    name character varying(64) NOT NULL,
    menu_ids text DEFAULT ''::text NOT NULL,
    max_users integer DEFAULT 100 NOT NULL,
    max_storage_mb integer DEFAULT 1024 NOT NULL,
    status smallint DEFAULT 1 NOT NULL,
    tenant_id bigint DEFAULT 0 NOT NULL,
    created_by bigint DEFAULT 0 NOT NULL,
    created_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by bigint DEFAULT 0 NOT NULL,
    updated_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    version integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE sys_tenant_package; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.sys_tenant_package IS '租户套餐表';


--
-- Name: COLUMN sys_tenant_package.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_tenant_package.id IS '套餐ID（Snowflake）';


--
-- Name: COLUMN sys_tenant_package.name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_tenant_package.name IS '套餐名称';


--
-- Name: COLUMN sys_tenant_package.menu_ids; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_tenant_package.menu_ids IS '菜单ID列表（逗号分隔）';


--
-- Name: COLUMN sys_tenant_package.max_users; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_tenant_package.max_users IS '最大用户数';


--
-- Name: COLUMN sys_tenant_package.max_storage_mb; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_tenant_package.max_storage_mb IS '最大存储空间（MB）';


--
-- Name: COLUMN sys_tenant_package.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_tenant_package.status IS '状态：1=正常，0=停用';


--
-- Name: COLUMN sys_tenant_package.tenant_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_tenant_package.tenant_id IS '租户ID，由 TenantLineInterceptor 自动注入';


--
-- Name: COLUMN sys_tenant_package.deleted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_tenant_package.deleted IS '软删除标志';


--
-- Name: COLUMN sys_tenant_package.version; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_tenant_package.version IS '乐观锁版本号';


--
-- Name: sys_user; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sys_user (
    id bigint NOT NULL,
    username character varying(50) NOT NULL,
    password character varying(255) NOT NULL,
    nickname character varying(100),
    email character varying(100),
    phone character varying(20),
    avatar character varying(500),
    status smallint DEFAULT 1 NOT NULL,
    tenant_id bigint DEFAULT 0 NOT NULL,
    created_by bigint DEFAULT 0 NOT NULL,
    created_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by bigint DEFAULT 0 NOT NULL,
    updated_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    version integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE sys_user; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.sys_user IS '用户表';


--
-- Name: COLUMN sys_user.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_user.id IS '用户ID（Snowflake）';


--
-- Name: COLUMN sys_user.username; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_user.username IS '登录用户名（租户内唯一）';


--
-- Name: COLUMN sys_user.password; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_user.password IS 'BCrypt(cost=10) 密码哈希';


--
-- Name: COLUMN sys_user.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_user.status IS '状态：1-启用，0-禁用';


--
-- Name: COLUMN sys_user.deleted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_user.deleted IS '软删除标志';


--
-- Name: COLUMN sys_user.version; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sys_user.version IS '乐观锁版本号';


--
-- Name: sys_user_role; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sys_user_role (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    role_id bigint NOT NULL,
    tenant_id bigint DEFAULT 0 NOT NULL,
    created_by bigint DEFAULT 0 NOT NULL,
    created_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by bigint DEFAULT 0 NOT NULL,
    updated_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    version integer DEFAULT 1 NOT NULL
);


--
-- Name: TABLE sys_user_role; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.sys_user_role IS '用户-角色关联表';


--
-- Name: sys_webhook_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sys_webhook_config (
    id bigint NOT NULL,
    webhook_name character varying(100) NOT NULL,
    webhook_url character varying(500) NOT NULL,
    event_types text NOT NULL,
    secret_key character varying(128) NOT NULL,
    status character varying(20) NOT NULL,
    retry_count integer DEFAULT 5 NOT NULL,
    timeout_seconds integer DEFAULT 5 NOT NULL,
    tenant_id bigint DEFAULT 0 NOT NULL,
    created_by bigint DEFAULT 0 NOT NULL,
    created_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by bigint DEFAULT 0 NOT NULL,
    updated_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    version integer DEFAULT 1 NOT NULL
);


--
-- Name: sys_webhook_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sys_webhook_log (
    id bigint NOT NULL,
    webhook_id bigint NOT NULL,
    event_type character varying(50) NOT NULL,
    event_data text NOT NULL,
    request_url character varying(500) NOT NULL,
    request_headers text,
    request_body text NOT NULL,
    response_status integer,
    response_body text,
    retry_times integer DEFAULT 0 NOT NULL,
    status character varying(20) NOT NULL,
    error_message text,
    tenant_id bigint DEFAULT 0 NOT NULL,
    created_by bigint DEFAULT 0 NOT NULL,
    created_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by bigint DEFAULT 0 NOT NULL,
    updated_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    version integer DEFAULT 1 NOT NULL
);


--
-- Name: sys_task_execution_log_2026_03; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sys_task_execution_log ATTACH PARTITION public.sys_task_execution_log_2026_03 FOR VALUES FROM ('2026-03-01 00:00:00') TO ('2026-04-01 00:00:00');


--
-- Name: sys_task_execution_log_2026_04; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sys_task_execution_log ATTACH PARTITION public.sys_task_execution_log_2026_04 FOR VALUES FROM ('2026-04-01 00:00:00') TO ('2026-05-01 00:00:00');


--
-- Name: sys_task_execution_log_2026_05; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sys_task_execution_log ATTACH PARTITION public.sys_task_execution_log_2026_05 FOR VALUES FROM ('2026-05-01 00:00:00') TO ('2026-06-01 00:00:00');


--
-- Name: sys_task_execution_log_2026_06; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sys_task_execution_log ATTACH PARTITION public.sys_task_execution_log_2026_06 FOR VALUES FROM ('2026-06-01 00:00:00') TO ('2026-07-01 00:00:00');


--
-- Data for Name: cache_invalidation_event; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.cache_invalidation_event (id, cache_name, cache_key, event_type, source_pod, tenant_id, created_by, created_time, updated_by, updated_time, deleted, version) FROM stdin;
\.


--
-- Data for Name: msg_record; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.msg_record (id, template_id, message_type, receiver_id, receiver_address, subject, content, send_status, send_time, error_message, tenant_id, created_by, created_time, updated_by, updated_time, deleted, version) FROM stdin;
\.


--
-- Data for Name: msg_subscription; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.msg_subscription (id, user_id, template_id, channel, status, preference, tenant_id, created_by, created_time, updated_by, updated_time, deleted, version) FROM stdin;
\.


--
-- Data for Name: msg_user_inbox; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.msg_user_inbox (id, user_id, message_id, title, content, is_read, read_time, tenant_id, created_by, created_time, updated_by, updated_time, deleted, version) FROM stdin;
\.


--
-- Data for Name: open_app_secret; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.open_app_secret (id, app_id, secret_key, secret_version, status, expire_time, tenant_id, created_by, created_time, updated_by, updated_time, deleted, version) FROM stdin;
\.


--
-- Data for Name: qrtz_blob_triggers; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.qrtz_blob_triggers (sched_name, trigger_name, trigger_group, blob_data) FROM stdin;
\.


--
-- Data for Name: qrtz_calendars; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.qrtz_calendars (sched_name, calendar_name, calendar) FROM stdin;
\.


--
-- Data for Name: qrtz_cron_triggers; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.qrtz_cron_triggers (sched_name, trigger_name, trigger_group, cron_expression, time_zone_id) FROM stdin;
\.


--
-- Data for Name: qrtz_fired_triggers; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.qrtz_fired_triggers (sched_name, entry_id, trigger_name, trigger_group, instance_name, fired_time, sched_time, priority, state, job_name, job_group, is_nonconcurrent, requests_recovery) FROM stdin;
\.


--
-- Data for Name: qrtz_job_details; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.qrtz_job_details (sched_name, job_name, job_group, description, job_class_name, is_durable, is_nonconcurrent, is_update_data, requests_recovery, job_data) FROM stdin;
\.


--
-- Data for Name: qrtz_locks; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.qrtz_locks (sched_name, lock_name) FROM stdin;
LjwxScheduler	STATE_ACCESS
LjwxScheduler	TRIGGER_ACCESS
\.


--
-- Data for Name: qrtz_paused_trigger_grps; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.qrtz_paused_trigger_grps (sched_name, trigger_group) FROM stdin;
\.


--
-- Data for Name: qrtz_scheduler_state; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.qrtz_scheduler_state (sched_name, instance_name, last_checkin_time, checkin_interval) FROM stdin;
\.


--
-- Data for Name: qrtz_simple_triggers; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.qrtz_simple_triggers (sched_name, trigger_name, trigger_group, repeat_count, repeat_interval, times_triggered) FROM stdin;
\.


--
-- Data for Name: qrtz_simprop_triggers; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.qrtz_simprop_triggers (sched_name, trigger_name, trigger_group, str_prop_1, str_prop_2, str_prop_3, int_prop_1, int_prop_2, long_prop_1, long_prop_2, dec_prop_1, dec_prop_2, bool_prop_1, bool_prop_2) FROM stdin;
\.


--
-- Data for Name: qrtz_triggers; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.qrtz_triggers (sched_name, trigger_name, trigger_group, job_name, job_group, description, next_fire_time, prev_fire_time, priority, trigger_state, trigger_type, start_time, end_time, calendar_name, misfire_instr, job_data) FROM stdin;
\.


--
-- Data for Name: sys_config; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sys_config (id, config_name, config_key, config_value, config_type, remark, tenant_id, created_by, created_time, updated_by, updated_time, deleted, version) FROM stdin;
2000000001	主框架页-默认皮肤样式名称	sys.index.skinName	skin-blue	1	蓝色 skin-blue、绿色 skin-green、紫色 skin-purple、红色 skin-red、黄色 skin-yellow	1	1	2026-03-02 15:50:28.893091	1	2026-03-02 15:50:28.893091	f	1
2000000002	用户管理-账号初始密码	sys.user.initPassword		1	由环境变量 LJWX_BOOTSTRAP_USER_IMPORT_INITIAL_PASSWORD 提供	1	1	2026-03-02 15:50:28.893091	1	2026-03-02 15:50:28.893091	f	1
2000000003	主框架页-侧边栏主题	sys.index.sideTheme	theme-dark	1	深色主题 theme-dark、浅色主题 theme-light	1	1	2026-03-02 15:50:28.893091	1	2026-03-02 15:50:28.893091	f	1
2000000004	账号自助-是否开启用户注册功能	sys.account.registerUser	false	1	是否开启注册用户功能（true 开启，false 关闭）	1	1	2026-03-02 15:50:28.893091	1	2026-03-02 15:50:28.893091	f	1
2000000005	文件上传-允许的文件后缀	sys.file.allowedSuffix	jpg,jpeg,png,gif,webp,svg,pdf,doc,docx,xls,xlsx,ppt,pptx,txt,csv,zip,rar,7z,mp4,mp3	1	允许上传的文件后缀白名单	1	1	2026-03-02 15:50:28.893091	1	2026-03-02 15:50:28.893091	f	1
\.


--
-- Data for Name: sys_data_change_log; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sys_data_change_log (id, table_name, record_id, field_name, old_value, new_value, operate_type, tenant_id, created_by, created_time, updated_by, updated_time, deleted, version) FROM stdin;
\.


--
-- Data for Name: sys_dept; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sys_dept (id, parent_id, name, sort, leader, phone, email, status, tenant_id, created_by, created_time, updated_by, updated_time, deleted, version) FROM stdin;
1	0	总公司	0	管理员			1	1	1	2026-03-02 15:50:29.04158	1	2026-03-02 15:50:29.04158	f	1
2	1	技术部	1				1	1	1	2026-03-02 15:50:29.04158	1	2026-03-02 15:50:29.04158	f	1
3	1	市场部	2				1	1	1	2026-03-02 15:50:29.04158	1	2026-03-02 15:50:29.04158	f	1
4	1	财务部	3				1	1	1	2026-03-02 15:50:29.04158	1	2026-03-02 15:50:29.04158	f	1
\.


--
-- Data for Name: sys_dict_data; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sys_dict_data (id, dict_type, dict_label, dict_value, sort_order, status, css_class, list_class, is_default, remark, tenant_id, created_by, created_time, updated_by, updated_time, deleted, version) FROM stdin;
1910000001	sys_user_sex	男	0	0	1	\N	\N	t	\N	1	1	2026-03-02 15:50:28.86847	1	2026-03-02 15:50:28.86847	f	1
1910000002	sys_user_sex	女	1	1	1	\N	\N	f	\N	1	1	2026-03-02 15:50:28.86847	1	2026-03-02 15:50:28.86847	f	1
1910000003	sys_user_sex	未知	2	2	1	\N	\N	f	\N	1	1	2026-03-02 15:50:28.86847	1	2026-03-02 15:50:28.86847	f	1
1910000004	sys_show_hide	显示	0	0	1	\N	\N	t	\N	1	1	2026-03-02 15:50:28.869106	1	2026-03-02 15:50:28.869106	f	1
1910000005	sys_show_hide	隐藏	1	1	1	\N	\N	f	\N	1	1	2026-03-02 15:50:28.869106	1	2026-03-02 15:50:28.869106	f	1
1910000006	sys_normal_disable	正常	0	0	1	\N	\N	t	\N	1	1	2026-03-02 15:50:28.869384	1	2026-03-02 15:50:28.869384	f	1
1910000007	sys_normal_disable	停用	1	1	1	\N	\N	f	\N	1	1	2026-03-02 15:50:28.869384	1	2026-03-02 15:50:28.869384	f	1
1910000008	sys_job_status	正常	1	0	1	\N	\N	t	\N	1	1	2026-03-02 15:50:28.869648	1	2026-03-02 15:50:28.869648	f	1
1910000009	sys_job_status	暂停	0	1	1	\N	\N	f	\N	1	1	2026-03-02 15:50:28.869648	1	2026-03-02 15:50:28.869648	f	1
1910000010	sys_notice_type	通知	1	0	1	\N	\N	t	\N	1	1	2026-03-02 15:50:28.869862	1	2026-03-02 15:50:28.869862	f	1
1910000011	sys_notice_type	公告	2	1	1	\N	\N	f	\N	1	1	2026-03-02 15:50:28.869862	1	2026-03-02 15:50:28.869862	f	1
\.


--
-- Data for Name: sys_dict_type; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sys_dict_type (id, dict_name, dict_type, status, remark, tenant_id, created_by, created_time, updated_by, updated_time, deleted, version) FROM stdin;
1900000001	用户性别	sys_user_sex	1	用户性别列表	1	1	2026-03-02 15:50:28.867105	1	2026-03-02 15:50:28.867105	f	1
1900000002	菜单状态	sys_show_hide	1	菜单状态列表	1	1	2026-03-02 15:50:28.867105	1	2026-03-02 15:50:28.867105	f	1
1900000003	系统开关	sys_normal_disable	1	系统开关列表	1	1	2026-03-02 15:50:28.867105	1	2026-03-02 15:50:28.867105	f	1
1900000004	任务状态	sys_job_status	1	任务状态列表	1	1	2026-03-02 15:50:28.867105	1	2026-03-02 15:50:28.867105	f	1
1900000005	通知类型	sys_notice_type	1	通知类型列表	1	1	2026-03-02 15:50:28.867105	1	2026-03-02 15:50:28.867105	f	1
\.


--
-- Data for Name: sys_file; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sys_file (id, file_name, file_path, file_size, file_type, content_type, tenant_id, created_by, created_time, updated_by, updated_time, deleted, version) FROM stdin;
\.


--
-- Data for Name: sys_frontend_error; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sys_frontend_error (id, error_message, stack_trace, page_url, user_agent, tenant_id, created_by, created_time, updated_by, updated_time, deleted, version) FROM stdin;
\.


--
-- Data for Name: sys_import_export_task; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sys_import_export_task (id, task_type, business_type, file_name, file_url, status, total_count, success_count, failure_count, error_message, tenant_id, created_by, created_time, updated_by, updated_time, deleted, version) FROM stdin;
\.


--
-- Data for Name: sys_job; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sys_job (id, job_name, job_group, job_class_name, cron_expression, description, status, tenant_id, created_by, created_time, updated_by, updated_time, deleted, version) FROM stdin;
\.


--
-- Data for Name: sys_login_log; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sys_login_log (id, username, ip, location, browser, os, status, msg, tenant_id, created_by, created_time, updated_by, updated_time, deleted, version, ip_address, user_agent, login_time, message) FROM stdin;
\.


--
-- Data for Name: sys_menu; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sys_menu (id, parent_id, name, path, component, icon, sort, menu_type, permission, visible, tenant_id, created_by, created_time, updated_by, updated_time, deleted, version) FROM stdin;
1	0	系统管理	/system		Setting	1	0		1	1	0	2026-03-02 15:50:28.988265	0	2026-03-02 15:50:28.988265	f	1
2	1	用户管理	/system/user	system/user/index	User	1	1	user:read	1	1	0	2026-03-02 15:50:28.988265	0	2026-03-02 15:50:28.988265	f	1
3	1	角色管理	/system/role	system/role/index	UserFilled	2	1	role:read	1	1	0	2026-03-02 15:50:28.988265	0	2026-03-02 15:50:28.988265	f	1
4	1	菜单管理	/system/menu	system/menu/index	Menu	3	1	system:menu:list	1	1	0	2026-03-02 15:50:28.988265	0	2026-03-02 15:50:28.988265	f	1
5	1	部门管理	/system/dept	system/dept/index	OfficeBuilding	4	1		1	1	0	2026-03-02 15:50:28.988265	0	2026-03-02 15:50:28.988265	f	1
6	1	字典管理	/system/dict	system/dict/index	Collection	5	1	dict:read	1	1	0	2026-03-02 15:50:28.988265	0	2026-03-02 15:50:28.988265	f	1
7	1	配置管理	/system/config	system/config/index	Tools	6	1	config:read	1	1	0	2026-03-02 15:50:28.988265	0	2026-03-02 15:50:28.988265	f	1
8	1	日志管理	/system/log	system/log/index	Document	7	1	log:read	1	1	0	2026-03-02 15:50:28.988265	0	2026-03-02 15:50:28.988265	f	1
9	1	文件管理	/system/file	system/file/index	FolderOpened	8	1	file:read	1	1	0	2026-03-02 15:50:28.988265	0	2026-03-02 15:50:28.988265	f	1
10	1	公告管理	/system/notice	system/notice/index	Bell	9	1	notice:read	1	1	0	2026-03-02 15:50:28.988265	0	2026-03-02 15:50:28.988265	f	1
\.


--
-- Data for Name: sys_notice; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sys_notice (id, notice_title, notice_type, notice_content, status, publish_time, tenant_id, created_by, created_time, updated_by, updated_time, deleted, version) FROM stdin;
\.


--
-- Data for Name: sys_notice_user; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sys_notice_user (id, notice_id, user_id, read_time, tenant_id, created_by, created_time, updated_by, updated_time, deleted, version) FROM stdin;
\.


--
-- Data for Name: sys_operation_log; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sys_operation_log (id, title, business_type, method, request_method, request_url, request_param, response_result, status, error_msg, operator_id, operator_name, operator_ip, cost_time, tenant_id, created_by, created_time, updated_by, updated_time, deleted, version) FROM stdin;
\.


--
-- Data for Name: sys_outbox_event; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sys_outbox_event (id, aggregate_type, aggregate_id, event_type, payload, status, retry_count, max_retry, next_retry_time, sent_time, error_message, tenant_id, created_by, created_time, updated_by, updated_time, deleted, version) FROM stdin;
\.


--
-- Data for Name: sys_permission; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sys_permission (id, code, name, remark, tenant_id, created_by, created_time, updated_by, updated_time, deleted, version) FROM stdin;
1	user:read	用户查询	\N	1	0	2026-03-02 15:50:28.487662	0	2026-03-02 15:50:28.487662	f	1
2	user:write	用户管理	\N	1	0	2026-03-02 15:50:28.487662	0	2026-03-02 15:50:28.487662	f	1
3	user:delete	用户删除	\N	1	0	2026-03-02 15:50:28.487662	0	2026-03-02 15:50:28.487662	f	1
4	role:read	角色查询	\N	1	0	2026-03-02 15:50:28.487662	0	2026-03-02 15:50:28.487662	f	1
5	role:write	角色管理	\N	1	0	2026-03-02 15:50:28.487662	0	2026-03-02 15:50:28.487662	f	1
6	role:delete	角色删除	\N	1	0	2026-03-02 15:50:28.487662	0	2026-03-02 15:50:28.487662	f	1
7	tenant:read	租户查询	\N	1	0	2026-03-02 15:50:28.487662	0	2026-03-02 15:50:28.487662	f	1
8	tenant:write	租户管理	\N	1	0	2026-03-02 15:50:28.487662	0	2026-03-02 15:50:28.487662	f	1
9	job:read	定时任务查询	\N	1	0	2026-03-02 15:50:28.487662	0	2026-03-02 15:50:28.487662	f	1
10	job:write	定时任务管理	\N	1	0	2026-03-02 15:50:28.487662	0	2026-03-02 15:50:28.487662	f	1
11	job:execute	定时任务执行	\N	1	0	2026-03-02 15:50:28.487662	0	2026-03-02 15:50:28.487662	f	1
12	dict:read	字典查询	\N	1	0	2026-03-02 15:50:28.487662	0	2026-03-02 15:50:28.487662	f	1
13	dict:write	字典管理	\N	1	0	2026-03-02 15:50:28.487662	0	2026-03-02 15:50:28.487662	f	1
14	config:read	配置查询	\N	1	0	2026-03-02 15:50:28.487662	0	2026-03-02 15:50:28.487662	f	1
15	config:write	配置管理	\N	1	0	2026-03-02 15:50:28.487662	0	2026-03-02 15:50:28.487662	f	1
16	log:read	日志查询	\N	1	0	2026-03-02 15:50:28.487662	0	2026-03-02 15:50:28.487662	f	1
17	log:export	日志导出	\N	1	0	2026-03-02 15:50:28.487662	0	2026-03-02 15:50:28.487662	f	1
18	file:read	文件查询	\N	1	0	2026-03-02 15:50:28.487662	0	2026-03-02 15:50:28.487662	f	1
19	file:upload	文件上传	\N	1	0	2026-03-02 15:50:28.487662	0	2026-03-02 15:50:28.487662	f	1
20	file:delete	文件删除	\N	1	0	2026-03-02 15:50:28.487662	0	2026-03-02 15:50:28.487662	f	1
21	notice:read	通知查询	\N	1	0	2026-03-02 15:50:28.487662	0	2026-03-02 15:50:28.487662	f	1
22	notice:write	通知管理	\N	1	0	2026-03-02 15:50:28.487662	0	2026-03-02 15:50:28.487662	f	1
23	screen:read	大屏查询	\N	1	0	2026-03-02 15:50:28.487662	0	2026-03-02 15:50:28.487662	f	1
24	system:menu:list	菜单查询	\N	1	0	2026-03-02 15:50:28.986186	0	2026-03-02 15:50:28.986186	f	1
25	system:menu:detail	菜单详情	\N	1	0	2026-03-02 15:50:28.986186	0	2026-03-02 15:50:28.986186	f	1
26	system:menu:create	菜单新增	\N	1	0	2026-03-02 15:50:28.986186	0	2026-03-02 15:50:28.986186	f	1
27	system:menu:update	菜单修改	\N	1	0	2026-03-02 15:50:28.986186	0	2026-03-02 15:50:28.986186	f	1
28	system:menu:delete	菜单删除	\N	1	0	2026-03-02 15:50:28.986186	0	2026-03-02 15:50:28.986186	f	1
29	system:dept:list	部门查询	\N	1	0	2026-03-02 15:50:29.152546	0	2026-03-02 15:50:29.152546	f	1
30	system:dept:detail	部门详情	\N	1	0	2026-03-02 15:50:29.152546	0	2026-03-02 15:50:29.152546	f	1
31	system:dept:create	部门新增	\N	1	0	2026-03-02 15:50:29.152546	0	2026-03-02 15:50:29.152546	f	1
32	system:dept:update	部门修改	\N	1	0	2026-03-02 15:50:29.152546	0	2026-03-02 15:50:29.152546	f	1
33	system:dept:delete	部门删除	\N	1	0	2026-03-02 15:50:29.152546	0	2026-03-02 15:50:29.152546	f	1
34	system:monitor:server	服务器监控	\N	1	0	2026-03-02 15:50:29.152546	0	2026-03-02 15:50:29.152546	f	1
35	system:monitor:jvm	JVM监控	\N	1	0	2026-03-02 15:50:29.152546	0	2026-03-02 15:50:29.152546	f	1
36	system:monitor:cache	缓存监控	\N	1	0	2026-03-02 15:50:29.152546	0	2026-03-02 15:50:29.152546	f	1
37	system:online:list	在线用户查询	\N	1	0	2026-03-02 15:50:29.152546	0	2026-03-02 15:50:29.152546	f	1
38	system:online:kickout	强制下线	\N	1	0	2026-03-02 15:50:29.152546	0	2026-03-02 15:50:29.152546	f	1
39	system:log:login:list	登录日志查询	\N	1	0	2026-03-02 15:50:29.152546	0	2026-03-02 15:50:29.152546	f	1
40	system:tenant-package:list	套餐查询	\N	1	0	2026-03-02 15:50:29.152546	0	2026-03-02 15:50:29.152546	f	1
41	system:tenant-package:detail	套餐详情	\N	1	0	2026-03-02 15:50:29.152546	0	2026-03-02 15:50:29.152546	f	1
42	system:tenant-package:create	套餐新增	\N	1	0	2026-03-02 15:50:29.152546	0	2026-03-02 15:50:29.152546	f	1
43	system:tenant-package:update	套餐修改	\N	1	0	2026-03-02 15:50:29.152546	0	2026-03-02 15:50:29.152546	f	1
44	system:tenant-package:delete	套餐删除	\N	1	0	2026-03-02 15:50:29.152546	0	2026-03-02 15:50:29.152546	f	1
45	system:user:export	用户导出	\N	1	0	2026-03-02 15:50:29.152546	0	2026-03-02 15:50:29.152546	f	1
46	system:user:import	用户导入	\N	1	0	2026-03-02 15:50:29.152546	0	2026-03-02 15:50:29.152546	f	1
47	system:notice:read	通知已读	\N	1	0	2026-03-02 15:50:29.152546	0	2026-03-02 15:50:29.152546	f	1
48	system:notice:list	通知未读数	\N	1	0	2026-03-02 15:50:29.152546	0	2026-03-02 15:50:29.152546	f	1
\.


--
-- Data for Name: sys_role; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sys_role (id, name, code, status, remark, tenant_id, created_by, created_time, updated_by, updated_time, deleted, version) FROM stdin;
1	超级管理员	ADMIN	1	\N	1	0	2026-03-02 15:50:28.510664	0	2026-03-02 15:50:28.510664	f	1
\.


--
-- Data for Name: sys_role_permission; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sys_role_permission (id, role_id, permission_id, tenant_id, created_by, created_time, updated_by, updated_time, deleted, version) FROM stdin;
1	1	1	1	0	2026-03-02 15:50:28.511757	0	2026-03-02 15:50:28.511757	f	1
2	1	2	1	0	2026-03-02 15:50:28.511757	0	2026-03-02 15:50:28.511757	f	1
3	1	3	1	0	2026-03-02 15:50:28.511757	0	2026-03-02 15:50:28.511757	f	1
4	1	4	1	0	2026-03-02 15:50:28.511757	0	2026-03-02 15:50:28.511757	f	1
5	1	5	1	0	2026-03-02 15:50:28.511757	0	2026-03-02 15:50:28.511757	f	1
6	1	6	1	0	2026-03-02 15:50:28.511757	0	2026-03-02 15:50:28.511757	f	1
7	1	7	1	0	2026-03-02 15:50:28.511757	0	2026-03-02 15:50:28.511757	f	1
8	1	8	1	0	2026-03-02 15:50:28.511757	0	2026-03-02 15:50:28.511757	f	1
9	1	9	1	0	2026-03-02 15:50:28.511757	0	2026-03-02 15:50:28.511757	f	1
10	1	10	1	0	2026-03-02 15:50:28.511757	0	2026-03-02 15:50:28.511757	f	1
11	1	11	1	0	2026-03-02 15:50:28.511757	0	2026-03-02 15:50:28.511757	f	1
12	1	12	1	0	2026-03-02 15:50:28.511757	0	2026-03-02 15:50:28.511757	f	1
13	1	13	1	0	2026-03-02 15:50:28.511757	0	2026-03-02 15:50:28.511757	f	1
14	1	14	1	0	2026-03-02 15:50:28.511757	0	2026-03-02 15:50:28.511757	f	1
15	1	15	1	0	2026-03-02 15:50:28.511757	0	2026-03-02 15:50:28.511757	f	1
16	1	16	1	0	2026-03-02 15:50:28.511757	0	2026-03-02 15:50:28.511757	f	1
17	1	17	1	0	2026-03-02 15:50:28.511757	0	2026-03-02 15:50:28.511757	f	1
18	1	18	1	0	2026-03-02 15:50:28.511757	0	2026-03-02 15:50:28.511757	f	1
19	1	19	1	0	2026-03-02 15:50:28.511757	0	2026-03-02 15:50:28.511757	f	1
20	1	20	1	0	2026-03-02 15:50:28.511757	0	2026-03-02 15:50:28.511757	f	1
21	1	21	1	0	2026-03-02 15:50:28.511757	0	2026-03-02 15:50:28.511757	f	1
22	1	22	1	0	2026-03-02 15:50:28.511757	0	2026-03-02 15:50:28.511757	f	1
23	1	23	1	0	2026-03-02 15:50:28.511757	0	2026-03-02 15:50:28.511757	f	1
24	1	24	1	0	2026-03-02 15:50:28.987666	0	2026-03-02 15:50:28.987666	f	1
25	1	25	1	0	2026-03-02 15:50:28.987666	0	2026-03-02 15:50:28.987666	f	1
26	1	26	1	0	2026-03-02 15:50:28.987666	0	2026-03-02 15:50:28.987666	f	1
27	1	27	1	0	2026-03-02 15:50:28.987666	0	2026-03-02 15:50:28.987666	f	1
28	1	28	1	0	2026-03-02 15:50:28.987666	0	2026-03-02 15:50:28.987666	f	1
29	1	29	1	0	2026-03-02 15:50:29.155651	0	2026-03-02 15:50:29.155651	f	1
30	1	30	1	0	2026-03-02 15:50:29.155651	0	2026-03-02 15:50:29.155651	f	1
31	1	31	1	0	2026-03-02 15:50:29.155651	0	2026-03-02 15:50:29.155651	f	1
32	1	32	1	0	2026-03-02 15:50:29.155651	0	2026-03-02 15:50:29.155651	f	1
33	1	33	1	0	2026-03-02 15:50:29.155651	0	2026-03-02 15:50:29.155651	f	1
34	1	34	1	0	2026-03-02 15:50:29.155651	0	2026-03-02 15:50:29.155651	f	1
35	1	35	1	0	2026-03-02 15:50:29.155651	0	2026-03-02 15:50:29.155651	f	1
36	1	36	1	0	2026-03-02 15:50:29.155651	0	2026-03-02 15:50:29.155651	f	1
37	1	37	1	0	2026-03-02 15:50:29.155651	0	2026-03-02 15:50:29.155651	f	1
38	1	38	1	0	2026-03-02 15:50:29.155651	0	2026-03-02 15:50:29.155651	f	1
39	1	39	1	0	2026-03-02 15:50:29.155651	0	2026-03-02 15:50:29.155651	f	1
40	1	40	1	0	2026-03-02 15:50:29.155651	0	2026-03-02 15:50:29.155651	f	1
41	1	41	1	0	2026-03-02 15:50:29.155651	0	2026-03-02 15:50:29.155651	f	1
42	1	42	1	0	2026-03-02 15:50:29.155651	0	2026-03-02 15:50:29.155651	f	1
43	1	43	1	0	2026-03-02 15:50:29.155651	0	2026-03-02 15:50:29.155651	f	1
44	1	44	1	0	2026-03-02 15:50:29.155651	0	2026-03-02 15:50:29.155651	f	1
45	1	45	1	0	2026-03-02 15:50:29.155651	0	2026-03-02 15:50:29.155651	f	1
46	1	46	1	0	2026-03-02 15:50:29.155651	0	2026-03-02 15:50:29.155651	f	1
47	1	47	1	0	2026-03-02 15:50:29.155651	0	2026-03-02 15:50:29.155651	f	1
48	1	48	1	0	2026-03-02 15:50:29.155651	0	2026-03-02 15:50:29.155651	f	1
\.


--
-- Data for Name: sys_task_execution_log_2026_03; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sys_task_execution_log_2026_03 (id, task_name, task_group, task_params, status, start_time, end_time, duration, result, error_message, error_stack, server_ip, server_name, tenant_id, created_by, created_time, updated_by, updated_time, deleted, version) FROM stdin;
\.


--
-- Data for Name: sys_task_execution_log_2026_04; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sys_task_execution_log_2026_04 (id, task_name, task_group, task_params, status, start_time, end_time, duration, result, error_message, error_stack, server_ip, server_name, tenant_id, created_by, created_time, updated_by, updated_time, deleted, version) FROM stdin;
\.


--
-- Data for Name: sys_task_execution_log_2026_05; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sys_task_execution_log_2026_05 (id, task_name, task_group, task_params, status, start_time, end_time, duration, result, error_message, error_stack, server_ip, server_name, tenant_id, created_by, created_time, updated_by, updated_time, deleted, version) FROM stdin;
\.


--
-- Data for Name: sys_task_execution_log_2026_06; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sys_task_execution_log_2026_06 (id, task_name, task_group, task_params, status, start_time, end_time, duration, result, error_message, error_stack, server_ip, server_name, tenant_id, created_by, created_time, updated_by, updated_time, deleted, version) FROM stdin;
\.


--
-- Data for Name: sys_tenant; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sys_tenant (id, name, code, status, remark, tenant_id, created_by, created_time, updated_by, updated_time, deleted, version, package_id) FROM stdin;
1	默认租户	default	1	\N	0	0	2026-03-02 15:50:28.441668	0	2026-03-02 15:50:28.441668	f	1	0
\.


--
-- Data for Name: sys_tenant_package; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sys_tenant_package (id, name, menu_ids, max_users, max_storage_mb, status, tenant_id, created_by, created_time, updated_by, updated_time, deleted, version) FROM stdin;
\.


--
-- Data for Name: sys_user; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sys_user (id, username, password, nickname, email, phone, avatar, status, tenant_id, created_by, created_time, updated_by, updated_time, deleted, version) FROM stdin;
1	admin	$2b$10$uCp2Sw/d8Ipq5FrRNfBUt.FOq8dszFY/XHDumEDk3u5IhrZz1JW9S	系统管理员	\N	\N	\N	1	1	0	2026-03-02 15:50:28.464142	0	2026-03-02 15:50:28.464142	f	1
\.


--
-- Data for Name: sys_user_role; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sys_user_role (id, user_id, role_id, tenant_id, created_by, created_time, updated_by, updated_time, deleted, version) FROM stdin;
1	1	1	1	0	2026-03-02 15:50:28.533996	0	2026-03-02 15:50:28.533996	f	1
\.


--
-- Data for Name: sys_webhook_config; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sys_webhook_config (id, webhook_name, webhook_url, event_types, secret_key, status, retry_count, timeout_seconds, tenant_id, created_by, created_time, updated_by, updated_time, deleted, version) FROM stdin;
\.


--
-- Data for Name: sys_webhook_log; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sys_webhook_log (id, webhook_id, event_type, event_data, request_url, request_headers, request_body, response_status, response_body, retry_times, status, error_message, tenant_id, created_by, created_time, updated_by, updated_time, deleted, version) FROM stdin;
\.


--
-- Name: cache_invalidation_event cache_invalidation_event_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cache_invalidation_event
    ADD CONSTRAINT cache_invalidation_event_pkey PRIMARY KEY (id);


--
-- Name: msg_record msg_record_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.msg_record
    ADD CONSTRAINT msg_record_pkey PRIMARY KEY (id);


--
-- Name: msg_subscription msg_subscription_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.msg_subscription
    ADD CONSTRAINT msg_subscription_pkey PRIMARY KEY (id);


--
-- Name: msg_user_inbox msg_user_inbox_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.msg_user_inbox
    ADD CONSTRAINT msg_user_inbox_pkey PRIMARY KEY (id);


--
-- Name: open_app_secret open_app_secret_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.open_app_secret
    ADD CONSTRAINT open_app_secret_pkey PRIMARY KEY (id);


--
-- Name: qrtz_blob_triggers qrtz_blob_triggers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.qrtz_blob_triggers
    ADD CONSTRAINT qrtz_blob_triggers_pkey PRIMARY KEY (sched_name, trigger_name, trigger_group);


--
-- Name: qrtz_calendars qrtz_calendars_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.qrtz_calendars
    ADD CONSTRAINT qrtz_calendars_pkey PRIMARY KEY (sched_name, calendar_name);


--
-- Name: qrtz_cron_triggers qrtz_cron_triggers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.qrtz_cron_triggers
    ADD CONSTRAINT qrtz_cron_triggers_pkey PRIMARY KEY (sched_name, trigger_name, trigger_group);


--
-- Name: qrtz_fired_triggers qrtz_fired_triggers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.qrtz_fired_triggers
    ADD CONSTRAINT qrtz_fired_triggers_pkey PRIMARY KEY (sched_name, entry_id);


--
-- Name: qrtz_job_details qrtz_job_details_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.qrtz_job_details
    ADD CONSTRAINT qrtz_job_details_pkey PRIMARY KEY (sched_name, job_name, job_group);


--
-- Name: qrtz_locks qrtz_locks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.qrtz_locks
    ADD CONSTRAINT qrtz_locks_pkey PRIMARY KEY (sched_name, lock_name);


--
-- Name: qrtz_paused_trigger_grps qrtz_paused_trigger_grps_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.qrtz_paused_trigger_grps
    ADD CONSTRAINT qrtz_paused_trigger_grps_pkey PRIMARY KEY (sched_name, trigger_group);


--
-- Name: qrtz_scheduler_state qrtz_scheduler_state_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.qrtz_scheduler_state
    ADD CONSTRAINT qrtz_scheduler_state_pkey PRIMARY KEY (sched_name, instance_name);


--
-- Name: qrtz_simple_triggers qrtz_simple_triggers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.qrtz_simple_triggers
    ADD CONSTRAINT qrtz_simple_triggers_pkey PRIMARY KEY (sched_name, trigger_name, trigger_group);


--
-- Name: qrtz_simprop_triggers qrtz_simprop_triggers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.qrtz_simprop_triggers
    ADD CONSTRAINT qrtz_simprop_triggers_pkey PRIMARY KEY (sched_name, trigger_name, trigger_group);


--
-- Name: qrtz_triggers qrtz_triggers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.qrtz_triggers
    ADD CONSTRAINT qrtz_triggers_pkey PRIMARY KEY (sched_name, trigger_name, trigger_group);


--
-- Name: sys_config sys_config_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sys_config
    ADD CONSTRAINT sys_config_pkey PRIMARY KEY (id);


--
-- Name: sys_data_change_log sys_data_change_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sys_data_change_log
    ADD CONSTRAINT sys_data_change_log_pkey PRIMARY KEY (id);


--
-- Name: sys_dept sys_dept_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sys_dept
    ADD CONSTRAINT sys_dept_pkey PRIMARY KEY (id);


--
-- Name: sys_dict_data sys_dict_data_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sys_dict_data
    ADD CONSTRAINT sys_dict_data_pkey PRIMARY KEY (id);


--
-- Name: sys_dict_type sys_dict_type_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sys_dict_type
    ADD CONSTRAINT sys_dict_type_pkey PRIMARY KEY (id);


--
-- Name: sys_file sys_file_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sys_file
    ADD CONSTRAINT sys_file_pkey PRIMARY KEY (id);


--
-- Name: sys_frontend_error sys_frontend_error_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sys_frontend_error
    ADD CONSTRAINT sys_frontend_error_pkey PRIMARY KEY (id);


--
-- Name: sys_import_export_task sys_import_export_task_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sys_import_export_task
    ADD CONSTRAINT sys_import_export_task_pkey PRIMARY KEY (id);


--
-- Name: sys_job sys_job_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sys_job
    ADD CONSTRAINT sys_job_pkey PRIMARY KEY (id);


--
-- Name: sys_login_log sys_login_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sys_login_log
    ADD CONSTRAINT sys_login_log_pkey PRIMARY KEY (id);


--
-- Name: sys_menu sys_menu_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sys_menu
    ADD CONSTRAINT sys_menu_pkey PRIMARY KEY (id);


--
-- Name: sys_notice sys_notice_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sys_notice
    ADD CONSTRAINT sys_notice_pkey PRIMARY KEY (id);


--
-- Name: sys_notice_user sys_notice_user_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sys_notice_user
    ADD CONSTRAINT sys_notice_user_pkey PRIMARY KEY (id);


--
-- Name: sys_operation_log sys_operation_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sys_operation_log
    ADD CONSTRAINT sys_operation_log_pkey PRIMARY KEY (id);


--
-- Name: sys_outbox_event sys_outbox_event_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sys_outbox_event
    ADD CONSTRAINT sys_outbox_event_pkey PRIMARY KEY (id);


--
-- Name: sys_permission sys_permission_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sys_permission
    ADD CONSTRAINT sys_permission_pkey PRIMARY KEY (id);


--
-- Name: sys_permission sys_permission_tenant_id_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sys_permission
    ADD CONSTRAINT sys_permission_tenant_id_code_key UNIQUE (tenant_id, code);


--
-- Name: sys_role_permission sys_role_permission_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sys_role_permission
    ADD CONSTRAINT sys_role_permission_pkey PRIMARY KEY (id);


--
-- Name: sys_role sys_role_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sys_role
    ADD CONSTRAINT sys_role_pkey PRIMARY KEY (id);


--
-- Name: sys_role sys_role_tenant_id_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sys_role
    ADD CONSTRAINT sys_role_tenant_id_code_key UNIQUE (tenant_id, code);


--
-- Name: sys_task_execution_log sys_task_execution_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sys_task_execution_log
    ADD CONSTRAINT sys_task_execution_log_pkey PRIMARY KEY (id, start_time);


--
-- Name: sys_task_execution_log_2026_03 sys_task_execution_log_2026_03_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sys_task_execution_log_2026_03
    ADD CONSTRAINT sys_task_execution_log_2026_03_pkey PRIMARY KEY (id, start_time);


--
-- Name: sys_task_execution_log_2026_04 sys_task_execution_log_2026_04_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sys_task_execution_log_2026_04
    ADD CONSTRAINT sys_task_execution_log_2026_04_pkey PRIMARY KEY (id, start_time);


--
-- Name: sys_task_execution_log_2026_05 sys_task_execution_log_2026_05_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sys_task_execution_log_2026_05
    ADD CONSTRAINT sys_task_execution_log_2026_05_pkey PRIMARY KEY (id, start_time);


--
-- Name: sys_task_execution_log_2026_06 sys_task_execution_log_2026_06_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sys_task_execution_log_2026_06
    ADD CONSTRAINT sys_task_execution_log_2026_06_pkey PRIMARY KEY (id, start_time);


--
-- Name: sys_tenant sys_tenant_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sys_tenant
    ADD CONSTRAINT sys_tenant_code_key UNIQUE (code);


--
-- Name: sys_tenant_package sys_tenant_package_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sys_tenant_package
    ADD CONSTRAINT sys_tenant_package_pkey PRIMARY KEY (id);


--
-- Name: sys_tenant sys_tenant_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sys_tenant
    ADD CONSTRAINT sys_tenant_pkey PRIMARY KEY (id);


--
-- Name: sys_user sys_user_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sys_user
    ADD CONSTRAINT sys_user_pkey PRIMARY KEY (id);


--
-- Name: sys_user_role sys_user_role_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sys_user_role
    ADD CONSTRAINT sys_user_role_pkey PRIMARY KEY (id);


--
-- Name: sys_user sys_user_tenant_id_username_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sys_user
    ADD CONSTRAINT sys_user_tenant_id_username_key UNIQUE (tenant_id, username);


--
-- Name: sys_webhook_config sys_webhook_config_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sys_webhook_config
    ADD CONSTRAINT sys_webhook_config_pkey PRIMARY KEY (id);


--
-- Name: sys_webhook_log sys_webhook_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sys_webhook_log
    ADD CONSTRAINT sys_webhook_log_pkey PRIMARY KEY (id);


--
-- Name: idx_app_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_app_id ON public.open_app_secret USING btree (app_id);


--
-- Name: idx_cache_invalidation_event_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cache_invalidation_event_tenant_id ON public.cache_invalidation_event USING btree (tenant_id);


--
-- Name: idx_cache_name_created_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cache_name_created_time ON public.cache_invalidation_event USING btree (cache_name, created_time DESC);


--
-- Name: idx_data_change_log_created_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_data_change_log_created_time ON public.sys_data_change_log USING btree (created_time);


--
-- Name: idx_data_change_log_table_record; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_data_change_log_table_record ON public.sys_data_change_log USING btree (table_name, record_id);


--
-- Name: idx_dict_data_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_dict_data_type ON public.sys_dict_data USING btree (tenant_id, dict_type) WHERE (deleted = false);


--
-- Name: idx_file_tenant_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_file_tenant_time ON public.sys_file USING btree (tenant_id, created_time DESC);


--
-- Name: idx_file_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_file_type ON public.sys_file USING btree (file_type);


--
-- Name: idx_import_export_task_created_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_import_export_task_created_time ON public.sys_import_export_task USING btree (created_time);


--
-- Name: idx_import_export_task_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_import_export_task_status ON public.sys_import_export_task USING btree (status);


--
-- Name: idx_import_export_task_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_import_export_task_tenant_id ON public.sys_import_export_task USING btree (tenant_id);


--
-- Name: idx_job_tenant_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_job_tenant_status ON public.sys_job USING btree (tenant_id, status) WHERE (deleted = false);


--
-- Name: idx_job_tenant_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_job_tenant_time ON public.sys_job USING btree (tenant_id, created_time DESC) WHERE (deleted = false);


--
-- Name: idx_login_log_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_login_log_status ON public.sys_login_log USING btree (status);


--
-- Name: idx_login_log_tenant_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_login_log_tenant_time ON public.sys_login_log USING btree (tenant_id, created_time DESC);


--
-- Name: idx_login_log_username; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_login_log_username ON public.sys_login_log USING btree (username);


--
-- Name: idx_menu_tenant_parent; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_menu_tenant_parent ON public.sys_menu USING btree (tenant_id, parent_id) WHERE (deleted = false);


--
-- Name: idx_menu_tenant_sort; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_menu_tenant_sort ON public.sys_menu USING btree (tenant_id, sort) WHERE (deleted = false);


--
-- Name: idx_msg_record_created_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_msg_record_created_time ON public.msg_record USING btree (created_time);


--
-- Name: idx_msg_record_message_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_msg_record_message_type ON public.msg_record USING btree (message_type);


--
-- Name: idx_msg_record_receiver_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_msg_record_receiver_id ON public.msg_record USING btree (receiver_id);


--
-- Name: idx_msg_record_send_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_msg_record_send_status ON public.msg_record USING btree (send_status);


--
-- Name: idx_msg_record_template_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_msg_record_template_id ON public.msg_record USING btree (template_id);


--
-- Name: idx_msg_record_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_msg_record_tenant_id ON public.msg_record USING btree (tenant_id);


--
-- Name: idx_msg_subscription_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_msg_subscription_status ON public.msg_subscription USING btree (status);


--
-- Name: idx_msg_subscription_template_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_msg_subscription_template_id ON public.msg_subscription USING btree (template_id);


--
-- Name: idx_msg_subscription_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_msg_subscription_tenant_id ON public.msg_subscription USING btree (tenant_id);


--
-- Name: idx_msg_subscription_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_msg_subscription_user_id ON public.msg_subscription USING btree (user_id);


--
-- Name: idx_msg_user_inbox_created_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_msg_user_inbox_created_time ON public.msg_user_inbox USING btree (created_time);


--
-- Name: idx_msg_user_inbox_is_read; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_msg_user_inbox_is_read ON public.msg_user_inbox USING btree (is_read);


--
-- Name: idx_msg_user_inbox_message_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_msg_user_inbox_message_id ON public.msg_user_inbox USING btree (message_id);


--
-- Name: idx_msg_user_inbox_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_msg_user_inbox_tenant_id ON public.msg_user_inbox USING btree (tenant_id);


--
-- Name: idx_msg_user_inbox_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_msg_user_inbox_user_id ON public.msg_user_inbox USING btree (user_id);


--
-- Name: idx_notice_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notice_status ON public.sys_notice USING btree (status);


--
-- Name: idx_notice_tenant_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notice_tenant_time ON public.sys_notice USING btree (tenant_id, created_time DESC);


--
-- Name: idx_notice_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notice_type ON public.sys_notice USING btree (notice_type);


--
-- Name: idx_notice_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notice_user ON public.sys_notice_user USING btree (notice_id, user_id);


--
-- Name: idx_open_app_secret_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_open_app_secret_status ON public.open_app_secret USING btree (status);


--
-- Name: idx_open_app_secret_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_open_app_secret_tenant_id ON public.open_app_secret USING btree (tenant_id);


--
-- Name: idx_operation_log_operator; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_operation_log_operator ON public.sys_operation_log USING btree (operator_name);


--
-- Name: idx_operation_log_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_operation_log_status ON public.sys_operation_log USING btree (status);


--
-- Name: idx_operation_log_tenant_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_operation_log_tenant_time ON public.sys_operation_log USING btree (tenant_id, created_time DESC);


--
-- Name: idx_outbox_aggregate; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_outbox_aggregate ON public.sys_outbox_event USING btree (aggregate_type, aggregate_id);


--
-- Name: idx_outbox_created_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_outbox_created_time ON public.sys_outbox_event USING btree (created_time);


--
-- Name: idx_outbox_status_retry; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_outbox_status_retry ON public.sys_outbox_event USING btree (status, next_retry_time) WHERE ((status)::text = 'PENDING'::text);


--
-- Name: idx_outbox_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_outbox_tenant_id ON public.sys_outbox_event USING btree (tenant_id);


--
-- Name: idx_permission_tenant_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_permission_tenant_time ON public.sys_permission USING btree (tenant_id, created_time DESC) WHERE (deleted = false);


--
-- Name: idx_role_perm_perm_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_role_perm_perm_id ON public.sys_role_permission USING btree (tenant_id, permission_id) WHERE (deleted = false);


--
-- Name: idx_role_perm_role_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_role_perm_role_id ON public.sys_role_permission USING btree (tenant_id, role_id) WHERE (deleted = false);


--
-- Name: idx_role_tenant_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_role_tenant_status ON public.sys_role USING btree (tenant_id, status) WHERE (deleted = false);


--
-- Name: idx_role_tenant_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_role_tenant_time ON public.sys_role USING btree (tenant_id, created_time DESC) WHERE (deleted = false);


--
-- Name: idx_start_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_start_time ON ONLY public.sys_task_execution_log USING btree (start_time DESC);


--
-- Name: idx_status_start_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_status_start_time ON ONLY public.sys_task_execution_log USING btree (status, start_time DESC);


--
-- Name: idx_task_execution_log_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_task_execution_log_tenant_id ON ONLY public.sys_task_execution_log USING btree (tenant_id);


--
-- Name: idx_task_name_start_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_task_name_start_time ON ONLY public.sys_task_execution_log USING btree (task_name, start_time DESC);


--
-- Name: idx_tenant_created_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tenant_created_time ON public.sys_tenant USING btree (created_time DESC);


--
-- Name: idx_tenant_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tenant_status ON public.sys_tenant USING btree (status);


--
-- Name: idx_user_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_email ON public.sys_user USING btree (tenant_id, email) WHERE ((email IS NOT NULL) AND (deleted = false));


--
-- Name: idx_user_phone; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_phone ON public.sys_user USING btree (tenant_id, phone) WHERE ((phone IS NOT NULL) AND (deleted = false));


--
-- Name: idx_user_role_role_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_role_role_id ON public.sys_user_role USING btree (tenant_id, role_id) WHERE (deleted = false);


--
-- Name: idx_user_role_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_role_user_id ON public.sys_user_role USING btree (tenant_id, user_id) WHERE (deleted = false);


--
-- Name: idx_user_tenant_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_tenant_status ON public.sys_user USING btree (tenant_id, status) WHERE (deleted = false);


--
-- Name: idx_user_tenant_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_tenant_time ON public.sys_user USING btree (tenant_id, created_time DESC) WHERE (deleted = false);


--
-- Name: idx_webhook_config_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_webhook_config_status ON public.sys_webhook_config USING btree (status);


--
-- Name: idx_webhook_config_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_webhook_config_tenant_id ON public.sys_webhook_config USING btree (tenant_id);


--
-- Name: idx_webhook_log_created_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_webhook_log_created_time ON public.sys_webhook_log USING btree (created_time);


--
-- Name: idx_webhook_log_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_webhook_log_status ON public.sys_webhook_log USING btree (status);


--
-- Name: idx_webhook_log_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_webhook_log_tenant_id ON public.sys_webhook_log USING btree (tenant_id);


--
-- Name: idx_webhook_log_webhook_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_webhook_log_webhook_id ON public.sys_webhook_log USING btree (webhook_id);


--
-- Name: sys_task_execution_log_2026_03_start_time_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sys_task_execution_log_2026_03_start_time_idx ON public.sys_task_execution_log_2026_03 USING btree (start_time DESC);


--
-- Name: sys_task_execution_log_2026_03_status_start_time_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sys_task_execution_log_2026_03_status_start_time_idx ON public.sys_task_execution_log_2026_03 USING btree (status, start_time DESC);


--
-- Name: sys_task_execution_log_2026_03_task_name_start_time_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sys_task_execution_log_2026_03_task_name_start_time_idx ON public.sys_task_execution_log_2026_03 USING btree (task_name, start_time DESC);


--
-- Name: sys_task_execution_log_2026_03_tenant_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sys_task_execution_log_2026_03_tenant_id_idx ON public.sys_task_execution_log_2026_03 USING btree (tenant_id);


--
-- Name: sys_task_execution_log_2026_04_start_time_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sys_task_execution_log_2026_04_start_time_idx ON public.sys_task_execution_log_2026_04 USING btree (start_time DESC);


--
-- Name: sys_task_execution_log_2026_04_status_start_time_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sys_task_execution_log_2026_04_status_start_time_idx ON public.sys_task_execution_log_2026_04 USING btree (status, start_time DESC);


--
-- Name: sys_task_execution_log_2026_04_task_name_start_time_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sys_task_execution_log_2026_04_task_name_start_time_idx ON public.sys_task_execution_log_2026_04 USING btree (task_name, start_time DESC);


--
-- Name: sys_task_execution_log_2026_04_tenant_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sys_task_execution_log_2026_04_tenant_id_idx ON public.sys_task_execution_log_2026_04 USING btree (tenant_id);


--
-- Name: sys_task_execution_log_2026_05_start_time_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sys_task_execution_log_2026_05_start_time_idx ON public.sys_task_execution_log_2026_05 USING btree (start_time DESC);


--
-- Name: sys_task_execution_log_2026_05_status_start_time_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sys_task_execution_log_2026_05_status_start_time_idx ON public.sys_task_execution_log_2026_05 USING btree (status, start_time DESC);


--
-- Name: sys_task_execution_log_2026_05_task_name_start_time_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sys_task_execution_log_2026_05_task_name_start_time_idx ON public.sys_task_execution_log_2026_05 USING btree (task_name, start_time DESC);


--
-- Name: sys_task_execution_log_2026_05_tenant_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sys_task_execution_log_2026_05_tenant_id_idx ON public.sys_task_execution_log_2026_05 USING btree (tenant_id);


--
-- Name: sys_task_execution_log_2026_06_start_time_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sys_task_execution_log_2026_06_start_time_idx ON public.sys_task_execution_log_2026_06 USING btree (start_time DESC);


--
-- Name: sys_task_execution_log_2026_06_status_start_time_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sys_task_execution_log_2026_06_status_start_time_idx ON public.sys_task_execution_log_2026_06 USING btree (status, start_time DESC);


--
-- Name: sys_task_execution_log_2026_06_task_name_start_time_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sys_task_execution_log_2026_06_task_name_start_time_idx ON public.sys_task_execution_log_2026_06 USING btree (task_name, start_time DESC);


--
-- Name: sys_task_execution_log_2026_06_tenant_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sys_task_execution_log_2026_06_tenant_id_idx ON public.sys_task_execution_log_2026_06 USING btree (tenant_id);


--
-- Name: uk_msg_subscription_user_template_channel; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uk_msg_subscription_user_template_channel ON public.msg_subscription USING btree (user_id, template_id, channel) WHERE (deleted = false);


--
-- Name: uq_config_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_config_key ON public.sys_config USING btree (tenant_id, config_key) WHERE (deleted = false);


--
-- Name: uq_dict_type_type; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_dict_type_type ON public.sys_dict_type USING btree (tenant_id, dict_type) WHERE (deleted = false);


--
-- Name: sys_task_execution_log_2026_03_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.sys_task_execution_log_pkey ATTACH PARTITION public.sys_task_execution_log_2026_03_pkey;


--
-- Name: sys_task_execution_log_2026_03_start_time_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_start_time ATTACH PARTITION public.sys_task_execution_log_2026_03_start_time_idx;


--
-- Name: sys_task_execution_log_2026_03_status_start_time_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_status_start_time ATTACH PARTITION public.sys_task_execution_log_2026_03_status_start_time_idx;


--
-- Name: sys_task_execution_log_2026_03_task_name_start_time_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_task_name_start_time ATTACH PARTITION public.sys_task_execution_log_2026_03_task_name_start_time_idx;


--
-- Name: sys_task_execution_log_2026_03_tenant_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_task_execution_log_tenant_id ATTACH PARTITION public.sys_task_execution_log_2026_03_tenant_id_idx;


--
-- Name: sys_task_execution_log_2026_04_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.sys_task_execution_log_pkey ATTACH PARTITION public.sys_task_execution_log_2026_04_pkey;


--
-- Name: sys_task_execution_log_2026_04_start_time_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_start_time ATTACH PARTITION public.sys_task_execution_log_2026_04_start_time_idx;


--
-- Name: sys_task_execution_log_2026_04_status_start_time_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_status_start_time ATTACH PARTITION public.sys_task_execution_log_2026_04_status_start_time_idx;


--
-- Name: sys_task_execution_log_2026_04_task_name_start_time_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_task_name_start_time ATTACH PARTITION public.sys_task_execution_log_2026_04_task_name_start_time_idx;


--
-- Name: sys_task_execution_log_2026_04_tenant_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_task_execution_log_tenant_id ATTACH PARTITION public.sys_task_execution_log_2026_04_tenant_id_idx;


--
-- Name: sys_task_execution_log_2026_05_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.sys_task_execution_log_pkey ATTACH PARTITION public.sys_task_execution_log_2026_05_pkey;


--
-- Name: sys_task_execution_log_2026_05_start_time_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_start_time ATTACH PARTITION public.sys_task_execution_log_2026_05_start_time_idx;


--
-- Name: sys_task_execution_log_2026_05_status_start_time_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_status_start_time ATTACH PARTITION public.sys_task_execution_log_2026_05_status_start_time_idx;


--
-- Name: sys_task_execution_log_2026_05_task_name_start_time_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_task_name_start_time ATTACH PARTITION public.sys_task_execution_log_2026_05_task_name_start_time_idx;


--
-- Name: sys_task_execution_log_2026_05_tenant_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_task_execution_log_tenant_id ATTACH PARTITION public.sys_task_execution_log_2026_05_tenant_id_idx;


--
-- Name: sys_task_execution_log_2026_06_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.sys_task_execution_log_pkey ATTACH PARTITION public.sys_task_execution_log_2026_06_pkey;


--
-- Name: sys_task_execution_log_2026_06_start_time_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_start_time ATTACH PARTITION public.sys_task_execution_log_2026_06_start_time_idx;


--
-- Name: sys_task_execution_log_2026_06_status_start_time_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_status_start_time ATTACH PARTITION public.sys_task_execution_log_2026_06_status_start_time_idx;


--
-- Name: sys_task_execution_log_2026_06_task_name_start_time_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_task_name_start_time ATTACH PARTITION public.sys_task_execution_log_2026_06_task_name_start_time_idx;


--
-- Name: sys_task_execution_log_2026_06_tenant_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_task_execution_log_tenant_id ATTACH PARTITION public.sys_task_execution_log_2026_06_tenant_id_idx;


--
-- Name: sys_outbox_event outbox_event_notify; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER outbox_event_notify AFTER INSERT ON public.sys_outbox_event FOR EACH ROW EXECUTE FUNCTION public.notify_outbox_event();


--
-- Name: msg_user_inbox fk_msg_user_inbox_message; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.msg_user_inbox
    ADD CONSTRAINT fk_msg_user_inbox_message FOREIGN KEY (message_id) REFERENCES public.msg_record(id);


--
-- Name: msg_user_inbox fk_msg_user_inbox_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.msg_user_inbox
    ADD CONSTRAINT fk_msg_user_inbox_user FOREIGN KEY (user_id) REFERENCES public.sys_user(id);


--
-- Name: qrtz_blob_triggers qrtz_blob_triggers_sched_name_trigger_name_trigger_group_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.qrtz_blob_triggers
    ADD CONSTRAINT qrtz_blob_triggers_sched_name_trigger_name_trigger_group_fkey FOREIGN KEY (sched_name, trigger_name, trigger_group) REFERENCES public.qrtz_triggers(sched_name, trigger_name, trigger_group);


--
-- Name: qrtz_cron_triggers qrtz_cron_triggers_sched_name_trigger_name_trigger_group_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.qrtz_cron_triggers
    ADD CONSTRAINT qrtz_cron_triggers_sched_name_trigger_name_trigger_group_fkey FOREIGN KEY (sched_name, trigger_name, trigger_group) REFERENCES public.qrtz_triggers(sched_name, trigger_name, trigger_group);


--
-- Name: qrtz_simple_triggers qrtz_simple_triggers_sched_name_trigger_name_trigger_group_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.qrtz_simple_triggers
    ADD CONSTRAINT qrtz_simple_triggers_sched_name_trigger_name_trigger_group_fkey FOREIGN KEY (sched_name, trigger_name, trigger_group) REFERENCES public.qrtz_triggers(sched_name, trigger_name, trigger_group);


--
-- Name: qrtz_simprop_triggers qrtz_simprop_triggers_sched_name_trigger_name_trigger_grou_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.qrtz_simprop_triggers
    ADD CONSTRAINT qrtz_simprop_triggers_sched_name_trigger_name_trigger_grou_fkey FOREIGN KEY (sched_name, trigger_name, trigger_group) REFERENCES public.qrtz_triggers(sched_name, trigger_name, trigger_group);


--
-- Name: qrtz_triggers qrtz_triggers_sched_name_job_name_job_group_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.qrtz_triggers
    ADD CONSTRAINT qrtz_triggers_sched_name_job_name_job_group_fkey FOREIGN KEY (sched_name, job_name, job_group) REFERENCES public.qrtz_job_details(sched_name, job_name, job_group);


--
-- PostgreSQL database dump complete
--

\unrestrict DahdbKxydmjkiS4Gaa5RrzAqJ7JZZkvN57delNi41l3PWQy0s1eI8IZr1FE34vy
