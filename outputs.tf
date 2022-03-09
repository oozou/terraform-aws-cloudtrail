output "cloudtrail_id" {
  description = "S3 Bucket Id"
  value       = join("", aws_cloudtrail.this.*.id)
}

output "cloudtrail_arn" {
  description = "S3 Bucket ARN"
  value       = join("", aws_cloudtrail.this.*.arn)
}

output "centralize_bucket_name" {
  description = "S3 Bucket Name"
  value       = join("", module.centralize_log_bucket.*.bucket_name)
}

output "centralize_bucket_arn" {
  description = "S3 Bucket ARN"
  value       = join("", module.centralize_log_bucket.*.bucket_arn)
}

output "centralize_key_arn" {
  description = "KMS key arn"
  value       = join("", module.cloudtrail_kms.*.key_arn)
}

output "centralize_key_id" {
  description = "KMS key id"
  value       = join("", module.cloudtrail_kms.*.key_id)
}

