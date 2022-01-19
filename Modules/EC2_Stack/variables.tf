variable "subnet_list" {

}

variable "app" {}

variable "lhd" {}

variable "environment" {}

variable "instancerole" {
  type = string

}

variable "max_size" {}

variable "elb_logging_bucket" {}


variable "min_size" {}

variable "desired_size" {}

variable "instance_type" {}

variable "health_check_grace_period" {}

variable "health_check_type" {}

variable "force_delete" {}

variable "termination_policies" {}

variable "ec2_instance_role" {}

variable "timeouts" {}

variable "vpc_id" {}

#variable "key_name" {}

variable "alb_security_groups" {
  description = "A list of security group IDs"
  type        = list(string)
}

variable "ec2_security_groups" {
  description = "A list of security group IDs"
  type        = list(string)
}

variable "event_run_ssm_doc_role_arn" {}

variable "ssm_doc_asg_lifecycle_role_arn" {}

variable "userdata_filename" {}

variable "sns_topic_default_notification_arn" {}

variable "asg_hook_sns_role_arn" {}

variable "lb_healthcheck_path" {}

variable "eH_std_tags"{
type        = map(string)
  description = "eHealth Std Tags for each resource"
}

variable "nlb_subnet_mapping" {}

variable "esb_port" {}