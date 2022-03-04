/* -------------------------------------------------------------------------- */
/*                                   AWS_KMS                                  */
/* -------------------------------------------------------------------------- */
module "cloudtrail_kms" {
  count = var.is_create_monitor_trail && var.cloudtrail_encrypted ? 1 : 0

  source      = "git@github.com:oozou/terraform-aws-kms-key.git?ref=v0.0.1"
  key_type    = "service"
  description = "Used to encrypt data in ${local.name}"
  alias_name  = "${local.name}-kms"
}
