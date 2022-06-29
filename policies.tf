data "aws_iam_policy_document" "kms_cloudtrail" {
  count = 1 - local.account_mode
  statement {
    sid    = "Enable CloudTrail Key Permission"
    effect = "Allow"
    actions = [
      "kms:GenerateDataKey*",
      "kms:Decrypt",
      "kms:List*",
      "kms:DescribeKey*",
      "kms:Encrypt",
      "kms:ReEncrypt*"
    ]
    resources = ["*"]
    principals {
      identifiers = ["cloudtrail.amazonaws.com"]
      type        = "Service"
    }
    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:cloudtrail:arn"
      values   = [for account in local.account_ids : join("", ["arn:aws:cloudtrail:*:", account, ":trail/*"])]
    }
  }

  # TODO RESTRICT
  statement {
    sid    = "Allow CloudWatch log Key Permission"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["logs.amazonaws.com"]
    }
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    resources = ["*"]
    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:aws:logs:ap-southeast-1:*:log-group:/aws/cloudtrail/${local.name}*"]
    }
  }

  statement {
    sid    = "Allow AWS Services to use the key"
    effect = "Allow"
    actions = [
      "kms:GenerateDataKey*",
      "kms:Decrypt",
      "kms:List*",
      "kms:DescribeKey*",
      "kms:Encrypt",
      "kms:ReEncrypt*"
    ]
    resources = ["*"]
    principals {
      identifiers = local.policy_identifiers
      type        = "AWS"
    }
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values = [
        "s3.ap-southeast-1.amazonaws.com",
        "lambda.ap-southeast-1.amazonaws.com"
      ]
    }
  }
}

data "aws_iam_policy_document" "s3_cloudtrail" {
  count = 1 - local.account_mode
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"
    actions = [
      "s3:GetBucketAcl"
    ]
    resources = [local.centralize_log_bucket_arn]
    principals {
      identifiers = [
        "cloudtrail.amazonaws.com"
      ]
      type = "Service"
    }
  }

  statement {
    sid    = "Allow cross-account access for CloudTrail check"
    effect = "Allow"
    actions = [
      "s3:GetObjectVersionAcl",
      "s3:GetBucketLogging",
      "s3:GetBucketPolicy",
      "s3:GetBucketAcl"
    ]
    resources = [
      local.centralize_log_bucket_arn,
      "${local.centralize_log_bucket_arn}/AWSLogs/*"
    ]
    principals {
      identifiers = local.policy_identifiers
      type        = "AWS"
    }
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = [for account in local.account_ids : join("", [local.centralize_log_bucket_arn, "/AWSLogs/", account, "/*"])]
    principals {
      identifiers = [
        "cloudtrail.amazonaws.com"
      ]
      type = "Service"
    }
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  statement {
    sid    = "DenyDeleteObject"
    effect = "Deny"
    actions = [
      "s3:Delete*"
    ]
    resources = [
      local.centralize_log_bucket_arn,
      "${local.centralize_log_bucket_arn}/*"
    ]
    principals {
      identifiers = ["*"]
      type        = "*"
    }
  }

  statement {
    sid    = "DenyIncorrectEncryptionHeader"
    effect = "Deny"
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "${local.centralize_log_bucket_arn}/*"
    ]
    principals {
      identifiers = ["*"]
      type        = "AWS"
    }
    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["aws:kms", "AES256"]
    }
  }

  statement {
    sid    = "DenyUnEncryptedObjectUploads"
    effect = "Deny"
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "${local.centralize_log_bucket_arn}/*"
    ]
    principals {
      identifiers = ["*"]
      type        = "*"
    }
    condition {
      test     = "Null"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["true"]
    }
  }
}
