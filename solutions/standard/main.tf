########################################################################################################################
# Resource Group
########################################################################################################################

module "resource_group" {
  source                       = "terraform-ibm-modules/resource-group/ibm"
  version                      = "1.1.6"
  resource_group_name          = var.use_existing_resource_group == false ? (var.prefix != null ? "${var.prefix}-${var.resource_group_name}" : var.resource_group_name) : null
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
  kms_instance_guid                = var.existing_kms_instance_crn != null ? element(split(":", var.existing_kms_instance_crn), length(split(":", var.existing_kms_instance_crn)) - 3) : module.kms[0].kms_instance_guid
  en_key_name                      = var.prefix != null ? "${var.prefix}-${var.en_key_name}" : var.en_key_name
  en_key_ring_name                 = var.prefix != null ? "${var.prefix}-${var.en_key_ring_name}" : var.en_key_ring_name
  en_kms_key_id                    = local.existing_kms_root_key_id != null ? local.existing_kms_root_key_id : module.kms[0].keys[format("%s.%s", local.en_key_ring_name, local.en_key_name)].key_id
  cos_key_name                     = var.prefix != null ? "${var.prefix}-${var.cos_key_name}" : var.cos_key_name
  cos_key_ring_name                = var.prefix != null ? "${var.prefix}-${var.cos_key_ring_name}" : var.cos_key_ring_name
  cos_kms_key_crn                  = var.existing_cos_bucket_name != null ? null : var.existing_kms_root_key_crn != null ? var.existing_kms_root_key_crn : module.kms[0].keys[format("%s.%s", local.cos_key_ring_name, local.cos_key_name)].crn
}

# KMS root key for Event Notifications
module "kms" {
  providers = {
    ibm = ibm.kms
  }
  count                       = var.existing_kms_root_key_crn != null ? 0 : 1 # no need to create any KMS resources if passing an existing key
  source                      = "terraform-ibm-modules/kms-all-inclusive/ibm"
  version                     = "4.15.2"
  create_key_protect_instance = false
  region                      = local.kms_region
  existing_kms_instance_crn   = var.existing_kms_instance_crn
  key_ring_endpoint_type      = var.kms_endpoint_type
  key_endpoint_type           = var.kms_endpoint_type
  keys = [
    {
      key_ring_name         = local.en_key_ring_name
      existing_key_ring     = false
      force_delete_key_ring = true
      keys = [
        {
          key_name                 = local.en_key_name
          standard_key             = false
          rotation_interval_month  = 3
          dual_auth_delete_enabled = false
          force_delete             = true
        }
      ]
    },
    {
      key_ring_name         = local.cos_key_ring_name
      existing_key_ring     = false
      force_delete_key_ring = true
      keys = [
        {
          key_name                 = local.cos_key_name
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
  # tflint-ignore: terraform_unused_declarations
  validate_cos_regions        = var.cos_bucket_region != null && var.cross_region_location != null ? tobool("Cannot provide values for var.cos_bucket_region and var.cross_region_location") : true
  cos_bucket_name             = var.existing_cos_bucket_name != null ? var.existing_cos_bucket_name : (var.prefix != null ? "${var.prefix}-${var.cos_bucket_name}" : var.cos_bucket_name)
  cos_bucket_name_with_suffix = var.existing_cos_bucket_name != null ? var.existing_cos_bucket_name : module.cos[0].bucket_name
  cos_bucket_region           = var.cos_bucket_region != null ? var.cos_bucket_region : var.cross_region_location != null ? null : var.region
  cos_instance_name           = var.prefix != null ? "${var.prefix}-${var.cos_instance_name}" : var.cos_instance_name
}

module "cos" {
  count                               = var.existing_cos_bucket_name != null ? 0 : 1
  source                              = "terraform-ibm-modules/cos/ibm"
  version                             = "8.9.1"
  create_cos_instance                 = var.existing_cos_instance_crn == null ? true : false
  create_cos_bucket                   = var.existing_cos_bucket_name == null ? true : false
  existing_cos_instance_id            = var.existing_cos_instance_crn
  skip_iam_authorization_policy       = var.skip_cos_kms_auth_policy
  add_bucket_name_suffix              = var.add_bucket_name_suffix
  resource_group_id                   = module.resource_group.resource_group_id
  region                              = local.cos_bucket_region
  cross_region_location               = var.cross_region_location
  cos_instance_name                   = local.cos_instance_name
  cos_plan                            = var.cos_plan
  cos_tags                            = var.cos_instance_tags
  bucket_name                         = local.cos_bucket_name
  access_tags                         = var.cos_instance_access_tags
  management_endpoint_type_for_bucket = var.management_endpoint_type_for_bucket
  existing_kms_instance_guid          = local.kms_instance_guid
  kms_key_crn                         = local.cos_kms_key_crn
  monitoring_crn                      = var.existing_monitoring_crn
  retention_enabled                   = var.retention_enabled
  activity_tracker_crn                = var.existing_activity_tracker_crn
  archive_days                        = var.archive_days
}


########################################################################################################################
# Event Notifications
########################################################################################################################

locals {
  # KMS Related
  existing_kms_instance_crn = var.existing_kms_instance_crn != null ? var.existing_kms_instance_crn : null
  cos_endpoint              = var.existing_cos_bucket_name == null ? "https://${module.cos[0].s3_endpoint_public}" : var.existing_cos_endpoint
  # Event Notification Related
  parsed_existing_en_instance_crn = var.existing_en_instance_crn != null ? split(":", var.existing_en_instance_crn) : []
  existing_en_guid                = length(local.parsed_existing_en_instance_crn) > 0 ? local.parsed_existing_en_instance_crn[7] : null
}

data "ibm_resource_instance" "existing_en" {
  count      = var.existing_en_instance_crn == null ? 0 : 1
  identifier = var.existing_en_instance_crn
}

module "event_notifications" {
  count                    = var.existing_en_instance_crn != null ? 0 : 1
  source                   = "../.."
  resource_group_id        = module.resource_group.resource_group_id
  region                   = var.region
  name                     = var.prefix != null ? "${var.prefix}-${var.event_notification_name}" : var.event_notification_name
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
  cos_bucket_name         = local.cos_bucket_name_with_suffix
  cos_instance_id         = var.existing_cos_instance_crn != null ? var.existing_cos_instance_crn : module.cos[0].cos_instance_crn
  skip_en_cos_auth_policy = var.skip_en_cos_auth_policy
  cos_endpoint            = local.cos_endpoint
}

#create a service authorization between Secrets Manager and the target service (Event Notification)
resource "ibm_iam_authorization_policy" "policy" {
  count                       = var.skip_es_kms_auth_policy ? 0 : 1
  depends_on                  = [module.event_notifications]
  source_service_name         = "secrets-manager"
  source_resource_instance_id = local.existing_secrets_manager_instance_guid
  target_service_name         = "Event Notifications"
  target_resource_instance_id = module.elasticsearch.guid
  roles                       = ["Key Manager"]
}

# workaround for https://github.com/IBM-Cloud/terraform-provider-ibm/issues/4478
resource "time_sleep" "wait_for_es_authorization_policy" {
  depends_on      = [ibm_iam_authorization_policy.policy]
  create_duration = "30s"
}

locals {
  service_credential_secrets = [
    for service_credentials in var.service_credential_secrets : {
      secret_group_name        = service_credentials.secret_group_name
      secret_group_description = service_credentials.secret_group_description
      existing_secret_group    = service_credentials.existing_secret_group
      secrets = [
        for secret in service_credentials.service_credentials : {
          secret_name                             = secret.secret_name
          secret_labels                           = secret.secret_labels
          secret_auto_rotation                    = secret.secret_auto_rotation
          secret_auto_rotation_unit               = secret.secret_auto_rotation_unit
          secret_auto_rotation_interval           = secret.secret_auto_rotation_interval
          service_credentials_ttl                 = secret.service_credentials_ttl
          service_credential_secret_description   = secret.service_credential_secret_description
          service_credentials_source_service_role = secret.service_credentials_source_service_role
          service_credentials_source_service_crn  = module.elasticsearch.crn
          secret_type                             = "service_credentials" #checkov:skip=CKV_SECRET_6
        }
      ]
    }
  ]

  existing_secrets_manager_instance_crn_split = var.existing_secrets_manager_instance_crn != null ? split(":", var.existing_secrets_manager_instance_crn) : null
  existing_secrets_manager_instance_guid      = var.existing_secrets_manager_instance_crn != null ? element(local.existing_secrets_manager_instance_crn_split, length(local.existing_secrets_manager_instance_crn_split) - 3) : null
  existing_secrets_manager_instance_region    = var.existing_secrets_manager_instance_crn != null ? element(local.existing_secrets_manager_instance_crn_split, length(local.existing_secrets_manager_instance_crn_split) - 5) : null
}

module "secrets_manager_service_credentials" {
  depends_on                  = [time_sleep.wait_for_es_authorization_policy]
  source                      = "terraform-ibm-modules/secrets-manager/ibm//modules/secrets"
  version                     = "1.16.1"
  existing_sm_instance_guid   = local.existing_secrets_manager_instance_guid
  existing_sm_instance_region = local.existing_secrets_manager_instance_region
  endpoint_type               = var.existing_secrets_manager_endpoint_type
  secrets                     = local.service_credential_secrets
}