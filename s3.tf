module "centralize_log_bucket" {
  count  = 1 - local.account_mode
  source = "git@github.com:oozou/terraform-aws-s3?ref=v1.0.1"

  prefix      = var.prefix
  bucket_name = "account-trail"
  environment = "centralize"

  centralize_hub     = true
  versioning_enabled = true
  force_s3_destroy   = false

  is_enable_s3_hardening_policy = false

  is_create_consumer_readonly_policy = true

  lifecycle_rules = var.centralize_trail_bucket_lifecycle_rule

  additional_bucket_polices = [data.aws_iam_policy_document.s3_cloudtrail[count.index].json]

  kms_key_arn = { kms_arn = local.kms_key_id }

  tags = var.tags
}
