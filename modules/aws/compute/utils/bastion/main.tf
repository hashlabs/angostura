/**
 *## Description:
 *
 *Bastion creates a EC2 instance to be used as Bastion host for our infrastructure
 *
 *## Usage:
 *
 *```hcl
 *module "bastion" {
 *  source = "../../modules/compute/utils/bastion"
 *
 *  environment            = "${var.environment}"
 *  key_name               = "${data.terraform_remote_state.base.ecs_key_name}"
 *  subnet_id              = "${module.vpc.public_subnet_ids[0]}"
 *  vpc_security_group_ids = ["${module.vpc.bastion_security_group_id}"]
 *}
 *```
 */

/*
 * Variables
 */
variable "environment" {
  description = "Environment"
}

variable "key_name" {
  description = "SSH Key Pair to be assigned to the Launch Configuration for the instances running in this cluster"
}

variable "instance_type" {
  description = "EC2 instance type for Bastion"
  default     = "t2.nano"
}

variable "subnet_id" {
  description = "VPC Security Groups IDs to be used in the Launch Configuration for the instances running in this cluster"
}

variable "vpc_security_group_ids" {
  description = "VPC Security Groups IDs to be used in the Launch Configuration for the instances running in this cluster"
  type        = "list"
}

/*
 * Resources
 */
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "bastion" {
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "${var.instance_type}"

  key_name = "${var.key_name}"

  subnet_id              = "${var.subnet_id}"
  vpc_security_group_ids = ["${var.vpc_security_group_ids}"]

  tags {
    Class       = "terraform"
    Environment = "${var.environment}"
  }
}

resource "aws_eip" "bastion_eip" {
  vpc      = true
  instance = "${aws_instance.bastion.id}"
}

/*
 * Outputs
 */
output "ip" {
  value = "${aws_eip.bastion_eip.public_ip}"
}
