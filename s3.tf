# resource "aws_s3_bucket" "hub_trails" {
#     bucket = "${var.env_name}-centralized-trails-${data.aws_caller_identity.current.account_id}"
#     acl    = "private"
#     policy = file("./policy/centralized-trails-bucket-policy.json")

#     server_side_encryption_configuration {
#     rule {
#         apply_server_side_encryption_by_default {
#             kms_master_key_id = aws_kms_key.centralized_kms_key.arn
#             sse_algorithm     = "aws:kms"
#             }
#         }
#     }

#     versioning {
#         enabled = true
#     }

#     lifecycle_rule {
#         id      = "LogLifecycleManagement"
#         enabled = true
#         transition {
#         days          = 31
#         storage_class = "STANDARD_IA"
#         }

#         transition {
#         days          = 366
#         storage_class = "GLACIER"
#         }

#         expiration {
#         days = 3660
#         }
#     }
# }

# resource "aws_s3_bucket_policy" "default" {
#   bucket = aws_s3_bucket.default.id
#   policy = data.aws_iam_policy_document.hub_trails.json
# }

# resource "aws_s3_bucket_public_access_block" "centralized_trails" {
#     bucket = aws_s3_bucket.centralized_trails.id
#     block_public_acls   = true
#     block_public_policy = true
#     ignore_public_acls = true
#     restrict_public_buckets = true
# }


# data "aws_iam_policy_document" "hub_trails" {
#   statement {
#     sid    = "Cloudtrail ACL Check"
#     effect = "Allow"

#     principals {
#       type        = "Service"
#       identifiers = ["cloudtrail.amazonaws.com"]
#     }

#     actions = [
#       "s3:GetBucketAcl",
#     ]

#     resources = [
#       "arn:aws:s3:::${var.name}",
#     ]
#   }

#   statement {
#     sid    = "Allow cross accout access for CloudTrail"
#     effect = "Allow"

#     principals {
#       type        = "AWS"
#       identifiers = ["arn:aws:iam::${var.accountid}:root"]
#     }

#     actions = [
#       "s3:GetObjectVersionAcl",
#       "s3:GetBucketLogging",
#       "s3:GetBucketPolicy",
#       "s3:GetBucketAcl"
#     ]

#     resources = [
#       "arn:aws:s3:::${var.name}",
#       "arn:aws:s3:::${var.name}/logs/*"
#     ]
#   }

#   statement {
#     sid    = "CloudTrail Write"
#     effect = "Allow"

#     principals {
#       type        = "Service"
#       identifiers = ["cloudtrail.amazonaws.com"]
#     }

#     actions = [
#       "s3:PutObject",
#     ]

#     resources = [
#       "arn:aws:s3:::${var.name}/*",
#     ]

#     condition {
#       test     = "StringEquals"
#       variable = "s3:x-amz-acl"

#       values = [
#         "bucket-owner-full-control",
#       ]
#     }
#   }

#   statement {
#     sid    = "Deny Delete"
#     effect = "Deny"

#     principals {
#       identifiers = "*"
#     }

#     actions = [
#       "s3:Delete*",
#     ]

#     resources = [
#       "arn:aws:s3:::${var.name}",
#       "arn:aws:s3:::${var.name}/*"
#     ]
#   }
# }
