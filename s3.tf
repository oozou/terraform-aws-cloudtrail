module "centralize_log_bucket" {
  count  = local.account_mode_count == 1 ? 1 : 0
  source = "git@github.com:oozou/terraform-aws-s3?ref=v1.0.1"

  prefix      = "account"
  bucket_name = "monitor-trail"
  environment = "centralize"

  centralize_hub     = true
  versioning_enabled = true
  force_s3_destroy   = false

  is_enable_s3_hardening_policy = false

  is_create_consumer_readonly_policy = true

  lifecycle_rules = var.centralize_trail_bucket_lifecycle_rule

  tags = var.tags

  additional_bucket_polices = [data.aws_iam_policy_document.s3_cloudtrail[count.index].json]

  kms_key_arn = { kms_arn = local.kms_key_id }
}
