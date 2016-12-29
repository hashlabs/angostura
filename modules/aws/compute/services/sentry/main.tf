/**
 *## Description:
 *
 *Sentry module creates a ECS Cluster with ECS Service and Task for the sentry image.
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
 *module "sentry" {
 *  source      = "../services/sentry"
 *  environment = "${var.environment}"
 *
 *  db_username = "${var.db_username}"
 *  db_password = "${var.db_password}"
 *  db_host     = "${var.db_host}"
 *  db_port     = "${var.db_port}"
 *  db_name     = "${var.sentry_db_name}"
 *
 *  smtp_host     = "${var.smtp_host}"
 *  smtp_port     = "${var.smtp_port}"
 *  smtp_username = "${var.smtp_username}"
 *  smtp_password = "${var.smtp_password}"
 *
 *  key_name                = "${var.key_name}"
 *  iam_instance_profile_id = "${var.iam_instance_profile_id}"
 *  subnet_ids              = ["${var.subnet_ids}"]
 *  security_groups         = ["${var.security_groups}"]
 *  asg_min_size            = "${var.asg_min_size}"
 *  asg_max_size            = "${var.asg_max_size}"
 *
 *  sentry_secret_key = "${var.sentry_secret_key}"
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
  default     = "sentry"
}

variable "smtp_host" {
  description = "SMTP host"
}

variable "smtp_port" {
  description = "SMTP port"
}

variable "smtp_username" {
  description = "SMTP username"
}

variable "smtp_password" {
  description = "SMTP password"
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

variable "sentry_secret_key" {
  description = "Random 32 chars string"
}

variable "github_app_id" {
  description = "Github APP ID"
}

variable "github_api_secret" {
  description = "Github API Secret"
}

/*
 * Resources
 */
data "template_file" "sentry" {
  template = "${file("${path.module}/sentry.json")}"

  vars {
    container_name = "sentry-${var.environment}"
    environment    = "${var.environment}"

    db_username = "${var.db_username}"
    db_password = "${var.db_password}"
    db_host     = "${var.db_host}"
    db_port     = "${var.db_port}"
    db_name     = "${var.db_name}"

    smtp_host     = "${var.smtp_host}"
    smtp_port     = "${var.smtp_port}"
    smtp_username = "${var.smtp_username}"
    smtp_password = "${var.smtp_password}"

    github_app_id     = "${var.github_app_id}"
    github_api_secret = "${var.github_api_secret}"

    sentry_secret_key = "${var.sentry_secret_key}"
  }
}

# Create a cluster for Sentry
resource "aws_ecs_cluster" "sentry" {
  name = "sentry-c-${var.environment}"
}

module "sentry_lc" {
  source      = "../../utils/launch_configuration"
  environment = "${var.environment}"

  cluster_name            = "${aws_ecs_cluster.sentry.name}"
  key_name                = "${var.key_name}"
  iam_instance_profile_id = "${var.iam_instance_profile_id}"
  instance_type           = "${var.instance_type}"
  security_groups         = ["${var.security_groups}"]
}

resource "aws_autoscaling_group" "sentry_asg" {
  launch_configuration = "${module.sentry_lc.id}"
  min_size             = "${var.asg_min_size}"
  max_size             = "${var.asg_max_size}"
  health_check_type    = "ELB"
  vpc_zone_identifier  = ["${var.subnet_ids}"]
}

# Create a task definition for Sentry
resource "aws_ecs_task_definition" "sentry" {
  family                = "sentry-${var.environment}"
  container_definitions = "${data.template_file.sentry.rendered}"

  volume {
    name      = "sentry-${var.environment}"
    host_path = "/ecs/sentry"
  }
}

# Create a Service for Sentry
resource "aws_ecs_service" "sentry" {
  name            = "sentry-${var.environment}"
  cluster         = "${aws_ecs_cluster.sentry.id}"
  task_definition = "${aws_ecs_task_definition.sentry.arn}"
  desired_count   = "${var.desired_count}"
}

/*
 * Outputs
 */

// ECS Service name
output "service_name" {
  value = "${aws_ecs_service.sentry.name}"
}
