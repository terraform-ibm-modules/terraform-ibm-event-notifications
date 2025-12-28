###########################################################
# This file creates an Event Notifications resource instance
###########################################################
locals {
  # tflint-ignore: terraform_unused_declarations
  validate_kms_values = !var.kms_encryption_enabled && (var.existing_kms_instance_crn != null || var.root_key_id != null || var.kms_endpoint_url != null) ? tobool("When passing values for var.existing_kms_instance_crn or/and var.root_key_id or/and var.kms_endpoint_url, you must set var.kms_encryption_enabled to true. Otherwise unset them to use default encryption") : true
  # tflint-ignore: terraform_unused_declarations
  validate_kms_vars = var.kms_encryption_enabled && (var.existing_kms_instance_crn == null || var.root_key_id == null || var.kms_endpoint_url == null) ? tobool("When setting var.kms_encryption_enabled to true, a value must be passed for var.existing_kms_instance_crn, var.root_key_id and var.kms_endpoint_url") : true
  # tflint-ignore: terraform_unused_declarations
  validate_cos_values = !var.cos_integration_enabled && (var.cos_instance_id != null || var.cos_bucket_name != null || var.cos_endpoint != null) ? tobool("When passing values for var.cos_instance_id or/and var.cos_bucket_name or/and var.cos_endpoint, you must set var.cos_integration_enabled to true. Otherwise unset them to disable collection of failed delivery events") : true
  # tflint-ignore: terraform_unused_declarations
  validate_cos_vars = var.cos_integration_enabled && (var.cos_instance_id == null || var.cos_bucket_name == null || var.cos_endpoint == null) ? tobool("When setting var.cos_integration_enabled to true, a value must be passed for var.cos_instance_id, var.cos_bucket_name and var.cos_endpoint") : true
  # Determine what KMS service is being used for encryption
  kms_service = var.existing_kms_instance_crn != null ? (
    can(regex(".*kms.*", var.existing_kms_instance_crn)) ? "kms" : (
      can(regex(".*hs-crypto.*", var.existing_kms_instance_crn)) ? "hs-crypto" : null
    )
  ) : null

  # Get account ID
  account_id = ibm_resource_instance.en_instance.account_id

  en_endpoints = { for key, value in ibm_resource_instance.en_instance.extensions : key => value
  }
}

resource "ibm_resource_instance" "en_instance" {
  plan              = var.plan
  location          = var.region
  name              = var.name
  resource_group_id = var.resource_group_id
  tags              = var.tags
  service           = "event-notifications"

  parameters = {
    service-endpoints = var.service_endpoints
  }
}

##############################################################################
# Attach Access Tags
##############################################################################

resource "ibm_resource_tag" "en_tag" {
  count       = length(var.access_tags) == 0 ? 0 : 1
  resource_id = ibm_resource_instance.en_instance.crn
  tags        = var.access_tags
  tag_type    = "access"
}

#############################################################################
# Event Notification COS integration to Collect Failed Events
#############################################################################
resource "ibm_en_integration_cos" "en_cos_integration" {
  depends_on    = [time_sleep.wait_for_cos_authorization_policy]
  count         = var.cos_integration_enabled ? 1 : 0
  instance_guid = ibm_resource_instance.en_instance.guid
  type          = "collect_failed_events"
  metadata {
    endpoint    = var.cos_endpoint
    crn         = var.cos_instance_id
    bucket_name = var.cos_bucket_name
  }
}

#############################################################################
# Event Notification KMS integration
#############################################################################

locals {

  en_integration_id = length(data.ibm_en_integrations.en_integrations) > 0 ? [
    for integrations in data.ibm_en_integrations.en_integrations[0].integrations :
    integrations.id if(integrations.type == "kms" || integrations.type == "hs-crypto")
  ] : null
}

data "ibm_en_integrations" "en_integrations" {
  count         = var.kms_encryption_enabled == false ? 0 : 1
  instance_guid = ibm_resource_instance.en_instance.guid
}

resource "ibm_en_integration" "en_kms_integration" {
  depends_on     = [time_sleep.wait_for_kms_authorization_policy]
  count          = var.kms_encryption_enabled == false ? 0 : 1
  instance_guid  = ibm_resource_instance.en_instance.guid
  integration_id = local.en_integration_id[0]
  type           = local.kms_service
  metadata {
    endpoint    = var.kms_endpoint_url
    crn         = var.existing_kms_instance_crn
    root_key_id = var.root_key_id
  }
}

##############################################################################
# IAM Authorization Policy
##############################################################################

locals {
  existing_kms_instance_guid = var.kms_encryption_enabled == true ? element(split(":", var.existing_kms_instance_crn), length(split(":", var.existing_kms_instance_crn)) - 3) : null
  existing_cos_instance_guid = var.cos_integration_enabled == true ? element(split(":", var.cos_instance_id), length(split(":", var.cos_instance_id)) - 3) : null
}

# Create IAM Authorization Policies to allow event notification to access cos
resource "ibm_iam_authorization_policy" "cos_policy" {
  count                       = var.cos_integration_enabled == false || var.skip_en_cos_auth_policy ? 0 : 1
  source_service_name         = "event-notifications"
  source_resource_instance_id = ibm_resource_instance.en_instance.guid
  roles                       = ["Object Writer", "Reader"]
  description                 = "Allow EN instance with GUID ${ibm_resource_instance.en_instance.guid} `Object Writer` and `Reader` access to the COS instance with GUID ${local.existing_cos_instance_guid}."
  resource_attributes {
    name     = "serviceName"
    operator = "stringEquals"
    value    = "cloud-object-storage"
  }
  resource_attributes {
    name     = "accountId"
    operator = "stringEquals"
    value    = local.account_id
  }
  resource_attributes {
    name     = "serviceInstance"
    operator = "stringEquals"
    value    = local.existing_cos_instance_guid
  }
  resource_attributes {
    name     = "resourceType"
    operator = "stringEquals"
    value    = "bucket"
  }
  resource_attributes {
    name     = "resource"
    operator = "stringEquals"
    value    = var.cos_bucket_name
  }
}

# workaround for https://github.com/IBM-Cloud/terraform-provider-ibm/issues/4478
resource "time_sleep" "wait_for_cos_authorization_policy" {
  depends_on = [ibm_iam_authorization_policy.cos_policy]

  create_duration = "30s"
}

# Create IAM Authorization Policies to allow event notification to access kms for the encryption key
resource "ibm_iam_authorization_policy" "kms_policy" {
  count                       = var.kms_encryption_enabled == false || var.skip_en_kms_auth_policy ? 0 : 1
  source_service_name         = "event-notifications"
  source_resource_instance_id = ibm_resource_instance.en_instance.guid
  roles                       = ["Reader"]
  description                 = "Allow Event Notifications instance ${ibm_resource_instance.en_instance.guid} to read the ${local.kms_service} key ${var.root_key_id} from instance ${local.existing_kms_instance_guid}"
  resource_attributes {
    name     = "serviceName"
    operator = "stringEquals"
    value    = local.kms_service
  }
  resource_attributes {
    name     = "accountId"
    operator = "stringEquals"
    value    = local.account_id
  }
  resource_attributes {
    name     = "serviceInstance"
    operator = "stringEquals"
    value    = local.existing_kms_instance_guid
  }
  resource_attributes {
    name     = "resourceType"
    operator = "stringEquals"
    value    = "key"
  }
  resource_attributes {
    name     = "resource"
    operator = "stringEquals"
    value    = var.root_key_id
  }
  # Scope of policy now includes the key, so ensure to create new policy before
  # destroying old one to prevent any disruption to every day services.
  lifecycle {
    create_before_destroy = true
  }
}

# workaround for https://github.com/IBM-Cloud/terraform-provider-ibm/issues/4478
resource "time_sleep" "wait_for_kms_authorization_policy" {
  depends_on = [ibm_iam_authorization_policy.kms_policy]

  create_duration = "30s"
}

##############################################################################
# Context Based Restrictions
##############################################################################
module "cbr_rule" {
  count            = length(var.cbr_rules) > 0 ? length(var.cbr_rules) : 0
  source           = "terraform-ibm-modules/cbr/ibm//modules/cbr-rule-module"
  version          = "1.35.4"
  rule_description = var.cbr_rules[count.index].description
  enforcement_mode = var.cbr_rules[count.index].enforcement_mode
  rule_contexts    = var.cbr_rules[count.index].rule_contexts
  resources = [{
    attributes = [
      {
        name     = "accountId"
        value    = var.cbr_rules[count.index].account_id
        operator = "stringEquals"
      },
      {
        name     = "serviceInstance"
        value    = ibm_resource_instance.en_instance.guid
        operator = "stringEquals"
      },
      {
        name     = "serviceName"
        value    = "event-notifications"
        operator = "stringEquals"
      }
    ]
  }]
}

resource "ibm_resource_key" "service_credentials" {
  for_each             = var.service_credential_names
  name                 = each.key
  role                 = each.value
  resource_instance_id = ibm_resource_instance.en_instance.id
}

locals {
  service_credentials_json = length(var.service_credential_names) > 0 ? {
    for service_credential in ibm_resource_key.service_credentials :
    service_credential["name"] => service_credential["credentials_json"]
  } : null

  service_credentials_object = length(var.service_credential_names) > 0 ? {
    credentials = {
      for service_credential in ibm_resource_key.service_credentials :
      service_credential["name"] => service_credential["credentials"]
    }
  } : null
}
