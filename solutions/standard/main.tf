########################################################################################################################
# Resource Group
########################################################################################################################

# Create new resource group, or take in existing group
module "resource_group" {
  count                        = var.existing_en_instance_crn == null ? 1 : 0
  source                       = "terraform-ibm-modules/resource-group/ibm"
  version                      = "1.1.6"
  resource_group_name          = var.use_existing_resource_group == false ? (var.prefix != null ? "${var.prefix}-${var.resource_group_name}" : var.resource_group_name) : null
  existing_resource_group_name = var.use_existing_resource_group == true ? var.resource_group_name : null
}

#######################################################################################################################
# KMS keys
#######################################################################################################################

# Input variable validation
locals {
  # Validate that a value has been passed for 'existing_kms_instance_crn' and 'kms_endpoint_url' if not using existing EN instance
  # tflint-ignore: terraform_unused_declarations
  validate_kms_input = (var.existing_kms_instance_crn == null || var.kms_endpoint_url == null) && var.existing_en_instance_crn == null ? tobool("A value for 'existing_kms_instance_crn' and 'kms_endpoint_url' must be passed when no value is passed for 'existing_en_instance_crn'.") : true
}

# If existing KMS root key CRN passed, parse details from it
module "kms_root_key_crn_parser" {
  count   = var.existing_kms_root_key_crn != null ? 1 : 0
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.1.0"
  crn     = var.existing_kms_root_key_crn
}

# If existing KMS intance CRN passed, parse details from it
module "kms_instance_crn_parser" {
  count   = var.existing_kms_instance_crn != null ? 1 : 0
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.1.0"
  crn     = var.existing_kms_instance_crn
}

# If not using an existing COS bucket, or an existing EN instance, parse details from the KMS key CRN used for COS
module "cos_kms_key_crn_parser" {
  count   = var.existing_cos_bucket_name == null && var.existing_en_instance_crn == null ? 1 : 0
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.1.0"
  crn     = local.cos_kms_key_crn
}

locals {
  # If an existing KMS root key, or an existing EN instance is passed, do not create a new KMS root key
  create_kms_keys = var.existing_kms_root_key_crn != null || var.existing_en_instance_crn != null ? false : true
  # If existing KMS root key CRN passed, parse the ID from it
  existing_en_kms_root_key_id = var.existing_kms_root_key_crn != null ? module.kms_root_key_crn_parser[0].resource : null
  # Determine the KMS root key ID value (new key or existing key)
  en_kms_key_id = local.existing_en_kms_root_key_id != null ? local.existing_en_kms_root_key_id : var.existing_en_instance_crn == null ? module.kms[0].keys[format("%s.%s", local.en_key_ring_name, local.en_key_name)].key_id : null
  # If existing KMS instance CRN passed, parse the region from it
  kms_region = var.existing_kms_instance_crn != null ? module.kms_instance_crn_parser[0].region : null
  # If existing KMS instance CRN passed, parse the GUID from it
  kms_instance_guid = var.existing_kms_instance_crn != null ? module.kms_instance_crn_parser[0].service_instance : null
  # If existing KMS instance CRN passed, parse the service name from it
  kms_service_name = var.existing_kms_instance_crn != null ? module.kms_instance_crn_parser[0].service_name : null
  # If existing KMS instance CRN passed, parse the account ID from it
  # TODO: update logic once CRN parser supports outputting account id (tracked in https://github.com/terraform-ibm-modules/terraform-ibm-common-utilities/issues/17)
  kms_account_id = var.existing_kms_instance_crn != null ? split("/", module.kms_instance_crn_parser[0].scope)[1] : null
  # Create cross account EN / KMS auth policy if not using existing EN instance, if 'skip_en_kms_auth_policy' is false, and a value is passed for 'ibmcloud_kms_api_key'
  create_cross_account_en_kms_auth_policy = var.existing_en_instance_crn == null && !var.skip_en_kms_auth_policy && var.ibmcloud_kms_api_key != null
  # Create cross account COS / KMS auth policy if not using existing EN instance, if not using existing bucket, if 'skip_cos_kms_auth_policy' is false, and if a value is passed for 'ibmcloud_kms_api_key'
  create_cross_account_cos_kms_auth_policy = var.existing_en_instance_crn == null && var.existing_cos_bucket_name == null && !var.skip_cos_kms_auth_policy && var.ibmcloud_kms_api_key != null
  # If a prefix value is passed, add it to the EN key name
  en_key_name = var.prefix != null ? "${var.prefix}-${var.en_key_name}" : var.en_key_name
  # If a prefix value is passed, add it to the EN key ring name
  en_key_ring_name = var.prefix != null ? "${var.prefix}-${var.en_key_ring_name}" : var.en_key_ring_name
  # If a prefix value is passed, add it to the COS key name
  cos_key_name = var.prefix != null ? "${var.prefix}-${var.cos_key_name}" : var.cos_key_name
  # If a prefix value is passed, add it to the COS key ring name
  cos_key_ring_name = var.prefix != null ? "${var.prefix}-${var.cos_key_ring_name}" : var.cos_key_ring_name
  # Determine the COS KMS key CRN (new key or existing key). It will only have a value if not using an existing bucket or existing EN instance
  cos_kms_key_crn = var.existing_en_instance_crn != null || var.existing_cos_bucket_name != null ? null : var.existing_kms_root_key_crn != null ? var.existing_kms_root_key_crn : module.kms[0].keys[format("%s.%s", local.cos_key_ring_name, local.cos_key_name)].crn
  # If existing KMS instance CRN passed, parse the key ID from it
  cos_kms_key_id = local.cos_kms_key_crn != null ? module.cos_kms_key_crn_parser[0].resource : null
  # Event Notifications KMS Key ring config
  en_kms_key = {
    key_ring_name     = local.en_key_ring_name
    existing_key_ring = false
    keys = [
      {
        key_name                 = local.en_key_name
        standard_key             = false
        rotation_interval_month  = 3
        dual_auth_delete_enabled = false
        force_delete             = true
      }
    ]
  }
  # Event Notifications COS bucket KMS Key ring config
  en_cos_kms_key = {
    key_ring_name     = local.cos_key_ring_name
    existing_key_ring = false
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
  # If not using existing EN instance or KMS key, create Key. Don't create a COS KMS key if using existing COS bucket.
  all_keys = local.create_kms_keys ? var.existing_cos_bucket_name != null ? [local.en_kms_key] : concat([local.en_kms_key], [local.en_cos_kms_key]) : []
}

# Create cross account IAM Authorization Policy to allow COS to read the KMS encryption key
resource "ibm_iam_authorization_policy" "cos_kms_policy" {
  count                       = local.create_cross_account_cos_kms_auth_policy ? 1 : 0
  provider                    = ibm.kms
  source_service_account      = local.cos_account_id
  source_service_name         = "cloud-object-storage"
  source_resource_instance_id = local.cos_instance_guid
  roles                       = ["Reader"]
  description                 = "Allow the COS instance ${local.cos_instance_guid} to read the ${local.kms_service_name} key ${local.cos_kms_key_id} from the instance ${local.kms_instance_guid}"
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
    value    = local.kms_instance_guid
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
  description                 = "Allow the EN instance with GUID ${module.event_notifications[0].guid} to read the ${local.kms_service_name} key ${local.cos_kms_key_id} from the instance ${local.kms_instance_guid}}"
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
    value    = local.kms_instance_guid
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

# Create KMS root keys
module "kms" {
  providers = {
    ibm = ibm.kms
  }
  count                       = local.create_kms_keys ? 1 : 0
  source                      = "terraform-ibm-modules/kms-all-inclusive/ibm"
  version                     = "4.19.1"
  create_key_protect_instance = false
  region                      = local.kms_region
  existing_kms_instance_crn   = var.existing_kms_instance_crn
  key_ring_endpoint_type      = var.kms_endpoint_type
  key_endpoint_type           = var.kms_endpoint_type
  keys                        = local.all_keys
}

#######################################################################################################################
# COS
#######################################################################################################################

# If existing COS intance CRN passed, parse details from it
module "cos_instance_crn_parser" {
  count   = var.existing_cos_instance_crn != null ? 1 : 0
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.1.0"
  crn     = var.existing_cos_instance_crn
}

locals {
  # Validate mutually exclusive inputs
  # tflint-ignore: terraform_unused_declarations
  validate_cos_regions = var.cos_bucket_region != null && var.cross_region_location != null ? tobool("Cannot provide values for 'cos_bucket_region' and 'cross_region_location'. Pick one or the other, or alternatively pass no values for either and allow it to default to the 'region' input.") : true

  # Validate cos inputs when using existing bucket
  # tflint-ignore: terraform_unused_declarations
  validate_cos_bucket = var.existing_cos_bucket_name != null && (var.existing_cos_instance_crn == null || var.existing_cos_endpoint == null) ? tobool("When passing a value for 'existing_cos_bucket_name', you must also pass values for 'existing_cos_instance_crn' and 'existing_cos_endpoint'.") : true

  # If a bucket name is passed, or an existing EN CRN is passed; do not create COS resources
  create_cos_bucket = var.existing_cos_bucket_name != null || var.existing_en_instance_crn != null ? false : true
  # determine COS details
  cos_bucket_name             = var.existing_cos_bucket_name != null ? var.existing_cos_bucket_name : local.create_cos_bucket ? (var.prefix != null ? "${var.prefix}-${var.cos_bucket_name}" : var.cos_bucket_name) : null
  cos_bucket_name_with_suffix = var.existing_cos_bucket_name != null ? var.existing_cos_bucket_name : local.create_cos_bucket ? module.cos[0].bucket_name : null
  cos_bucket_region           = var.cos_bucket_region != null ? var.cos_bucket_region : var.cross_region_location != null ? null : var.region
  cos_instance_name           = var.prefix != null ? "${var.prefix}-${var.cos_instance_name}" : var.cos_instance_name
  cos_endpoint                = var.existing_cos_bucket_name == null ? (local.create_cos_bucket ? "https://${module.cos[0].s3_endpoint_direct}" : null) : var.existing_cos_endpoint
  # If not using existing EN instance, and if existing COS instance CRN passed, parse the GUID from it, otherwise get GUID from COS module output
  cos_instance_guid = var.existing_en_instance_crn == null ? var.existing_cos_instance_crn == null ? module.cos[0].cos_instance_guid : module.cos_instance_crn_parser[0].service_instance : null
  # If not using existing EN instance, parse the COS account ID from the CRN
  # TODO: update logic once CRN parser supports outputting account id (tracked in https://github.com/terraform-ibm-modules/terraform-ibm-common-utilities/issues/17)
  cos_account_id = var.existing_en_instance_crn == null ? var.existing_cos_instance_crn != null ? split("/", module.cos_instance_crn_parser[0].scope)[1] : module.cos[0].cos_account_id : null
}

module "cos" {
  count                               = local.create_cos_bucket ? 1 : 0
  source                              = "terraform-ibm-modules/cos/ibm"
  version                             = "8.16.4"
  create_cos_instance                 = var.existing_cos_instance_crn == null ? true : false
  create_cos_bucket                   = local.create_cos_bucket
  existing_cos_instance_id            = var.existing_cos_instance_crn
  skip_iam_authorization_policy       = local.create_cross_account_en_kms_auth_policy || local.create_cross_account_cos_kms_auth_policy || var.skip_cos_kms_auth_policy
  add_bucket_name_suffix              = var.add_bucket_name_suffix
  resource_group_id                   = module.resource_group[0].resource_group_id
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
  archive_days                        = var.archive_days
}


########################################################################################################################
# Event Notifications
########################################################################################################################

# If existing EN intance CRN passed, parse details from it
module "existing_en_crn_parser" {
  count   = var.existing_en_instance_crn != null ? 1 : 0
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.1.0"
  crn     = var.existing_en_instance_crn
}

locals {
  # determine if existing EN instance being used
  use_existing_en_instance = var.existing_en_instance_crn != null
  # if using existing EN instance, parse the GUID from it
  existing_en_instance_guid = local.use_existing_en_instance ? module.existing_en_crn_parser[0].service_instance : null
  # determine the EN GUID
  eventnotification_guid = local.use_existing_en_instance ? local.existing_en_instance_guid : module.event_notifications[0].guid
  # determine the EN CRN
  eventnotification_crn = local.use_existing_en_instance ? var.existing_en_instance_crn : module.event_notifications[0].crn
}

# Lookup instance if using an existing one
data "ibm_resource_instance" "existing_en_instance" {
  count      = local.use_existing_en_instance ? 1 : 0
  identifier = local.existing_en_instance_guid
}

module "event_notifications" {
  count                    = local.use_existing_en_instance ? 0 : 1
  source                   = "../.."
  resource_group_id        = module.resource_group[0].resource_group_id
  region                   = var.region
  name                     = var.prefix != null ? "${var.prefix}-${var.event_notification_name}" : var.event_notification_name
  plan                     = var.service_plan
  tags                     = var.tags
  service_endpoints        = var.service_endpoints
  service_credential_names = var.service_credential_names
  # KMS Related
  kms_encryption_enabled    = true
  kms_endpoint_url          = var.kms_endpoint_url
  existing_kms_instance_crn = var.existing_kms_instance_crn
  root_key_id               = local.en_kms_key_id
  skip_en_kms_auth_policy   = local.create_cross_account_en_kms_auth_policy || local.create_cross_account_cos_kms_auth_policy || var.skip_en_kms_auth_policy
  # COS Related
  cos_integration_enabled = true
  cos_bucket_name         = local.cos_bucket_name_with_suffix
  cos_instance_id         = var.existing_cos_instance_crn != null ? var.existing_cos_instance_crn : module.cos[0].cos_instance_crn
  skip_en_cos_auth_policy = var.skip_en_cos_auth_policy
  cos_endpoint            = local.cos_endpoint
}

########################################################################################################################
# Service Credentials
########################################################################################################################

# If existing EN intance CRN passed, parse details from it
module "existing_sm_crn_parser" {
  count   = var.existing_secrets_manager_instance_crn != null ? 1 : 0
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.1.0"
  crn     = var.existing_secrets_manager_instance_crn
}

locals {
  # Validate that a value has been passed for 'existing_secrets_manager_instance_crn' if creating credentials using the 'service_credential_secrets' input
  # tflint-ignore: terraform_unused_declarations
  validate_sm_crn = length(var.service_credential_secrets) > 0 && var.existing_secrets_manager_instance_crn == null ? tobool("'existing_secrets_manager_instance_crn' is required when adding service credentials with the 'service_credential_secrets' input.") : false
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
          secret_name                             = secret.secret_name
          secret_labels                           = secret.secret_labels
          secret_auto_rotation                    = secret.secret_auto_rotation
          secret_auto_rotation_unit               = secret.secret_auto_rotation_unit
          secret_auto_rotation_interval           = secret.secret_auto_rotation_interval
          service_credentials_ttl                 = secret.service_credentials_ttl
          service_credential_secret_description   = secret.service_credential_secret_description
          service_credentials_source_service_role = secret.service_credentials_source_service_role
          service_credentials_source_service_crn  = local.eventnotification_crn
          secret_type                             = "service_credentials" #checkov:skip=CKV_SECRET_6
        }
      ]
    }
  ]
}

# create a service authorization between Secrets Manager and the target service (Event Notification)
resource "ibm_iam_authorization_policy" "secrets_manager_key_manager" {
  count                       = var.skip_en_sm_auth_policy || var.existing_secrets_manager_instance_crn == null ? 0 : 1
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
  version                     = "1.20.0"
  existing_sm_instance_guid   = local.existing_secrets_manager_instance_guid
  existing_sm_instance_region = local.existing_secrets_manager_instance_region
  endpoint_type               = var.existing_secrets_manager_endpoint_type
  secrets                     = local.service_credential_secrets
}
