#!/bin/bash
set -e

LATEST_YQ=$(curl -w "%{url_effective}" -I -L -s -S https://github.com/mikefarah/yq/releases/latest -o /dev/null | sed -e 's|.*/||')
UNAME=$(uname | tr '[:upper:]' '[:lower:]')

if [[ -z "${NEWRELIC_API_KEY}" ]]; then
  NEWRELIC_API_KEY=$(aws --profile ${aws_profile} ssm get-parameter \
    --name "/newrelic/api_key" \
    --query "Parameter.Value" \
    --with-decryption \
    --output text \
    --region us-east-1)
else
  echo 'loading newrelic api key from environment'
fi

mkdir -p target
mkdir -p .dockertmp/bin
curl -sLo- https://github.com/mikefarah/yq/releases/download/${LATEST_YQ}/yq_${UNAME}_amd64 > .dockertmp/bin/yq && chmod +x .dockertmp/bin/yq
curl -sLo- https://download.newrelic.com/newrelic/java-agent/newrelic-agent/current/newrelic-agent.jar > .dockertmp/newrelic.jar
mkdir -p .dockertmp/.m2
cp -r $HOME/.m2/settings.xml .dockertmp/.m2/settings.xml

# Check https://github.com/newrelic/newrelic-java-agent/issues/526. When it is solved, we can remove workaround to enable
# completable trace again.
cat << EOF > .dockertmp/newrelic.yml
common: &default_settings
  license_key: $NEWRELIC_API_KEY
  distributed_tracing:
    enabled: true
  browser_monitoring:
    auto_instrument: false
  class_transformer:
    trace_annotation_class_name: ${trace_annotation_class_name}
    com.newrelic.instrumentation.java.completable-future-jdk8u40:
      enabled: false
EOF
