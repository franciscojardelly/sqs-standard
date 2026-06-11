project_name      = "my-project"
environment       = "prod"
aws_region        = "us-east-1"
queue_name_suffix = "file-events"

# Queue behaviour
visibility_timeout_seconds = 30
message_retention_seconds  = 604800 # 7 days
max_message_size           = 262144 # 256 KB
delay_seconds              = 0
receive_wait_time_seconds  = 20 # long polling

# Dead-letter queue
max_receive_count             = 5
dlq_message_retention_seconds = 1209600 # 14 days

# Encryption — fill with KMS key ARN for SSE-KMS in prod (recommended)
kms_key_arn                       = "" # e.g. "arn:aws:kms:us-east-1:123456789012:key/mrk-..."
kms_data_key_reuse_period_seconds = 300

tags = {
  Owner = "platform-team"
  Team  = "data-engineering"
}
