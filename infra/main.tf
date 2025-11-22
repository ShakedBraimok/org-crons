terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    # Backend configuration should be provided via backend config file
    # Example: terraform init -backend-config=backend-${ENV}.tfvars
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
      Template    = "eventbridge-rules"
    }
  }
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  rules       = jsondecode(file(var.rules_path))

  # Merge default tags with custom tags
  common_tags = merge(
    {
      Environment = var.environment
      Project     = var.project_name
      Terraform   = "true"
    },
    var.tags
  )
}

# EventBridge Rules
module "eventbridge_rule" {
  for_each = { for r in local.rules : r.rule_name => r }
  source   = "Senora-dev/eventbridge-rule/aws"
  version  = "~> 1.0"

  rule_name           = "${local.name_prefix}-${each.value.rule_name}"
  rule_description    = try(each.value.description, "EventBridge rule ${each.value.rule_name}")
  schedule_expression = try(each.value.schedule_expression, null)
  event_pattern       = try(each.value.event_pattern, null)

  # Rule state
  is_enabled = try(each.value.enabled, true)

  # Targets configuration with DLQ support
  targets = {
    for target_key, target in try(each.value.targets, {}) : target_key => merge(
      target,
      var.enable_dlq ? {
        dead_letter_config = {
          arn = aws_sqs_queue.eventbridge_dlq[0].arn
        }
      } : {}
    )
  }

  # Tags
  tags = merge(
    local.common_tags,
    try(each.value.tags, {})
  )
}

# Dead Letter Queue for failed events
resource "aws_sqs_queue" "eventbridge_dlq" {
  count = var.enable_dlq ? 1 : 0

  name                       = "${local.name_prefix}-eventbridge-dlq"
  message_retention_seconds  = var.dlq_retention_seconds
  visibility_timeout_seconds = 300

  kms_master_key_id = var.enable_encryption ? aws_kms_key.eventbridge[0].id : null

  tags = local.common_tags
}

# DLQ Policy
resource "aws_sqs_queue_policy" "eventbridge_dlq" {
  count = var.enable_dlq ? 1 : 0

  queue_url = aws_sqs_queue.eventbridge_dlq[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.eventbridge_dlq[0].arn
      }
    ]
  })
}

# KMS Key for encryption
resource "aws_kms_key" "eventbridge" {
  count = var.enable_encryption ? 1 : 0

  description             = "KMS key for EventBridge encryption"
  deletion_window_in_days = var.kms_deletion_window
  enable_key_rotation     = true

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-eventbridge-key"
    }
  )
}

resource "aws_kms_alias" "eventbridge" {
  count = var.enable_encryption ? 1 : 0

  name          = "alias/${local.name_prefix}-eventbridge"
  target_key_id = aws_kms_key.eventbridge[0].key_id
}

# CloudWatch Log Group for EventBridge debugging
resource "aws_cloudwatch_log_group" "eventbridge" {
  count = var.enable_logging ? 1 : 0

  name              = "/aws/events/${local.name_prefix}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.enable_encryption ? aws_kms_key.eventbridge[0].arn : null

  tags = local.common_tags
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "failed_invocations" {
  count = var.enable_monitoring ? 1 : 0

  alarm_name          = "${local.name_prefix}-eventbridge-failed-invocations"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "FailedInvocations"
  namespace           = "AWS/Events"
  period              = var.alarm_period
  statistic           = "Sum"
  threshold           = var.failed_invocations_threshold
  alarm_description   = "EventBridge failed invocations exceeded threshold"
  alarm_actions       = var.alarm_actions

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "dlq_messages" {
  count = var.enable_monitoring && var.enable_dlq ? 1 : 0

  alarm_name          = "${local.name_prefix}-eventbridge-dlq-messages"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "Messages in EventBridge DLQ"
  alarm_actions       = var.alarm_actions

  dimensions = {
    QueueName = aws_sqs_queue.eventbridge_dlq[0].name
  }

  tags = local.common_tags
}

# SNS Topic for alarms (optional)
resource "aws_sns_topic" "eventbridge_alerts" {
  count = var.create_sns_topic ? 1 : 0

  name              = "${local.name_prefix}-eventbridge-alerts"
  kms_master_key_id = var.enable_encryption ? aws_kms_key.eventbridge[0].id : null

  tags = local.common_tags
}

resource "aws_sns_topic_subscription" "eventbridge_alerts_email" {
  count = var.create_sns_topic && var.alert_email != "" ? 1 : 0

  topic_arn = aws_sns_topic.eventbridge_alerts[0].arn
  protocol  = "email"
  endpoint  = var.alert_email
}
