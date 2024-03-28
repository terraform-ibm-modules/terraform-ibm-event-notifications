########################################################################################################################
# Resource Group
########################################################################################################################

module "resource_group" {
  source                       = "terraform-ibm-modules/resource-group/ibm"
  version                      = "1.1.5"
  resource_group_name          = var.existing_resource_group == false ? var.resource_group_name : null
  existing_resource_group_name = var.existing_resource_group == true ? var.resource_group_name : null
}

#######################################################################################################################
# KMS Keys
#######################################################################################################################

locals {
  en_kms_key_id              = var.existing_kms_root_key_id != null ? var.existing_kms_root_key_id : module.kms[0].keys[format("%s.%s", var.en_key_ring_name, var.en_key_name)].key_id
  kms_instance_crn           = var.existing_kms_instance_crn != null ? var.existing_kms_instance_crn : module.kms[0].key_protect_id
  kms_endpoint_url           = var.kms_endpoint_url != null ? var.kms_endpoint_url : module.kms[0].kp_private_endpoint
  existing_kms_instance_guid = var.existing_kms_instance_crn != null ? element(split(":", var.existing_kms_instance_crn), length(split(":", var.existing_kms_instance_crn)) - 3) : module.kms[0].key_protect_guid
}

# KMS root key for Event Notifications
module "kms" {
  providers = {
    ibm = ibm.kms
  }
  count                       = var.existing_kms_root_key_id != null || var.existing_cos_bucket_name != null ? 0 : 1 # no need to create any KMS resources if passing an existing key, or bucket
  source                      = "terraform-ibm-modules/kms-all-inclusive/ibm"
  version                     = "4.8.4"
  create_key_protect_instance = false
  region                      = var.kms_region
  existing_kms_instance_guid  = local.existing_kms_instance_guid
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
  cos_kms_key_crn   = var.existing_cos_bucket_name != null ? null : var.existing_kms_root_key_id != null ? var.existing_kms_root_key_id : module.kms[0].keys[format("%s.%s", var.cos_key_ring_name, var.cos_key_name)].crn
  cos_instance_crn  = var.existing_cos_instance_crn != null ? var.existing_cos_instance_crn : module.cos[0].cos_instance_crn
  cos_instance_guid = var.existing_cos_instance_crn != null ? element(split(":", var.existing_cos_instance_crn), length(split(":", var.existing_cos_instance_crn)) - 3) : module.cos[0].cos_instance_guid
  cos_bucket_name   = var.existing_cos_bucket_name != null ? var.existing_cos_bucket_name : module.cos[0].buckets[var.cos_bucket_name].bucket_name

  activity_tracking = var.existing_activity_tracker_crn != null ? {
    read_data_events     = true
    write_data_events    = true
    activity_tracker_crn = var.existing_activity_tracker_crn
  } : null

  metrics_monitoring = var.existing_monitoring_crn != null ? {
    usage_metrics_enabled   = true
    request_metrics_enabled = true
    metrics_monitoring_crn  = var.existing_monitoring_crn
  } : null
}

module "cos" {
  providers = {
    ibm = ibm.cos
  }
  count                    = var.existing_cos_bucket_name == null ? 1 : 0 # no need to call COS module if consumer is passing existing COS bucket
  source                   = "terraform-ibm-modules/cos/ibm//modules/fscloud"
  version                  = "7.5.0"
  resource_group_id        = module.resource_group.resource_group_id
  create_cos_instance      = var.existing_cos_instance_crn == null ? true : false # don't create instance if existing one passed in
  create_resource_key      = false
  cos_instance_name        = var.cos_instance_name
  cos_tags                 = var.cos_instance_tags
  existing_cos_instance_id = var.existing_cos_instance_crn
  access_tags              = var.cos_instance_access_tags
  cos_plan                 = "standard"
  bucket_configs = [{
    access_tags                   = var.cos_bucket_access_tags
    add_bucket_name_suffix        = var.add_bucket_name_suffix
    bucket_name                   = var.cos_bucket_name
    kms_encryption_enabled        = true
    kms_guid                      = local.existing_kms_instance_guid
    kms_key_crn                   = local.cos_kms_key_crn
    skip_iam_authorization_policy = var.skip_cos_kms_auth_policy
    management_endpoint_type      = var.management_endpoint_type_for_bucket
    storage_class                 = var.cos_bucket_class
    resource_instance_id          = local.cos_instance_crn
    region_location               = var.cos_region
    force_delete                  = true
    activity_tracking             = local.activity_tracking
    metrics_monitoring            = local.metrics_monitoring
  }]
}

########################################################################################################################
# Event Notifications
########################################################################################################################

locals {
  cos_endpoint = var.cos_endpoint == null ? "https://${module.cos[0].buckets[var.cos_bucket_name].s3_endpoint_private}" : var.cos_endpoint
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
  kms_endpoint_url          = local.kms_endpoint_url
  existing_kms_instance_crn = local.kms_instance_crn
  root_key_id               = local.en_kms_key_id
  skip_en_kms_auth_policy   = var.skip_en_kms_auth_policy
  # COS Related
  cos_integration_enabled = true
  cos_destination_name    = var.cos_destination_name
  cos_bucket_name         = local.cos_bucket_name
  cos_instance_id         = local.cos_instance_guid
  cos_region              = var.cos_region
  skip_en_cos_auth_policy = var.skip_en_cos_auth_policy
  cos_endpoint            = local.cos_endpoint
}
