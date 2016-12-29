/**
 *## Description:
 *
 *Launch Configuration module creates a `aws_launch_configuration` resource with the provided variables.
 *
 *## Usage:
 *
 *```hcl
 *module "microservices_lc" {
 *  source = "../utils/launch_configuration"
 *  environment = "${var.environment}"
 *
 *  cluster_name            = "${aws_ecs_cluster.microservices.name}"
 *  key_name                = "${var.key_name}"
 *  iam_instance_profile_id = "${var.iam_instance_profile_id}"
 *  security_groups         = "${var.security_groups}"
 *  instance_type           = "${var.instance_type}"
 *  swap_size               = "2G"
 *}
 *```
 */

/*
 * Variables
 */
variable "environment" {
  description = "Environment"
}

variable "cluster_name" {
  description = "ECS cluster name"
}

variable "key_name" {
  description = "SSH Key Pair to be assigned to the Launch Configuration for the instances running in this cluster"
}

variable "iam_instance_profile_id" {
  description = "IAM Profile ID to be used in the Launch Configuration for the instances running in this cluster"
}

variable "instance_type" {
  description = "Instace type Launch Configuration for the instances running in this cluster"
  default     = "t2.micro"
}

variable "security_groups" {
  description = "VPC Security Groups IDs to be used in the Launch Configuration for the instances running in this cluster"
  type        = "list"
}

variable "image_id" {
  description = "AMI ID, this needs to match the region you are running instances on"
  default     = "ami-6df8fe7a"
}

variable "swap_size" {
  description = "The size of the swapfile to be created in the instance"
  default     = "1G"
}

/*
 * Resources
 */
data "template_file" "user_data" {
  template = "${file("${path.module}/user_data.sh")}"

  vars {
    environment  = "${var.environment}"
    cluster_name = "${var.cluster_name}"
    swap_size    = "${var.swap_size}"
  }
}

resource "aws_launch_configuration" "launch_configuration" {
  name_prefix          = "${var.environment}-"
  iam_instance_profile = "${var.iam_instance_profile_id}"
  image_id             = "${var.image_id}"
  instance_type        = "${var.instance_type}"
  key_name             = "${var.key_name}"
  security_groups      = ["${var.security_groups}"]
  user_data            = "${data.template_file.user_data.rendered}"

  lifecycle {
    create_before_destroy = true
  }
}

/*
 * Outputs
 */

// Launch Configuration ID
output "id" {
  value = "${aws_launch_configuration.launch_configuration.id}"
}
