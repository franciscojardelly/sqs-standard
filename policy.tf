# ── Main queue policy ─────────────────────────────────────────────────────────

data "aws_iam_policy_document" "this" {
  statement {
    sid     = "DenyNonSSL"
    effect  = "Deny"
    actions = ["sqs:*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    resources = [aws_sqs_queue.this.arn]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_sqs_queue_policy" "this" {
  queue_url = aws_sqs_queue.this.id
  policy    = data.aws_iam_policy_document.this.json
}

# ── DLQ policy ────────────────────────────────────────────────────────────────

data "aws_iam_policy_document" "dlq" {
  statement {
    sid     = "DenyNonSSL"
    effect  = "Deny"
    actions = ["sqs:*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    resources = [aws_sqs_queue.dlq.arn]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_sqs_queue_policy" "dlq" {
  queue_url = aws_sqs_queue.dlq.id
  policy    = data.aws_iam_policy_document.dlq.json
}
