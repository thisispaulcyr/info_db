-- Function: info.nginx_conf_vhosts_builder()

-- DROP FUNCTION info.nginx_conf_vhosts_builder();

CREATE OR REPLACE FUNCTION info.nginx_conf_vhosts_builder()
  RETURNS TABLE(nginx_conf_vhosts text) AS
$BODY$DECLARE
	the_record record;
	output text;
    additional_host character varying;
	server_name character varying;
	keepalive_timeout smallint;
	ssl_certificate character varying;
	ssl_certificate_key character varying;
	base character varying;
	root character varying;
	access_log character varying;
	error_log character varying;
	handler_apache boolean NOT NULL DEFAULT false;
BEGIN
	FOR the_record IN SELECT * FROM info.nginx_conf_vhosts ORDER BY host
	LOOP
	output := E'\n\n    \#\#\# ' || the_record.host || E' ###\n\n';
	IF length(the_record.override_server) > 0 THEN
		output := output || the_record.override_server;
	ELSE
		IF the_record.ssl = 'support' THEN
			IF the_record.rewrite_www THEN
				output := output || E'    server {\n        listen 80;\n        listen [::]:80;\n        listen 443 ssl;\n        listen [::]:443 ssl;\n        server_name www.' || the_record.host;
				IF array_length(the_record.additional_hosts::text[], 1) > 0 THEN
					FOREACH additional_host IN ARRAY the_record.additional_hosts
					LOOP
						output := output || ' www.' || additional_host;
					END LOOP;
					output := output || ';';
					output := output || E'\n        return 301 $scheme://$host$request_uri;\n    }';
				ELSE
					output := output || ';';
					output := output || E'\n        return 301 $scheme://' || the_record.host || E'$request_uri;\n    }';
				END IF;
			END IF;
			output := output || E'\n\n    server {\n        listen 80;\n        listen [::]:80;\n        listen 443 ssl;\n        listen [::]:443 ssl;\n        server_name ' || the_record.host;
			IF array_length(the_record.additional_hosts, 1) > 0 THEN
				FOREACH additional_host IN ARRAY the_record.additional_hosts
				LOOP
					output := output || ' ' || additional_host;
				END LOOP;
			END IF;
			output := output || ';';
		ELSIF the_record.ssl = 'force' THEN
			IF the_record.rewrite_www THEN
				output := output || E'    server {\n        listen 80;\n        listen [::]:80;\n        server_name ~^(www\.)?' || replace(the_record.host, '.', '\.') || '$';
				IF array_length(the_record.additional_hosts, 1) > 0 THEN
					FOREACH additional_host IN ARRAY the_record.additional_hosts
					LOOP
						output := output || ' ~^(www\.)?' || replace(additional_host, '.', '\.') || '$';
					END LOOP;
					output := output || ';';
					output := output || E'\n        return 301 https://$host';
				ELSE
					output := output || ';';
					output := output || E'\n        return 301 https://' || the_record.host;
				END IF;
				output := output || E'$request_uri;\n    }';

				output := output || E'\n\n    server {\n        listen 443 ssl;\n        listen [::]:443 ssl;\n        server_name www.' || the_record.host;
				IF array_length(the_record.additional_hosts, 1) > 0 THEN
					FOREACH additional_host IN ARRAY the_record.additional_hosts
					LOOP
						output := output || ' www.' || additional_host;
					END LOOP;
					output := output || ';';
					output := output || E'\n        return 301 https://$host';
				ELSE
					output := output || ';';
					output := output || E'\n        return 301 https://' || the_record.host;
				END IF;
				output := output || E'$request_uri;\n    }';
			END IF;
			output := output || E'\n\n    server {\n        listen 443 ssl;\n        listen [::]:443 ssl;\n        server_name ' || the_record.host;
			IF array_length(the_record.additional_hosts, 1) > 0 THEN
				FOREACH additional_host IN ARRAY the_record.additional_hosts
				LOOP
					output := output || ' ' || additional_host;
				END LOOP;
			END IF;
			output := output || ';';
		ELSE
			IF the_record.rewrite_www THEN
				output := output || E'    server {\n        listen 80;\n        listen [::]:80;\n        server_name www.' || the_record.host;
				IF array_length(the_record.additional_hosts, 1) > 0 THEN
					FOREACH additional_host IN ARRAY the_record.additional_hosts
					LOOP
						output := output || ' www.' || additional_host;
					END LOOP;
					output := output || ';';
					output := output || E'\n        return 301 http://$host$request_uri;\n    }';
				ELSE
					output := output || ';';
					output := output || E'\n        return 301 http://' || the_record.host || E'$request_uri;\n    }';
				END IF;
			END IF;
			output := output || E'\n\n    server {\n        listen 80;\n        listen [::]:80;\n        server_name ' || the_record.host;
			IF array_length(the_record.additional_hosts, 1) > 0 THEN
				FOREACH additional_host IN ARRAY the_record.additional_hosts
				LOOP
					output := output || ' ' || additional_host;
				END LOOP;
			END IF;
			output := output || ';';
		END IF;

		IF length(the_record.keepalive_timeout::character varying) > 0 THEN
			keepalive_timeout := the_record.keepalive_timeout;
		ELSE
			keepalive_timeout := 70;
		END IF;
		output := output || E'\n        keepalive_timeout ' || keepalive_timeout || ';';
		
		IF the_record.ssl = 'support' OR the_record.ssl = 'force' THEN
			IF length(the_record.ssl_certificate) > 0 THEN
				ssl_certificate := the_record.ssl_certificate;
			ELSE
				ssl_certificate := '/etc/letsencrypt/live/' || the_record.host || '/fullchain.pem';
			END IF;
			output := output || E'\n        ssl_certificate ' || ssl_certificate || ';';
			IF length(the_record.ssl_certificate_key) > 0 THEN
				ssl_certificate_key := the_record.ssl_certificate_key;
			ELSE
				ssl_certificate_key := '/etc/letsencrypt/live/' || the_record.host || '/privkey.pem';
			END IF;
			output := output || E'\n        ssl_certificate_key ' || ssl_certificate_key || ';';
		END IF;
		IF length(the_record.base) > 0 THEN
			base := the_record.base;
		ELSE
			base := '/var/www/domains/' || the_record.host;
		END IF;
		IF length(the_record.root) > 0 THEN
			root := the_record.root;
		ELSE
			root := base || '/public_html';
		END IF;
		output := output || E'\n        root ' || root || ';';
		IF length(the_record.access_log) > 0 THEN
			access_log := the_record.access_log;
		ELSE
			access_log := base || '/';
			IF the_record.access_log_host_label THEN
				access_log := access_log || the_record.host || '.';
			END IF;
			access_log := access_log || 'nginx_access.log';
		END IF;
		output := output || E'\n        access_log ' || access_log || ';';
		IF length(the_record.error_log) > 0 THEN
			error_log := the_record.error_log;
		ELSE
			error_log := base || '/nginx_error.log';
		END IF;
		output := output || E'\n        error_log ' || error_log || ';';

		IF the_record.handler_apache THEN
			output := output || E'\n\n        # Apache handles all except certain file requests\n        location / {\n            proxy_set_header X-Real-IP $remote_addr;\n            proxy_set_header X-Forwarded-For $remote_addr;\n            proxy_set_header X-Forwarded-Proto $scheme;\n            proxy_set_header Host ';
			IF array_length(the_record.additional_hosts, 1) > 0 THEN
				output := output || '$host';
			ELSE
				output := output || the_record.host;
			END IF;
			output := output || ';';
			output := output || E'\n            proxy_pass http://127.0.0.1:8080;\n        }\n\n        location ~* ^.+\.(jpg|jpeg|gif|png|css|zip|pdf|txt|js)$ {\n            try_files $uri $uri/ @backend;\n        }';
			output := output || E'\n\n        location @backend {\n            proxy_set_header X-Real-IP  $remote_addr;\n            proxy_set_header X-Forwarded-For $remote_addr;\n            proxy_set_header X-Forwarded-Proto $scheme;\n            proxy_set_header Host ';
			IF array_length(the_record.additional_hosts, 1) > 0 THEN
				output := output || '$host';
			ELSE
				output := output || the_record.host;
			END IF;
			output := output || ';';
			output := output || E'\n            proxy_pass http://127.0.0.1:8080;\n        }';
		END IF;
		output := output || E'\n    }\n';
	END IF;
	RETURN QUERY SELECT output;
END LOOP;
END;$BODY$
  LANGUAGE plpgsql STABLE
  COST 100;
