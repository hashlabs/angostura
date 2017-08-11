/**
 *## Description:
 *
 *Metabase module creates a ECS Cluster with ECS Service and Task for the metabase image.
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
 *module "metabase" {
 *  source      = "../services/metabase"
 *  environment = "${var.environment}"
 *  image       = "${var.image}"
 *
 *  db_username = "${var.db_username}"
 *  db_password = "${var.db_password}"
 *  db_host     = "${var.db_host}"
 *  db_port     = "${var.db_port}"
 *  db_name     = "${var.metabase_db_name}"
 *
 *  key_name                = "${var.key_name}"
 *  iam_instance_profile_id = "${var.iam_instance_profile_id}"
 *  subnet_ids              = ["${var.subnet_ids}"]
 *  security_groups         = ["${var.security_groups}"]
 *  asg_min_size            = "${var.asg_min_size}"
 *  asg_max_size            = "${var.asg_max_size}"
 *}
 *```

/*
 * Variables
 */

variable "environment" {
  description = "Environment name"
}

variable "image" {
  description = "Docker image name"
  default     = "metabase/metabase:latest"
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
  default     = "metabase"
}

variable "key_name" {
  description = "SSH Key Pair to be assigned to the Launch Configuration for the instances running in this cluster"
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

/*
 * Resources
 */
data "template_file" "metabase" {
  template = "${file("${path.module}/metabase.json")}"

  vars {
    container_name = "metabase-${var.environment}"
    image          = "${var.image}"

    db_username = "${var.db_username}"
    db_password = "${var.db_password}"
    db_host     = "${var.db_host}"
    db_port     = "${var.db_port}"
    db_name     = "${var.db_name}"
  }
}

module "metabase_lc" {
  source      = "../../utils/launch_configuration"
  environment = "${var.environment}"

  cluster_name            = "${aws_ecs_cluster.metabase.name}"
  key_name                = "${var.key_name}"
  iam_instance_profile_id = "${var.iam_instance_profile_id}"
  security_groups         = ["${var.security_groups}"]
}

resource "aws_autoscaling_group" "metabase_asg" {
  launch_configuration = "${module.metabase_lc.id}"
  min_size             = "${var.asg_min_size}"
  max_size             = "${var.asg_max_size}"
  health_check_type    = "ELB"
  vpc_zone_identifier  = ["${var.subnet_ids}"]
}

# Create a cluster for Metabase
resource "aws_ecs_cluster" "metabase" {
  name = "metabase-c-${var.environment}"
}

# Create a task definition for Metabase
resource "aws_ecs_task_definition" "metabase" {
  family                = "metabase-${var.environment}"
  container_definitions = "${data.template_file.metabase.rendered}"
}

# Create a Service for Metabase
resource "aws_ecs_service" "metabase" {
  name            = "metabase-${var.environment}"
  cluster         = "${aws_ecs_cluster.metabase.id}"
  task_definition = "${aws_ecs_task_definition.metabase.arn}"
  desired_count   = "${var.desired_count}"
}

/*
 * Outputs
 */

// ECS Service name
output "service_name" {
  value = "${aws_ecs_service.metabase.name}"
}
