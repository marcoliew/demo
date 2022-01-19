output "security_group_packer" {
  value = module.security_group_packer.security_group_id
}

output "security_group_fsx" {
  value = module.security_group_Fsx.security_group_id
}

output "ec2_profile_name" {
  value = aws_iam_instance_profile.ec2_profile.name
}

output "security_group_ec2" {
  value = concat([module.security_group_Ec2.security_group_id], tolist(data.aws_security_groups.smc_provided_sg_ids.ids))
  #module.security_group_Ec2.security_group_id
}

output "security_group_alb" {
  value = concat([module.security_group_Alb.security_group_id], tolist(data.aws_security_groups.smc_provided_sg_ids.ids))
  #module.security_group_Alb.security_group_id
}

#output "default-kp-ec2" {
#  value = aws_key_pair.default-kp-ec2.key_name
#}

output "event_run_ssm_doc_role_arn" {
  value = aws_iam_role.event_run_ssm_doc_role.arn
}

output "ssm_doc_asg_lifecycle_role_arn" {
  value = aws_iam_role.ssm_doc_asg_lifecycle_role.arn
}

output "sns_topic_default_notification_arn" {
  value = aws_sns_topic.DefaultNotificationTopic.arn
}

output "asg_hook_sns_role_arn" {
  value = aws_iam_role.asg_hook_sns_role.arn
}

output "esb_port" {
  value = var.esb_port
}