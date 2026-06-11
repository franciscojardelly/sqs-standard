# ── Infrastructure ────────────────────────────────────────────────────────────

variable "project_name" {
  description = "Name of the project, used as a prefix for all resource names."
  type        = string
  nullable    = false
}

variable "environment" {
  description = "Deployment environment name. One of: dev, staging, prod."
  type        = string
  nullable    = false

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Must be one of: dev, staging, prod."
  }
}

variable "aws_region" {
  description = "AWS region where all resources will be deployed."
  type        = string
  nullable    = false
}

# ── Queue identity ─────────────────────────────────────────────────────────────

variable "queue_name_suffix" {
  description = "Suffix that identifies the queue purpose, appended after the project and environment prefix (e.g. 'orders', 'file-events')."
  type        = string
  nullable    = false
}

# ── Queue behaviour ───────────────────────────────────────────────────────────

variable "visibility_timeout_seconds" {
  description = "Duration (in seconds) that a received message is hidden from other consumers. Must be >= the consumer processing time. Range: 0–43200."
  type        = number
  default     = 30

  validation {
    condition     = var.visibility_timeout_seconds >= 0 && var.visibility_timeout_seconds <= 43200
    error_message = "Must be between 0 and 43200 seconds."
  }
}

variable "message_retention_seconds" {
  description = "Number of seconds Amazon SQS retains a message. Range: 60 (1 min) to 1209600 (14 days). Default: 345600 (4 days)."
  type        = number
  default     = 345600

  validation {
    condition     = var.message_retention_seconds >= 60 && var.message_retention_seconds <= 1209600
    error_message = "Must be between 60 and 1209600 seconds."
  }
}

variable "max_message_size" {
  description = "Maximum message size in bytes. Range: 1024 (1 KB) to 262144 (256 KB). Default: 262144."
  type        = number
  default     = 262144

  validation {
    condition     = var.max_message_size >= 1024 && var.max_message_size <= 262144
    error_message = "Must be between 1024 and 262144 bytes."
  }
}

variable "delay_seconds" {
  description = "Seconds to delay delivery of all messages. Range: 0–900. Default: 0."
  type        = number
  default     = 0

  validation {
    condition     = var.delay_seconds >= 0 && var.delay_seconds <= 900
    error_message = "Must be between 0 and 900 seconds."
  }
}

variable "receive_wait_time_seconds" {
  description = "Long-polling wait time in seconds. 0 = short polling; 1–20 = long polling (recommended: 20)."
  type        = number
  default     = 20

  validation {
    condition     = var.receive_wait_time_seconds >= 0 && var.receive_wait_time_seconds <= 20
    error_message = "Must be between 0 and 20 seconds."
  }
}

# ── Dead-letter queue ─────────────────────────────────────────────────────────

variable "max_receive_count" {
  description = "Number of times a message can be received before being sent to the DLQ. Range: 1–1000."
  type        = number
  default     = 3

  validation {
    condition     = var.max_receive_count >= 1 && var.max_receive_count <= 1000
    error_message = "Must be between 1 and 1000."
  }
}

variable "dlq_message_retention_seconds" {
  description = "Number of seconds the DLQ retains failed messages. Range: 60 to 1209600. Default: 1209600 (14 days)."
  type        = number
  default     = 1209600

  validation {
    condition     = var.dlq_message_retention_seconds >= 60 && var.dlq_message_retention_seconds <= 1209600
    error_message = "Must be between 60 and 1209600 seconds."
  }
}

# ── Encryption ────────────────────────────────────────────────────────────────

variable "kms_key_arn" {
  description = "ARN of a KMS key for SSE-KMS encryption. Leave empty to use SSE-SQS (AWS-managed keys — no extra cost)."
  type        = string
  default     = ""
}

variable "kms_data_key_reuse_period_seconds" {
  description = "Seconds SQS can reuse a KMS data key before calling KMS again. Range: 60–86400. Ignored when kms_key_arn is empty."
  type        = number
  default     = 300

  validation {
    condition     = var.kms_data_key_reuse_period_seconds >= 60 && var.kms_data_key_reuse_period_seconds <= 86400
    error_message = "Must be between 60 and 86400 seconds."
  }
}

# ── Tags ──────────────────────────────────────────────────────────────────────

variable "tags" {
  description = "Additional tags to merge into all resources."
  type        = map(string)
  default     = {}
}
