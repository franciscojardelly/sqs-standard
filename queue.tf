# ── Dead-letter queue ─────────────────────────────────────────────────────────

resource "aws_sqs_queue" "dlq" {
  name = local.dlq_name

  message_retention_seconds = var.dlq_message_retention_seconds
  receive_wait_time_seconds = var.receive_wait_time_seconds

  # Encryption — mirrors the main queue
  sqs_managed_sse_enabled           = local.use_kms ? null : true
  kms_master_key_id                 = local.use_kms ? var.kms_key_arn : null
  kms_data_key_reuse_period_seconds = local.use_kms ? var.kms_data_key_reuse_period_seconds : null

  tags = {
    Name = local.dlq_name
  }
}

# Allows only the main queue to redrive messages into the DLQ.
resource "aws_sqs_queue_redrive_allow_policy" "dlq" {
  queue_url = aws_sqs_queue.dlq.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = [aws_sqs_queue.this.arn]
  })
}

# ── Main queue ────────────────────────────────────────────────────────────────

resource "aws_sqs_queue" "this" {
  name = local.queue_name

  visibility_timeout_seconds = var.visibility_timeout_seconds
  message_retention_seconds  = var.message_retention_seconds
  max_message_size           = var.max_message_size
  delay_seconds              = var.delay_seconds
  receive_wait_time_seconds  = var.receive_wait_time_seconds

  # Encryption
  sqs_managed_sse_enabled           = local.use_kms ? null : true
  kms_master_key_id                 = local.use_kms ? var.kms_key_arn : null
  kms_data_key_reuse_period_seconds = local.use_kms ? var.kms_data_key_reuse_period_seconds : null

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = var.max_receive_count
  })

  tags = {
    Name = local.queue_name
  }
}

resource "aws_sqs_queue_redrive_policy" "this" {
  queue_url = aws_sqs_queue.this.id

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = var.max_receive_count
  })
}
