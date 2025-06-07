########################################################################################################################
# Resource Group
########################################################################################################################

module "resource_group" {
  source                       = "terraform-ibm-modules/resource-group/ibm"
  version                      = "1.2.0"
  existing_resource_group_name = var.existing_resource_group_name
}

#######################################################################################################################
# KMS keys
#######################################################################################################################

# parse KMS details from the existing KMS instance CRN
module "existing_kms_crn_parser" {
  count   = var.existing_kms_instance_crn != null ? 1 : 0
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.1.0"
  crn     = var.existing_kms_instance_crn
}

# If existing KMS root key CRN passed, parse details from it
module "existing_kms_key_crn_parser" {
  count   = var.existing_kms_root_key_crn != null ? 1 : 0
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.1.0"
  crn     = var.existing_kms_root_key_crn
}

locals {
  prefix = (var.prefix != null && trimspace(var.prefix) != "" ? "${var.prefix}-" : "")

  # If an existing KMS root key, or an existing EN instance is passed, or KMS is not enabled do not create a new KMS root key
  create_kms_keys = !var.kms_encryption_enabled || var.existing_kms_root_key_crn != null || var.existing_event_notifications_instance_crn != null ? false : true

  kms_region                = var.kms_encryption_enabled ? var.existing_kms_instance_crn != null ? module.existing_kms_crn_parser[0].region : var.existing_kms_root_key_crn != null ? module.existing_kms_key_crn_parser[0].region : null : null
  existing_kms_guid         = var.kms_encryption_enabled ? var.existing_kms_instance_crn != null ? module.existing_kms_crn_parser[0].service_instance : var.existing_kms_root_key_crn != null ? module.existing_kms_key_crn_parser[0].service_instance : null : null
  kms_service_name          = var.kms_encryption_enabled ? var.existing_kms_instance_crn != null ? module.existing_kms_crn_parser[0].service_name : var.existing_kms_root_key_crn != null ? module.existing_kms_key_crn_parser[0].service_name : null : null
  kms_account_id            = var.kms_encryption_enabled ? var.existing_kms_instance_crn != null ? module.existing_kms_crn_parser[0].account_id : var.existing_kms_root_key_crn != null ? module.existing_kms_key_crn_parser[0].account_id : null : null
  en_kms_key_id             = local.create_kms_keys ? module.kms[0].keys[format("%s.%s", local.en_key_ring_name, local.en_key_name)].key_id : var.existing_kms_root_key_crn != null ? module.existing_kms_key_crn_parser[0].resource : null
  existing_kms_instance_crn = var.kms_encryption_enabled ? var.existing_kms_instance_crn != null ? var.existing_kms_instance_crn : "crn:v1:bluemix:${module.existing_kms_key_crn_parser[0].ctype}:${module.existing_kms_key_crn_parser[0].service_name}:${module.existing_kms_key_crn_parser[0].region}:${module.existing_kms_key_crn_parser[0].scope}:${module.existing_kms_key_crn_parser[0].service_instance}::" : null

  # Create cross account EN / KMS auth policy if not using existing EN instance, if 'skip_en_kms_auth_policy' is false, and a value is passed for 'ibmcloud_key_management_service_api_key'
  create_cross_account_en_kms_auth_policy = var.existing_event_notifications_instance_crn == null && !var.skip_event_notifications_kms_auth_policy && var.ibmcloud_kms_api_key != null
  # Create cross account COS / KMS auth policy if not using existing EN instance, if 'skip_cos_kms_auth_policy' is false, and if a value is passed for 'ibmcloud_key_management_service_api_key'
  create_cross_account_cos_kms_auth_policy = var.existing_event_notifications_instance_crn == null && !var.skip_cos_kms_auth_policy && var.ibmcloud_kms_api_key != null
  # If a prefix value is passed, add it to the EN key name
  en_key_name = "${local.prefix}${var.event_notifications_key_name}"
  # If a prefix value is passed, add it to the EN key ring name
  en_key_ring_name = "${local.prefix}${var.event_notifications_key_ring_name}"
  # Use existing key if set. Else if new key and if a prefix value is passed, add it to the COS key name
  cos_key_name = "${local.prefix}${var.cos_key_name}"
  # Determine the COS KMS key CRN (new key or existing key). It will only have a value if not using an existing bucket or existing EN instance
  cos_kms_key_crn = var.existing_event_notifications_instance_crn != null ? null : var.kms_encryption_enabled ? var.existing_kms_root_key_crn != null ? var.existing_kms_root_key_crn : module.kms[0].keys[format("%s.%s", local.en_key_ring_name, local.cos_key_name)].crn : null
  # If existing KMS instance CRN passed, parse the key ID from it
  cos_kms_key_id = local.cos_kms_key_crn != null ? module.cos_kms_key_crn_parser[0].resource : null
}

module "kms" {
  providers = {
    ibm = ibm.kms
  }
  count                       = local.create_kms_keys ? 1 : 0
  source                      = "terraform-ibm-modules/kms-all-inclusive/ibm"
  version                     = "5.1.7"
  create_key_protect_instance = false
  region                      = local.kms_region
  existing_kms_instance_crn   = var.existing_kms_instance_crn
  key_ring_endpoint_type      = var.kms_endpoint_type
  key_endpoint_type           = var.kms_endpoint_type
  keys = [
    {
      key_ring_name = local.en_key_ring_name
      keys = [
        {
          key_name                 = local.en_key_name
          standard_key             = false
          rotation_interval_month  = 3
          dual_auth_delete_enabled = false
          force_delete             = true
        },
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

# If not using an existing EN instance, parse details from the new or existing KMS key CRN used for COS
module "cos_kms_key_crn_parser" {
  count   = (local.create_kms_keys || var.existing_kms_root_key_crn != null) ? 1 : 0
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.1.0"
  crn     = local.cos_kms_key_crn
}

# Create cross account IAM Authorization Policy to allow COS to read the KMS encryption key
resource "ibm_iam_authorization_policy" "cos_kms_policy" {
  count                       = local.create_cross_account_cos_kms_auth_policy ? 1 : 0
  provider                    = ibm.kms
  source_service_account      = local.cos_account_id
  source_service_name         = "cloud-object-storage"
  source_resource_instance_id = local.cos_instance_guid
  roles                       = ["Reader"]
  description                 = "Allow the COS instance ${local.cos_instance_guid} to read the ${local.kms_service_name} key ${local.cos_kms_key_id} from the instance ${local.existing_kms_guid}"
  resource_attributes {
    name     = "serviceName"
    operator = "stringEquals"
    value    = local.kms_service_name
  }
  resource_attributes {
    name     = "accountId"
    operator = "stringEquals"
    value    = local.kms_account_id
  }
  resource_attributes {
    name     = "serviceInstance"
    operator = "stringEquals"
    value    = local.existing_kms_guid
  }
  resource_attributes {
    name     = "resourceType"
    operator = "stringEquals"
    value    = "key"
  }
  resource_attributes {
    name     = "resource"
    operator = "stringEquals"
    value    = local.cos_kms_key_id
  }
  # Scope of policy now includes the key, so ensure to create new policy before
  # destroying old one to prevent any disruption to every day services.
  lifecycle {
    create_before_destroy = true
  }
}

# Create cross account IAM Authorization Policy to allow EN to read the KMS encryption key
resource "ibm_iam_authorization_policy" "en_kms_policy" {
  count                       = local.create_cross_account_en_kms_auth_policy ? 1 : 0
  provider                    = ibm.kms
  source_service_account      = module.event_notifications[0].account_id
  source_service_name         = "event-notifications"
  source_resource_instance_id = module.event_notifications[0].guid
  roles                       = ["Reader"]
  description                 = "Allow the EN instance with GUID ${module.event_notifications[0].guid} to read the ${local.kms_service_name} key ${local.cos_kms_key_id} from the instance ${local.existing_kms_guid}}"
  resource_attributes {
    name     = "serviceName"
    operator = "stringEquals"
    value    = local.kms_service_name
  }
  resource_attributes {
    name     = "accountId"
    operator = "stringEquals"
    value    = local.kms_account_id
  }
  resource_attributes {
    name     = "serviceInstance"
    operator = "stringEquals"
    value    = local.existing_kms_guid
  }
  resource_attributes {
    name     = "resourceType"
    operator = "stringEquals"
    value    = "key"
  }
  resource_attributes {
    name     = "resource"
    operator = "stringEquals"
    value    = local.cos_kms_key_id
  }
  # Scope of policy now includes the key, so ensure to create new policy before
  # destroying old one to prevent any disruption to every day services.
  lifecycle {
    create_before_destroy = true
  }
}

#######################################################################################################################
# COS
#######################################################################################################################

# parse COS details from the existing COS instance CRN
module "existing_cos_crn_parser" {
  count   = var.existing_cos_instance_crn != null ? 1 : 0
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.1.0"
  crn     = var.existing_cos_instance_crn
}

locals {
  # If not collecting failed events, or an existing EN CRN is passed; do not create COS resources
  create_cos_bucket = !var.enable_collecting_failed_events || var.existing_event_notifications_instance_crn != null ? false : true
  # determine COS details
  cos_bucket_name             = var.existing_event_notifications_instance_crn == null && !var.enable_collecting_failed_events ? null : local.create_cos_bucket ? "${local.prefix}${var.cos_bucket_name}" : null
  cos_bucket_name_with_suffix = var.existing_event_notifications_instance_crn == null && var.enable_collecting_failed_events ? module.cos_buckets[0].buckets[local.cos_bucket_name].bucket_name : null
  cos_bucket_region           = var.existing_event_notifications_instance_crn == null && var.cos_bucket_region != null && var.cos_bucket_region != "" ? var.cos_bucket_region : var.region
  cos_instance_guid           = var.existing_event_notifications_instance_crn == null ? (var.existing_cos_instance_crn == null ? (length(module.cos_buckets) > 0 ? module.cos_buckets.bucket_configs.cos_instance_guid : null) : module.existing_cos_crn_parser[0].service_instance) : null
  cos_bucket_endpoint         = var.existing_event_notifications_instance_crn == null && var.enable_collecting_failed_events ? "https://${module.cos_buckets[0].buckets[local.cos_bucket_name].s3_endpoint_direct}" : null
  cos_account_id              = var.existing_event_notifications_instance_crn == null ? var.existing_cos_instance_crn != null ? split("/", module.existing_cos_crn_parser[0].scope)[1] : null : null
}

locals {
  bucket_config = [{
    access_tags                   = var.cos_bucket_access_tags
    bucket_name                   = local.cos_bucket_name
    add_bucket_name_suffix        = var.add_bucket_name_suffix
    kms_encryption_enabled        = var.kms_encryption_enabled
    kms_guid                      = local.existing_kms_guid
    kms_key_crn                   = local.cos_kms_key_crn
    skip_iam_authorization_policy = var.skip_cos_kms_auth_policy
    management_endpoint_type      = var.management_endpoint_type_for_bucket
    storage_class                 = var.cos_bucket_class
    resource_instance_id          = var.existing_cos_instance_crn
    region_location               = local.cos_bucket_region
    activity_tracking = {
      read_data_events  = true
      write_data_events = true
      management_events = true
    }
    metrics_monitoring = {
      usage_metrics_enabled   = true
      request_metrics_enabled = true
      metrics_monitoring_crn  = var.existing_monitoring_crn
    }
    force_delete = true
  }]
}

module "cos_buckets" {
  count          = var.enable_collecting_failed_events && var.existing_event_notifications_instance_crn == null ? 1 : 0
  source         = "terraform-ibm-modules/cos/ibm//modules/buckets"
  version        = "9.0.5"
  bucket_configs = local.bucket_config
}

########################################################################################################################
# Event Notifications
########################################################################################################################

# If existing EN intance CRN passed, parse details from it
module "existing_en_crn_parser" {
  count   = var.existing_event_notifications_instance_crn != null ? 1 : 0
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.1.0"
  crn     = var.existing_event_notifications_instance_crn
}

locals {
  # determine if existing EN instance being used
  use_existing_en_instance = var.existing_event_notifications_instance_crn != null
  # if using existing EN instance, parse the GUID from it
  existing_en_instance_guid = local.use_existing_en_instance ? module.existing_en_crn_parser[0].service_instance : null
  # determine the EN GUID
  eventnotification_guid = local.use_existing_en_instance ? local.existing_en_instance_guid : module.event_notifications[0].guid
  # determine the EN CRN
  eventnotification_crn = local.use_existing_en_instance ? var.existing_event_notifications_instance_crn : module.event_notifications[0].crn
}

# Lookup instance if using an existing one
data "ibm_resource_instance" "existing_en_instance" {
  count      = local.use_existing_en_instance ? 1 : 0
  identifier = local.existing_en_instance_guid
}

module "event_notifications" {
  count                    = local.use_existing_en_instance ? 0 : 1
  source                   = "../.."
  resource_group_id        = module.resource_group.resource_group_id
  region                   = var.region
  name                     = "${local.prefix}${var.event_notifications_instance_name}"
  plan                     = var.service_plan
  tags                     = var.event_notifications_resource_tags
  access_tags              = var.event_notifications_access_tags
  service_endpoints        = var.service_endpoints
  service_credential_names = var.service_credential_names
  # KMS Related
  kms_encryption_enabled    = var.kms_encryption_enabled
  kms_endpoint_url          = var.kms_endpoint_url
  existing_kms_instance_crn = local.existing_kms_instance_crn
  root_key_id               = local.en_kms_key_id
  skip_en_kms_auth_policy   = local.create_cross_account_en_kms_auth_policy || var.skip_event_notifications_kms_auth_policy
  # COS Related
  cos_integration_enabled = var.enable_collecting_failed_events
  cos_bucket_name         = local.cos_bucket_name_with_suffix
  cos_instance_id         = var.existing_cos_instance_crn
  skip_en_cos_auth_policy = var.skip_event_notifications_cos_auth_policy
  cos_endpoint            = local.cos_bucket_endpoint
  cbr_rules               = var.cbr_rules
}

########################################################################################################################
# Service Credentials
########################################################################################################################

# If existing EN instance CRN passed, parse details from it
module "existing_sm_crn_parser" {
  count   = var.existing_secrets_manager_instance_crn != null ? 1 : 0
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.1.0"
  crn     = var.existing_secrets_manager_instance_crn
}

locals {
  # parse SM GUID from CRN
  existing_secrets_manager_instance_guid = var.existing_secrets_manager_instance_crn != null ? module.existing_sm_crn_parser[0].service_instance : null
  # parse SM region from CRN
  existing_secrets_manager_instance_region = var.existing_secrets_manager_instance_crn != null ? module.existing_sm_crn_parser[0].region : null
  # generate list of service credential secrets to create
  service_credential_secrets = [
    for service_credentials in var.service_credential_secrets : {
      secret_group_name        = service_credentials.secret_group_name
      secret_group_description = service_credentials.secret_group_description
      existing_secret_group    = service_credentials.existing_secret_group
      secrets = [
        for secret in service_credentials.service_credentials : {
          secret_name                                 = secret.secret_name
          secret_labels                               = secret.secret_labels
          secret_auto_rotation                        = secret.secret_auto_rotation
          secret_auto_rotation_unit                   = secret.secret_auto_rotation_unit
          secret_auto_rotation_interval               = secret.secret_auto_rotation_interval
          service_credentials_ttl                     = secret.service_credentials_ttl
          service_credential_secret_description       = secret.service_credential_secret_description
          service_credentials_source_service_role_crn = secret.service_credentials_source_service_role_crn
          service_credentials_source_service_crn      = local.eventnotification_crn
          secret_type                                 = "service_credentials" #checkov:skip=CKV_SECRET_6
        }
      ]
    }
  ]
}

# create a service authorization between Secrets Manager and the target service (Event Notification)
resource "ibm_iam_authorization_policy" "secrets_manager_key_manager" {
  count                       = var.skip_event_notifications_secrets_manager_auth_policy || var.existing_secrets_manager_instance_crn == null ? 0 : 1
  source_service_name         = "secrets-manager"
  source_resource_instance_id = local.existing_secrets_manager_instance_guid
  target_service_name         = "event-notifications"
  target_resource_instance_id = local.eventnotification_guid
  roles                       = ["Key Manager"]
  description                 = "Allow Secrets Manager instance to manage key for the event-notification instance"
}

# workaround for https://github.com/IBM-Cloud/terraform-provider-ibm/issues/4478
resource "time_sleep" "wait_for_en_authorization_policy" {
  depends_on      = [ibm_iam_authorization_policy.secrets_manager_key_manager]
  create_duration = "30s"
}

module "secrets_manager_service_credentials" {
  count                       = length(local.service_credential_secrets) > 0 ? 1 : 0
  depends_on                  = [time_sleep.wait_for_en_authorization_policy]
  source                      = "terraform-ibm-modules/secrets-manager/ibm//modules/secrets"
  version                     = "2.5.1"
  existing_sm_instance_guid   = local.existing_secrets_manager_instance_guid
  existing_sm_instance_region = local.existing_secrets_manager_instance_region
  endpoint_type               = var.existing_secrets_manager_endpoint_type
  secrets                     = local.service_credential_secrets
}
