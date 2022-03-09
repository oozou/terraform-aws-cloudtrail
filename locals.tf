locals {
  check_kms_key_spoke_empty   = var.account_mode == "SPOKE" && var.kms_key_id == "" ? file("If account_mode is SPOKE, kms_key_id must not be empty.") : null
  check_s3_bucket_spoke_empty = var.account_mode == "SPOKE" && var.centralize_trail_bucket_name == "" ? file("If account_mode is SPOKE, centralize_trail_bucket_name must not be empty.") : null

  check_kms_key_hub_not_empty   = var.account_mode == "HUB" && var.kms_key_id != "" ? file("If account_mode is HUB, kms_key_id must be empty.") : null
  check_s3_bucket_hub_not_empty = var.account_mode == "HUB" && var.centralize_trail_bucket_name != "" ? file("If account_mode is HUB, centralize_trail_bucket_name must be empty.") : null
  name                          = "account-${var.environment}-monitor-trail"

  account_mode_count = var.account_mode == "HUB" ? 1 : 0

  account_ids = concat(var.spoke_account_ids, [data.aws_caller_identity.current.account_id])

  policy_identifiers = [for account in local.account_ids : join("", ["arn:aws:iam::", account, ":root"])]

  kms_key_id = var.kms_key_id != "" ? var.kms_key_id : join("", module.cloudtrail_kms.*.key_arn)

  centralize_log_bucket_arn = var.centralize_trail_bucket_name == "" ? join("", [module.centralize_log_bucket[0].bucket_arn]) : join("", ["arn:aws:s3:::", var.centralize_trail_bucket_name])

  tags = merge(
    {
      Terraform   = true
      Environment = var.environment
    },
    var.tags
  )
}
