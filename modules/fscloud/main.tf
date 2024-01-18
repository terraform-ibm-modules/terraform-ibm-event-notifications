module "event_notification" {
  source                        = "../../"
  resource_group_id             = var.resource_group_id
  name                          = var.name
  plan                          = "standard"
  kms_encryption_enabled        = true
  skip_iam_authorization_policy = var.skip_iam_authorization_policy
  existing_kms_instance_crn     = var.existing_kms_instance_crn
  root_key_id                   = var.root_key_id
  tags                          = var.tags
  service_endpoints             = "public-and-private"
  kms_endpoint                  = "private"
  cbr_rules                     = var.cbr_rules
  region                        = var.region
  kms_region                    = var.kms_region
}
