project_name      = "my-project"
environment       = "dev"
aws_region        = "us-east-1"
queue_name_suffix = "file-events"

# Queue behaviour
visibility_timeout_seconds = 30
message_retention_seconds  = 345600 # 4 days
max_message_size           = 262144 # 256 KB
delay_seconds              = 0
receive_wait_time_seconds  = 20 # long polling

# Dead-letter queue
max_receive_count             = 3
dlq_message_retention_seconds = 1209600 # 14 days

# Encryption — SSE-SQS (no extra cost)
kms_key_arn = ""

tags = {
  Owner = "platform-team"
  Team  = "data-engineering"
}
