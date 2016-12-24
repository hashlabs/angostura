/**
 *## Description:
 *
 *Drone module creates a ECS Cluster with ECS Service and Task for the drone CI image.
 *The cluster is created inside a VPC.
 *
 *This module creates all the necessary pieces that are needed to run a cluster, including:
 *
 ** Auto Scaling Groups
 ** EC2 Launch Configurations
 *
 *## Usage:
 *
 *```hcl
 *module "drone" {
 *  source      = "../services/drone"
 *  environment = "${var.environment}"
 *
 *  db_username = "${var.db_username}"
 *  db_password = "${var.db_password}"
 *  db_host     = "${var.db_host}"
 *  db_port     = "${var.db_port}"
 *  db_name     = "${var.db_name}"
 *
 *  key_name                = "${var.key_name}"
 *  iam_instance_profile_id = "${var.iam_instance_profile_id}"
 *  subnet_ids              = ["${var.subnet_ids}"]
 *  security_groups         = ["${var.security_groups}"]
 *  asg_min_size            = "${var.asg_min_size}"
 *  asg_max_size            = "${var.asg_max_size}"
 *
 *  github_client = "${var.github_client}"
 *  github_secret = "${var.github_secret}"
 *  drone_secret  = "${var.drone_secret}"
 *  drone_server  = "${var.drone_server}"
 *}
 *```
 */

/*
 * Variables
 */
variable "environment" {
  description = "Environment name"
}

variable "db_host" {
  description = "Database Host URL"
}

variable "db_username" {
  description = "Database Username"
}

variable "db_password" {
  description = "Database Password"
}

variable "db_port" {
  description = "Database Port"
  default     = "5432"
}

variable "db_name" {
  description = "Database name"
  default     = "drone"
}

variable "key_name" {
  description = "SSH Key Pair to be assigned to the Launch Configuration for the instances running in this cluster"
}

variable "instance_type" {
  description = "Instace type Launch Configuration for the instances running in this cluster"
  default     = "t2.small"
}

variable "iam_instance_profile_id" {
  description = "IAM Profile ID to be used in the Launch Configuration for the instances running in this cluster"
}

variable "subnet_ids" {
  description = "VPC Subnet IDs to be used in the Launch Configuration for the instances running in this cluster"
  type        = "list"
}

variable "security_groups" {
  description = "VPC Security Groups IDs to be used in the Launch Configuration for the instances running in this cluster"
  type        = "list"
}

variable "asg_min_size" {
  description = "Auto Scaling Group minimium size for the cluster"
  default     = 1
}

variable "asg_max_size" {
  description = "Auto Scaling Group maximum size for the cluster"
  default     = 1
}

variable "desired_count" {
  description = "Number of instances to be run"
  default     = 1
}

variable "github_client" {
  description = "Github App client id"
}

variable "github_secret" {
  description = "Github App secret key"
}

variable "drone_secret" {
  description = "Random 128 chars length string"
}

variable "drone_server" {
  description = "Server WebSockets endpoint"
}

variable "drone_admin" {
  description = "List of admins' Github username"
  default     = "orlando"
}

variable "drone_orgs" {
  description = "List of allowed Github orgs"
  default     = "hashlabs"
}

/*
 * Resources
 */
data "template_file" "drone" {
  template = "${file("${path.module}/drone.json")}"

  vars {
    container_name = "drone-${var.environment}"
    environment    = "${var.environment}"

    db_url = "postgres://${var.db_username}:${var.db_password}@${var.db_host}:${var.db_port}/${var.db_name}"

    github_client = "${var.github_client}"
    github_secret = "${var.github_secret}"

    drone_admin  = "${var.drone_admin}"
    drone_orgs   = "${var.drone_orgs}"
    drone_secret = "${var.drone_secret}"
    drone_server = "${var.drone_server}"
  }
}

module "drone_lc" {
  source      = "../../utils/launch_configuration"
  environment = "${var.environment}"

  cluster_name            = "${aws_ecs_cluster.drone.name}"
  key_name                = "${var.key_name}"
  iam_instance_profile_id = "${var.iam_instance_profile_id}"
  instance_type           = "${var.instance_type}"
  security_groups         = ["${var.security_groups}"]
}

resource "aws_autoscaling_group" "drone_asg" {
  launch_configuration = "${module.drone_lc.id}"
  min_size             = "${var.asg_min_size}"
  max_size             = "${var.asg_max_size}"
  health_check_type    = "ELB"
  vpc_zone_identifier  = ["${var.subnet_ids}"]
}

# Create a cluster for Drone
resource "aws_ecs_cluster" "drone" {
  name = "drone-c-${var.environment}"
}

# Create a task definition for Drone
resource "aws_ecs_task_definition" "drone" {
  family                = "drone-${var.environment}"
  container_definitions = "${data.template_file.drone.rendered}"

  volume {
    name      = "docker-socket-${var.environment}"
    host_path = "/var/run/docker.sock"
  }

  volume {
    name      = "drone-${var.environment}"
    host_path = "/ecs/drone"
  }

  volume {
    name      = "sftp-${var.environment}"
    host_path = "/ecs/drone-cache"
  }
}

# Create a Service for Drone
resource "aws_ecs_service" "drone" {
  name            = "drone-${var.environment}"
  cluster         = "${aws_ecs_cluster.drone.id}"
  task_definition = "${aws_ecs_task_definition.drone.arn}"
  desired_count   = "${var.desired_count}"
}

/*
 * Outputs
 */

// ECS Service name
output "service_name" {
  value = "${aws_ecs_service.drone.name}"
}
