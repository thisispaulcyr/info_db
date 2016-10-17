-- Table: info.nginx_conf_vhosts

-- DROP TABLE info.nginx_conf_vhosts;

CREATE TABLE info.nginx_conf_vhosts
(
  host character varying NOT NULL,
  rewrite_www boolean NOT NULL DEFAULT true,
  ssl info.support_enum NOT NULL DEFAULT 'disable'::info.support_enum,
  override_server text,
  additional_hosts text[],
  keepalive_timeout smallint,
  ssl_certificate character varying,
  ssl_certificate_key character varying,
  base character varying,
  root character varying,
  access_log_host_label boolean NOT NULL DEFAULT false,
  access_log character varying,
  error_log character varying,
  handler_apache boolean NOT NULL DEFAULT false,
  CONSTRAINT nginx_conf_pkey PRIMARY KEY (host)
);
