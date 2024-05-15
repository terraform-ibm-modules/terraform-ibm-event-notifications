########################################################################################################################
# Resource Group
########################################################################################################################

module "resource_group" {
  source                       = "terraform-ibm-modules/resource-group/ibm"
  version                      = "1.1.5"
  resource_group_name          = var.use_existing_resource_group == false ? var.resource_group_name : null
  existing_resource_group_name = var.use_existing_resource_group == true ? var.resource_group_name : null
}

#######################################################################################################################
# KMS keys
#######################################################################################################################

locals {
  parsed_existing_kms_root_key_crn = var.existing_kms_root_key_crn != null ? split(":", var.existing_kms_root_key_crn) : []
  existing_kms_root_key_id         = length(local.parsed_existing_kms_root_key_crn) > 0 ? local.parsed_existing_kms_root_key_crn[length(local.parsed_existing_kms_root_key_crn) - 1] : null
  parsed_existing_kms_instance_crn = var.existing_kms_instance_crn != null ? split(":", var.existing_kms_instance_crn) : []
  kms_region                       = length(local.parsed_existing_kms_instance_crn) > 0 ? local.parsed_existing_kms_instance_crn[5] : null
  en_kms_key_id                    = local.existing_kms_root_key_id != null ? local.existing_kms_root_key_id : module.kms[0].keys[format("%s.%s", var.en_key_ring_name, var.en_key_name)].key_id
  kms_instance_guid                = var.existing_kms_instance_crn != null ? element(split(":", var.existing_kms_instance_crn), length(split(":", var.existing_kms_instance_crn)) - 3) : module.kms[0].kms_instance_guid
}

# KMS root key for Event Notifications
module "kms" {
  providers = {
    ibm = ibm.kms
  }
  count                       = var.existing_kms_root_key_crn != null ? 0 : 1 # no need to create any KMS resources if passing an existing key
  source                      = "terraform-ibm-modules/kms-all-inclusive/ibm"
  version                     = "4.8.4"
  create_key_protect_instance = false
  region                      = local.kms_region
  existing_kms_instance_guid  = var.existing_kms_instance_crn
  key_ring_endpoint_type      = var.kms_endpoint_type
  key_endpoint_type           = var.kms_endpoint_type
  keys = [
    {
      key_ring_name         = var.en_key_ring_name
      existing_key_ring     = false
      force_delete_key_ring = true
      keys = [
        {
          key_name                 = var.en_key_name
          standard_key             = false
          rotation_interval_month  = 3
          dual_auth_delete_enabled = false
          force_delete             = true
        }
      ]
    },
    {
      key_ring_name         = var.cos_key_ring_name
      existing_key_ring     = false
      force_delete_key_ring = true
      keys = [
        {
          key_name                 = var.cos_key_name
          standard_key             = false
          rotation_interval_month  = 3
          dual_auth_delete_enabled = false
          force_delete             = true
        }
      ]
    }
  ]
}

#######################################################################################################################
# COS
#######################################################################################################################

locals {
  cos_kms_key_crn   = var.existing_cos_bucket_name != null ? null : local.existing_kms_root_key_id != null ? local.existing_kms_root_key_id : module.kms[0].keys[format("%s.%s", var.cos_key_ring_name, var.cos_key_name)].crn
  cos_instance_guid = var.existing_cos_instance_crn != null ? element(split(":", var.existing_cos_instance_crn), length(split(":", var.existing_cos_instance_crn)) - 3) : module.cos.cos_instance_guid
  cos_bucket_name   = var.existing_cos_bucket_name != null ? var.existing_cos_bucket_name : module.cos.bucket_name
}

module "cos" {
  source                              = "terraform-ibm-modules/cos/ibm"
  version                             = "8.2.0"
  create_cos_instance                 = var.existing_cos_instance_crn == null ? true : false
  create_cos_bucket                   = var.existing_cos_bucket_name == null ? true : false
  add_bucket_name_suffix              = var.add_bucket_name_suffix
  resource_group_id                   = module.resource_group.resource_group_id
  region                              = var.region
  cross_region_location               = var.cross_region_location
  cos_instance_name                   = var.cos_instance_name
  cos_plan                            = var.cos_plan
  cos_tags                            = var.cos_instance_tags
  bucket_name                         = var.cos_bucket_name
  access_tags                         = var.cos_instance_access_tags
  management_endpoint_type_for_bucket = var.management_endpoint_type_for_bucket
  existing_kms_instance_guid          = local.kms_instance_guid
  kms_key_crn                         = local.cos_kms_key_crn
  sysdig_crn                          = var.existing_monitoring_crn
  retention_enabled                   = var.retention_enabled
  activity_tracker_crn                = var.existing_activity_tracker_crn
}


########################################################################################################################
# Event Notifications
########################################################################################################################

locals {
  # KMS Related
  existing_kms_instance_crn = var.existing_kms_instance_crn != null ? var.existing_kms_instance_crn : null
  cos_endpoint              = var.existing_cos_bucket_name == null ? "https://${module.cos.s3_endpoint_public}" : var.existing_cos_endpoint
}

module "event_notifications" {
  source                   = "../.."
  resource_group_id        = module.resource_group.resource_group_id
  region                   = var.region
  name                     = var.event_notification_name
  plan                     = var.service_plan
  tags                     = var.tags
  service_endpoints        = var.service_endpoints
  service_credential_names = var.service_credential_names
  # KMS Related
  kms_encryption_enabled    = true
  kms_endpoint_url          = var.kms_endpoint_url
  existing_kms_instance_crn = local.existing_kms_instance_crn
  root_key_id               = local.en_kms_key_id
  skip_en_kms_auth_policy   = var.skip_en_kms_auth_policy
  # COS Related
  cos_integration_enabled = true
  cos_destination_name    = var.cos_destination_name
  cos_bucket_name         = local.cos_bucket_name
  cos_instance_id         = local.cos_instance_guid
  skip_en_cos_auth_policy = var.skip_en_cos_auth_policy
  cos_endpoint            = local.cos_endpoint
}
