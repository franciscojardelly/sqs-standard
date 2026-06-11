locals {
  name_prefix = "${var.project_name}-${var.environment}"
  queue_name  = "${local.name_prefix}-${var.queue_name_suffix}"
  dlq_name    = "${local.name_prefix}-${var.queue_name_suffix}-dlq"

  use_kms = var.kms_key_arn != ""

  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}
