#!/bin/bash
set -e

if [[ $BRANCH_NAME =~ ^(main|master) ]]; then
  DOCKER_LOGIN_BUCKET=${DOCKER_LOGIN_BUCKET_PROD}
else
  DOCKER_LOGIN_BUCKET=${DOCKER_LOGIN_BUCKET_DEV}
fi

NEWRELIC_API_KEY=$(aws --profile shared ssm get-parameter \
  --name "/newrelic/api_key" \
  --query "Parameter.Value" \
  --with-decryption \
  --output text \
  --region us-east-1)

mkdir -p .ebextensions
cat << EOF > .ebextensions/nginx-logs.config
# Rotate nginx logs written from docker container

files:
  /etc/logrotate.elasticbeanstalk.hourly/nginx-rotate.conf:
    mode: "000644"
    owner: root
    group: root
    content: |
      /var/lib/docker/volumes/current_logs/_data/access.ndjson {
        size 10M
        rotate 5
        missingok
        compress
        notifempty
        copytruncate
        sharedscripts
        delaycompress
        createolddir
        olddir /var/lib/docker/volumes/current_logs/_data/rotated
      }

  /etc/cron.hourly/cron.logrotate.nginx-rotate.conf:
    mode: "000755"
    owner: root
    group: root
    content: |
      #!/bin/sh
      test -x /usr/sbin/logrotate || exit 0
      /usr/sbin/logrotate /etc/logrotate.elasticbeanstalk.hourly/nginx-rotate.conf
EOF

mkdir -p .platform/fluentd
cat << EOF > .platform/fluentd/fluent.conf
<source>
  @type tail
  <parse>
    @type json
  </parse>
  path /logs/access.ndjson
  tag "docker.nginx"
</source>

<source>
  @type tail
  <parse>
    @type json
  </parse>
  path /logs/spring-boot-logger.ndjson
  tag "docker.app.${PROJECT_NAME}.${PROJECT_VERSION_TAG}"
</source>

<filter **>
  @type record_transformer
  enable_ruby true
  <record>
    # added time and hostname for papertrail, can be removed when moved to newrelic
    message \${time.strftime('%b %d %H:%M:%S')} \${hostname} web: \${record["@timestamp"]} \${record["level"]} [\${record["thread_name"]}] \${record["logger_name"]}: \${record["message"]}\\n\${record["stack_trace"]}
    hostname ${PROJECT_NAME}-${PROJECT_ENVIRONMENT}
    program ${PROJECT_VERSION_TAG}
    severity notice
    facility local0
  </record>
</filter>

<match docker.nginx>
  @type rewrite_tag_filter
  <rule>
    key     client.userAgent
    pattern /^.*HealthChecker.*/
    tag     discard
  </rule>
</match>

<match discard>
  @type null
</match>

<match **>
  @type copy
  <store>
    @type newrelic
    api_key "${NEWRELIC_API_KEY}"
  </store>
  <store>
    @type papertrail
    papertrail_host logs.papertrailapp.com
    papertrail_port 25419
    # buffer_chunk_limit and retry_wait will prevent reaching the new TCP connections rate limit
    buffer_chunk_limit 16MB
    retry_wait 5s
    <buffer>
      retry_wait 5s
      # default values for flush_mode and retry_type
      flush_mode interval
      retry_type exponential_backoff
    </buffer>
  </store>
  # Debugging, uncomment and tail fluentd container
  # <store>
  #   @type stdout
  # </store>
</match>
EOF

mkdir -p .platform/nginx/
cat << EOF > .platform/nginx/nginx.conf
user                 nginx;
error_log            /dev/null warn;
pid                  /var/run/nginx.pid;
worker_processes     auto;
worker_rlimit_nofile 32793;

events {
  worker_connections 1024;
}

http {
  include      /etc/nginx/mime.types;
  default_type multipart/form-data;
  access_log   /dev/null;

  log_format json escape=json '{'
    '"@version": "1",'
    '"@timestamp": "\$time_iso8601",'
    '"request.method": "\$request_method",'
    '"request.uri": "\$request_uri",'
    '"request.protocol": "\$server_protocol",'
    '"request.host": "\$host",'
    '"request.size": "\$content_length",'
    '"request.referrer": "\$http_referer",'
    '"response.status": "\$status",'
    '"response.size": "\$body_bytes_sent",'
    '"response.latency": "\$request_time",'
    '"client.address": "\$remote_addr",'
    '"client.user": "\$remote_user",'
    '"client.userAgent": "\$http_user_agent",'
    '"upstream.status": "\$upstream_status",'
    '"upstream.latency": "\$upstream_response_time",'
    '"upstream.connectTime": "\$upstream_connect_time",'
    '"upstream.headerTime": "\$upstream_header_time"'
  '}';

  server {
    listen     80 default_server;
    access_log /logs/access.ndjson json;

    client_max_body_size 50M;
    large_client_header_buffers 4 32k;
    client_header_timeout 60;
    client_body_timeout   60;
    keepalive_timeout     60;
    gzip                  off;
    gzip_comp_level       4;
    gzip_types text/plain text/css application/json application/javascript application/x-javascript text/xml application/xml application/xml+rss text/javascript;

    location / {
      proxy_pass          http://app:5000;
      proxy_http_version  1.1;

      proxy_set_header    Connection          \$connection_upgrade;
      proxy_set_header    Upgrade             \$http_upgrade;
      proxy_set_header    Host                \$host;
      proxy_set_header    X-Real-IP           \$remote_addr;
      proxy_set_header    X-Forwarded-For     \$proxy_add_x_forwarded_for;
    }
  }

  map \$http_upgrade \$connection_upgrade {
   default "upgrade";
  }
}
EOF

mkdir -p .platform/newrelic-infra/integrations.d
cat << EOF > .platform/newrelic-infra/integrations.d/logging.yml
logs:
  - name: docker-logs
    file: /host/var/lib/docker/containers/*/*.log
EOF

cat << EOF > Dockerrun.aws.json
{
  "AWSEBDockerrunVersion": "3",
  "Authentication": {
    "bucket": "${DOCKER_LOGIN_BUCKET}",
    "key": "docker-config.json"
  }
}
EOF

# .env is created by cloudformation when beanstalk configures ec2, the values are built from beanstalkConfig-ENV.json
cat << EOF > docker-compose.yml
version: "3.8"
services:
  fluentd:
    container_name: fluentd
    image: ${DOCKER_HOST}/fluentd
    restart: on-failure
    env_file:
      - .env
    network_mode: host
    volumes:
      - git-sync:/shared
      - .platform/fluentd/fluent.conf:/fluentd/etc/fluent.conf
      - logs:/logs
  nginx:
    container_name: nginx
    image: nginx:1.21
    restart: on-failure
    depends_on:
      - fluentd
    ports:
      - 80:80
    env_file:
      - .env
    volumes:
      - git-sync:/shared
      - .platform/nginx/nginx.conf:/etc/nginx/nginx.conf
      - logs:/logs
  app:
    container_name: ${PROJECT_NAME}_${PROJECT_VERSION_TAG}
    image: ${DOCKER_REGISTRY}/${PROJECT_NAME}:${PROJECT_VERSION_TAG}
    restart: on-failure
    env_file:
      - .env
    volumes:
      - git-sync:/shared
      - logs:/logs
    depends_on:
      - fluentd
      - nginx
  newrelic-infra:
    container_name: newrelic_infra
    image: newrelic/infrastructure
    restart: on-failure
    env_file:
      - .env
    network_mode: host
    cap_add:
      - SYS_PTRACE
    environment:
      - NRIA_LICENSE_KEY=$NEWRELIC_API_KEY
    volumes:
      - git-sync:/shared
      - /:/host:ro
      - /var/run/docker.sock:/var/run/docker.sock
      # Uncomment to ingest logs via newrelic-infra
      # - .platform/newrelic-infra/integrations.d/logging.yml:/etc/newrelic-infra/integrations.d/logging.yml
  git-sync:
    container_name: git-sync
    image: ${DOCKER_HOST}/git-sync
    user: root
    restart: on-failure
    env_file:
      - .env
    volumes:
      - git-sync:/tmp/git
      - logs:/logs
    command: [
      "--repo=${DEBUG_GIT_URL}",
      "--branch=master",
      "--wait=3600",
      "--add-user=true",
      "--ssh=true",
      "--ssh-known-hosts=false",
      "--ssh-key-file=/id_rsa"
    ]
volumes:
     logs:
     git-sync:
EOF

mkdir -p .platform/hooks/prebuild
cat << EOF > .platform/hooks/prebuild/docker-daemon.sh
#!/bin/bash
cat << EOC > /etc/docker/daemon.json
{
  "registry-mirrors": ["${DOCKER_MIRROR}"],
  "default-address-pools": [
    {
      "base": "172.250.0.0/16",
      "size": 24
    }
  ]
}
EOC
systemctl restart docker
EOF
chmod +x .platform/hooks/prebuild/docker-daemon.sh
