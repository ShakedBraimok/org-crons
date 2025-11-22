output "rule_arns" {
  description = "Map of rule names to their ARNs"
  value = {
    for name, rule in module.eventbridge_rule : name => rule.rule_arn
  }
}

output "rule_ids" {
  description = "Map of rule names to their IDs"
  value = {
    for name, rule in module.eventbridge_rule : name => rule.rule_id
  }
}

output "rules_summary" {
  description = "Summary of all created rules"
  value = {
    for name, rule in module.eventbridge_rule : name => {
      arn     = rule.rule_arn
      id      = rule.rule_id
      enabled = try(rule.enabled, true)
    }
  }
}

output "dlq_url" {
  description = "Dead Letter Queue URL"
  value       = var.enable_dlq ? aws_sqs_queue.eventbridge_dlq[0].url : null
}

output "dlq_arn" {
  description = "Dead Letter Queue ARN"
  value       = var.enable_dlq ? aws_sqs_queue.eventbridge_dlq[0].arn : null
}

output "kms_key_id" {
  description = "KMS key ID for encryption"
  value       = var.enable_encryption ? aws_kms_key.eventbridge[0].id : null
}

output "kms_key_arn" {
  description = "KMS key ARN for encryption"
  value       = var.enable_encryption ? aws_kms_key.eventbridge[0].arn : null
}

output "log_group_name" {
  description = "CloudWatch Log Group name"
  value       = var.enable_logging ? aws_cloudwatch_log_group.eventbridge[0].name : null
}

output "sns_topic_arn" {
  description = "SNS topic ARN for alerts"
  value       = var.create_sns_topic ? aws_sns_topic.eventbridge_alerts[0].arn : null
}

output "alarm_arns" {
  description = "CloudWatch alarm ARNs"
  value = var.enable_monitoring ? {
    failed_invocations = aws_cloudwatch_metric_alarm.failed_invocations[0].arn
    dlq_messages       = var.enable_dlq ? aws_cloudwatch_metric_alarm.dlq_messages[0].arn : null
  } : {}
}

output "event_bus_name" {
  description = "Event bus name used"
  value       = var.event_bus_name
}

output "deployment_info" {
  description = "Deployment information"
  value = {
    environment   = var.environment
    project_name  = var.project_name
    region        = var.aws_region
    rules_count   = length(local.rules)
    dlq_enabled   = var.enable_dlq
    monitoring    = var.enable_monitoring
    encryption    = var.enable_encryption
  }
}
