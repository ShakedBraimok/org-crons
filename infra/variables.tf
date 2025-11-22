variable "environment" {
  description = "Environment name (e.g., dev, staging, prod, qa, etc.)"
  type        = string
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "eventbridge"
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "rules_path" {
  description = "Path to JSON file containing an array of rules to create"
  type        = string
  default     = "../rules.json"
}

variable "event_bus_name" {
  description = "Name of the event bus (default or custom)"
  type        = string
  default     = "default"
}

# Dead Letter Queue Configuration
variable "enable_dlq" {
  description = "Enable Dead Letter Queue for failed events"
  type        = bool
  default     = true
}

variable "dlq_retention_seconds" {
  description = "Message retention period for DLQ (in seconds)"
  type        = number
  default     = 1209600 # 14 days
}

# Encryption Configuration
variable "enable_encryption" {
  description = "Enable KMS encryption for SQS DLQ and SNS"
  type        = bool
  default     = true
}

variable "kms_deletion_window" {
  description = "KMS key deletion window in days"
  type        = number
  default     = 30
}

# Logging Configuration
variable "enable_logging" {
  description = "Enable CloudWatch Logs for EventBridge"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention period (days)"
  type        = number
  default     = 30
}

# Monitoring Configuration
variable "enable_monitoring" {
  description = "Enable CloudWatch alarms"
  type        = bool
  default     = true
}

variable "alarm_evaluation_periods" {
  description = "Number of periods to evaluate for alarms"
  type        = number
  default     = 2
}

variable "alarm_period" {
  description = "Period for alarm evaluation (seconds)"
  type        = number
  default     = 300
}

variable "failed_invocations_threshold" {
  description = "Threshold for failed invocations alarm"
  type        = number
  default     = 5
}

variable "alarm_actions" {
  description = "List of ARNs to notify when alarm triggers"
  type        = list(string)
  default     = []
}

# SNS Configuration
variable "create_sns_topic" {
  description = "Create SNS topic for alerts"
  type        = bool
  default     = false
}

variable "alert_email" {
  description = "Email address for CloudWatch alarms"
  type        = string
  default     = ""
}

# Tags
variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
