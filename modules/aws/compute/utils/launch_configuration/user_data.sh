#!/bin/bash
echo ECS_CLUSTER=${cluster_name} > /etc/ecs/ecs.config
echo 'DOCKER_STORAGE_OPTIONS="--storage-driver overlay2"' > /etc/sysconfig/docker-storage
export ENVIRONMENT=${environment}
cat << HEREDOC | sudo tee /etc/sysconfig/docker
# The max number of open files for the daemon itself, and all
# running containers.  The default value of 1048576 mirrors the value
# used by the systemd service unit.
DAEMON_MAXFILES=1048576

# Additional startup options for the Docker daemon, for example:
# OPTIONS="--ip-forward=true --iptables=true"
# By default we limit the number of open files per container
OPTIONS="--default-ulimit nofile=1024000:1024000"
HEREDOC

# Enable Swap
sudo fallocate -l ${swap_size} /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo "/swapfile   none    swap    sw    0   0" | sudo tee -a /etc/fstab

# Restart Docker
service docker restart
