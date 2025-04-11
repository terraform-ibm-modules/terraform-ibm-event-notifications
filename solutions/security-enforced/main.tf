
#######################################################################################################################
# Wrapper around fully-configurable variation
#######################################################################################################################

module "event_notifications" {
  source                       = "../fully-configurable"
  ibmcloud_api_key             = var.ibmcloud_api_key
  provider_visibility          = "private"
  existing_resource_group_name = var.existing_resource_group_name
  region                       = var.region
  prefix                       = var.prefix
  # Event Notifications Related
  service_credential_names                  = var.service_credential_names
  event_notifications_name                  = var.event_notifications_name
  service_plan                              = var.service_plan
  service_endpoints                         = "public-and-private"
  event_notifications_resource_tags         = var.event_notifications_resource_tags
  event_notifications_access_tags           = var.event_notifications_access_tags
  existing_event_notifications_instance_crn = var.existing_event_notifications_instance_crn
  # KMS Related
  kms_encryption_enabled                   = true
  existing_kms_instance_crn                = var.existing_kms_instance_crn
  existing_kms_root_key_crn                = var.existing_kms_root_key_crn
  kms_endpoint_url                         = var.kms_endpoint_url
  kms_endpoint_type                        = "private"
  event_notifications_key_ring_name        = var.event_notifications_key_ring_name
  event_notifications_key_name             = var.event_notifications_key_name
  cos_key_ring_name                        = var.cos_key_ring_name
  cos_key_name                             = var.cos_key_name
  skip_event_notifications_kms_auth_policy = var.skip_event_notifications_kms_auth_policy
  ibmcloud_kms_api_key                     = var.ibmcloud_kms_api_key
  # COS Related
  enable_collecting_failed_events          = true
  existing_cos_instance_crn                = var.existing_cos_instance_crn
  cos_bucket_name                          = var.cos_bucket_name
  skip_event_notifications_cos_auth_policy = var.skip_event_notifications_cos_auth_policy
  skip_cos_kms_auth_policy                 = var.skip_cos_kms_auth_policy
  cos_bucket_access_tags                   = var.cos_bucket_access_tags
  add_bucket_name_suffix                   = var.add_bucket_name_suffix
  kms_encryption_enabled_bucket            = true
  cos_bucket_region                        = var.cos_bucket_region
  management_endpoint_type_for_bucket      = "private"
  #  SM related
  existing_secrets_manager_instance_crn                = var.existing_secrets_manager_instance_crn
  existing_secrets_manager_endpoint_type               = "private"
  service_credential_secrets                           = var.service_credential_secrets
  skip_event_notifications_secrets_manager_auth_policy = var.skip_event_notifications_secrets_manager_auth_policy

  cbr_rules = var.cbr_rules
}
