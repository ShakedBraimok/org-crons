# org-crons

Create event-driven workflows from a single JSON file - schedules, triggers, and pipelines - with DLQs, monitoring, and multi-environment support built in. production-ready EventBridge rules with DLQs, monitoring, alarms, and multi-environment support, so you can focus on your application logic, not AWS wiring.

# Quick Start Guide

Deploy EventBridge rules with clear step-by-step instructions. Each step includes validation commands and troubleshooting guidance.

## Prerequisites Checklist

Before you start, ensure you have:

- [ ] AWS CLI installed and configured (`aws --version`)
- [ ] Terraform >= 1.0 installed (`terraform version`)
- [ ] AWS credentials configured (`aws sts get-caller-identity`)
- [ ] Appropriate AWS permissions (EventBridge, SNS, CloudWatch, KMS, IAM)

## Step 1: Configure Your Rules

Create or edit `rules-dev.json` with your EventBridge rules:

```bash
cp examples/scheduled-lambda/rules.json rules-dev.json
# Edit rules-dev.json with your rules
```

**Example Rule Structure:**
```json
[
  {
    "rule_name": "daily-report",
    "description": "Trigger Lambda for daily reports",
    "schedule_expression": "cron(0 9 * * ? *)",
    "enabled": true,
    "targets": {
      "lambda": {
        "arn": "arn:aws:lambda:us-east-1:123456789012:function:report-generator"
      }
    }
  }
]
```

**Key Fields:**
- `rule_name`: Unique identifier for your rule
- `schedule_expression` OR `event_pattern`: Choose one
  - Schedule: `cron(0 9 * * ? *)` or `rate(5 minutes)`
  - Event pattern: `{"source": ["aws.ec2"], "detail-type": ["EC2 Instance State-change Notification"]}`
- `targets`: Where to send events (Lambda, SQS, SNS, Step Functions, etc.)

## Step 2: Configure Environment Variables

Create your environment configuration:

```bash
cd envs/dev
cp terraform.tfvars.example terraform.tfvars  # If example exists
# Or create new file
```

Edit `envs/dev/terraform.tfvars`:

```hcl
# Required
environment  = "dev"
project_name = "my-project"          # CHANGE THIS
aws_region   = "us-east-1"           # CHANGE THIS

# Path to your rules file
rules_path = "../../rules-dev.json"

# Optional: Monitoring and Alerts
enable_dlq          = true
enable_encryption   = true
enable_monitoring   = true
create_sns_topic    = true
alert_email         = "alerts@example.com"  # CHANGE THIS

# Optional: Advanced
log_retention_days     = 7
dlq_retention_seconds  = 345600  # 4 days
alarm_evaluation_periods = 2
```

## Step 3: Validate Configuration

```bash
# Validate your rules JSON
make validate-rules ENV=dev

# Validate Terraform configuration
make validate ENV=dev
```

**Common Issues:**
- Invalid JSON syntax → Check for trailing commas, missing quotes
- Invalid ARN format → Ensure target ARNs are complete and valid
- Invalid cron expression → Use AWS EventBridge cron format (6 fields)

## Step 4: Deploy

```bash
# See what will be created
make plan ENV=dev

# Deploy everything
make apply ENV=dev
```

**What gets created:**
- EventBridge rules from your JSON file
- Dead Letter Queue (DLQ) for failed events
- SNS topic for monitoring alerts
- CloudWatch alarms for rule failures
- KMS keys for encryption (if enabled)

## Step 5: Verify Deployment

```bash
# List all deployed rules
make list-rules ENV=dev

# Check rule status
make rule-status ENV=dev

# Check if any events ended up in DLQ
make check-dlq ENV=dev
```

## Next Steps

### Monitor Your Rules

```bash
# View CloudWatch dashboard
make outputs ENV=dev | grep dashboard_url

# View rule metrics
make rule-status ENV=dev

# Check DLQ for failed events
make check-dlq ENV=dev
```

### Add More Rules

1. Edit `rules-dev.json` and add new rules
2. Run `make validate-rules ENV=dev`
3. Run `make apply ENV=dev`

### Deploy to Staging/Production

```bash
# Copy and customize rules for staging
cp rules-dev.json rules-staging.json

# Create staging environment config
mkdir -p envs/staging
cp envs/dev/terraform.tfvars envs/staging/terraform.tfvars
# Edit staging tfvars (change environment = "staging")

# Deploy to staging
make deploy-all ENV=staging
```

## Common Use Cases

### Schedule-Based Rules
```json
{
  "rule_name": "hourly-backup",
  "schedule_expression": "rate(1 hour)",
  "targets": {"lambda": {"arn": "arn:aws:lambda:..."}}
}
```

### Event Pattern Rules
```json
{
  "rule_name": "s3-upload-trigger",
  "event_pattern": "{\"source\":[\"aws.s3\"],\"detail-type\":[\"Object Created\"]}",
  "targets": {"sqs": {"arn": "arn:aws:sqs:..."}}
}
```

### Multiple Targets
```json
{
  "rule_name": "critical-alert",
  "event_pattern": "{...}",
  "targets": {
    "lambda": {"arn": "arn:aws:lambda:..."},
    "sns": {"arn": "arn:aws:sns:..."},
    "sqs": {"arn": "arn:aws:sqs:..."}
  }
}
```

## Troubleshooting

### Rules not triggering?
1. Check rule is enabled: `make list-rules ENV=dev`
2. Verify target permissions (Lambda resource policy, SQS policy, etc.)
3. Check CloudWatch Logs for your targets
4. Look for events in DLQ: `make check-dlq ENV=dev`

### Terraform errors?
```bash
# Reinitialize
make init ENV=dev

# Check AWS credentials
aws sts get-caller-identity

# Enable debug logging
TF_LOG=DEBUG make apply ENV=dev
```

### JSON validation errors?
```bash
# Use jq to validate JSON
jq empty rules-dev.json

# Pretty-print to find syntax errors
jq . rules-dev.json
```

## Clean Up

To remove all resources:

```bash
make destroy ENV=dev
```

## Support

- Run `make help` to see all available commands and get help with common tasks
- Open a support ticket at [https://senora.dev/NewTicket](https://senora.dev/NewTicket)


## Environment Variables

This project uses environment-specific variable files in the `envs/` directory.

### dev
Variables are stored in `envs/dev/terraform.tfvars`



## GitHub Actions CI/CD

This project includes automated Terraform validation via GitHub Actions.

### Required GitHub Secrets

Configure these in Settings > Secrets > Actions:

- `AWS_ACCESS_KEY_ID`: Your AWS Access Key
- `AWS_SECRET_ACCESS_KEY`: Your AWS Secret Key
- `TF_STATE_BUCKET`: `senora-terraform-state-org-crons-6921f77660c6ce3fc4c93e03`
- `TF_STATE_KEY`: `org-crons/terraform.tfstate`


---
*Generated by [Senora](https://senora.dev)*
