# ── Main queue ────────────────────────────────────────────────────────────────

output "this_sqs_queue_id" {
  description = "URL of the main SQS queue (used as queue identifier in AWS SDK calls)."
  value       = aws_sqs_queue.this.id
}

output "this_sqs_queue_arn" {
  description = "ARN of the main SQS queue — use this in IAM policies and event source mappings."
  value       = aws_sqs_queue.this.arn
}

output "this_sqs_queue_name" {
  description = "Name of the main SQS queue."
  value       = aws_sqs_queue.this.name
}

output "this_sqs_queue_url" {
  description = "URL of the main SQS queue."
  value       = aws_sqs_queue.this.url
}

# ── Dead-letter queue ─────────────────────────────────────────────────────────

output "dlq_sqs_queue_id" {
  description = "URL of the dead-letter queue."
  value       = aws_sqs_queue.dlq.id
}

output "dlq_sqs_queue_arn" {
  description = "ARN of the dead-letter queue."
  value       = aws_sqs_queue.dlq.arn
}

output "dlq_sqs_queue_name" {
  description = "Name of the dead-letter queue."
  value       = aws_sqs_queue.dlq.name
}
