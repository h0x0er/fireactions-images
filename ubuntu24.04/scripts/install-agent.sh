#!/bin/bash

set -e
mkdir -p /home/agent
cd /home/agent

architecture=$(uname -m)

# set true: to use agent-binaries from int-pr build
int_pr="true"

if [[ $int_pr == "true" ]]; then

    agent=""
    if [ "$architecture" = "aarch64" ]; then
        agent="agent-arm"
    else
        agent="agent"
    fi
    curl -o agent "https://step-security-agent.s3.us-west-2.amazonaws.com/refs/heads/self-hosted/int/$agent"
    curl -O "https://step-security-agent.s3.us-west-2.amazonaws.com/refs/heads/self-hosted/int/agent.service"

else

    if [ "$architecture" = "aarch64" ]; then
        agent_tar="harden-runner_1.6.23_linux_arm64.tar.gz"
    else
        agent_tar="harden-runner_1.6.23_linux_amd64.tar.gz"
    fi

    curl -O "https://packages.stepsecurity.io/self-hosted/$agent_tar"

    if [ "$architecture" = "aarch64" ]; then
        echo "a3c89271e697ab39557ba8011cac7a2df690b5d27b4584d5d5abdf8845a6ce6c  $agent_tar" | sha256sum -c
    else
        echo "2430b850e0e4d67a2f3b626f02d2827226ee16406da6af0c47ae7b18e18bd2b8  $agent_tar" | sha256sum -c
    fi

    tar -xzf "$agent_tar"

fi

# 5. Create /home/agent/agent.json.
cat <<EOL >/home/agent/agent.json
{
"customer": "step-security-experiments",
"working_directory": "/opt/runner",
"api_key": "123",
"executor":"fireactions",
"api_url": "https://int.api.stepsecurity.io/v1"
}
EOL

# 6. Make agent executable...
chmod +x /home/agent/agent

# 7. Copy agent.service
cp agent.service /etc/systemd/system/agent.service

# enable agent-service
systemctl enable agent.service
