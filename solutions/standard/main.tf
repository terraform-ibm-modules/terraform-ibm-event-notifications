########################################################################################################################
# Resource Group
########################################################################################################################

module "resource_group" {
  source                       = "terraform-ibm-modules/resource-group/ibm"
  version                      = "1.1.4"
  resource_group_name          = var.existing_resource_group == false ? var.resource_group_name : null
  existing_resource_group_name = var.existing_resource_group == true ? var.resource_group_name : null
}

########################################################################################################################
# Event Notifications
########################################################################################################################

locals {
  service_credential_names = var.service_credential_names
  # KMS Add on
  existing_kms_instance_crn = var.existing_kms_instance_crn != null ? var.existing_kms_instance_crn : null
  kms_endpoint_url          = var.kms_encryption_enabled ? var.kms_endpoint_url != null ? var.kms_endpoint_url : format("https://%s.kms.cloud.ibm.com", var.region) : null
  kms_root_key_id           = var.kms_root_key_id != null ? var.kms_root_key_id : null
}

module "event_notifications" {
  source                        = "../.."
  resource_group_id             = module.resource_group.resource_group_id
  region                        = var.region
  name                          = var.event_notification_name
  plan                          = var.service_plan
  tags                          = var.tags
  service_endpoints             = var.service_endpoints
  service_credential_names      = local.service_credential_names
  skip_iam_authorization_policy = var.skip_iam_authorization_policy
  # KMS Add on
  kms_encryption_enabled    = var.kms_encryption_enabled
  kms_endpoint_url          = local.kms_endpoint_url
  existing_kms_instance_crn = local.existing_kms_instance_crn
  root_key_id               = local.kms_root_key_id
}
