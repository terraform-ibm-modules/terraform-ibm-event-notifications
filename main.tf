###########################################################
# This file creates an event notificaiton resource instance
###########################################################
locals {
  # tflint-ignore: terraform_unused_declarations
  validate_kms_plan = var.kms_encryption_enabled && var.plan != "standard" ? tobool("kms encryption is only supported for standard plan") : true
  # tflint-ignore: terraform_unused_declarations
  validate_kms_values = !var.kms_encryption_enabled && (var.existing_kms_instance_crn != null || var.root_key_id != null || var.kms_endpoint_url != null) ? tobool("When passing values for var.existing_kms_instance_crn or/and var.root_key_id or/and var.kms_endpoint_url, you must set var.kms_encryption_enabled to true. Otherwise unset them to use default encryption") : true
  # tflint-ignore: terraform_unused_declarations
  validate_kms_vars = var.kms_encryption_enabled && (var.existing_kms_instance_crn == null || var.root_key_id == null || var.kms_endpoint_url == null) ? tobool("When setting var.kms_encryption_enabled to true, a value must be passed for var.existing_kms_instance_crn, var.root_key_id and var.kms_endpoint_url") : true

  # Determine what KMS service is being used for encryption
  kms_service = var.existing_kms_instance_crn != null ? (
    can(regex(".*kms.*", var.existing_kms_instance_crn)) ? "kms" : (
      can(regex(".*hs-crypto.*", var.existing_kms_instance_crn)) ? "hs-crypto" : null
    )
  ) : null
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

#############################################################################
# Event Notification COS integration
#############################################################################

resource "ibm_en_destination_cos" "cos_en_destination" {
  depends_on            = [time_sleep.wait_for_cos_authorization_policy]
  count                 = var.cos_integration_enabled ? 1 : 0
  instance_guid         = ibm_resource_instance.en_instance.guid
  name                  = var.cos_destination_name
  type                  = "ibmcos"
  collect_failed_events = true
  description           = "IBM Cloud Object Storage destination for collection of failed events."
  config {
    params {
      bucket_name = var.cos_bucket_name
      instance_id = var.cos_instance_id
      endpoint    = var.cos_endpoint
    }
  }
}

#############################################################################
# Event Notification KMS integration
#############################################################################

locals {
  en_integration_id = length(data.ibm_en_integrations.en_integrations) > 0 ? data.ibm_en_integrations.en_integrations[0].integrations[0]["id"] : null
}

data "ibm_en_integrations" "en_integrations" {
  count         = var.kms_encryption_enabled == false ? 0 : 1
  instance_guid = ibm_resource_instance.en_instance.guid
}

resource "ibm_en_integration" "en_kms_integration" {
  depends_on     = [time_sleep.wait_for_kms_authorization_policy]
  count          = var.kms_encryption_enabled == false ? 0 : 1
  instance_guid  = ibm_resource_instance.en_instance.guid
  integration_id = local.en_integration_id
  type           = local.kms_service
  metadata {
    endpoint    = var.kms_endpoint_url
    crn         = var.existing_kms_instance_crn
    root_key_id = var.root_key_id
  }
}

##############################################################################
# Get Cloud Account ID
##############################################################################

data "ibm_iam_account_settings" "iam_account_settings" {
}

##############################################################################
# IAM Authorization Policy
##############################################################################

locals {
  existing_kms_instance_guid = var.kms_encryption_enabled == true ? element(split(":", var.existing_kms_instance_crn), length(split(":", var.existing_kms_instance_crn)) - 3) : null
}

# Create IAM Authorization Policies to allow event notification to access cos
resource "ibm_iam_authorization_policy" "cos_policy" {
  count                       = var.cos_integration_enabled == false || var.skip_en_cos_auth_policy ? 0 : 1
  source_service_name         = "event-notifications"
  source_resource_instance_id = ibm_resource_instance.en_instance.guid
  roles                       = ["Object Writer", "Reader"]
  description                 = "Allow EN instance with GUID ${ibm_resource_instance.en_instance.guid} `Object Writer` and `Reader` access to the COS instance with ID ${var.cos_instance_id}."

  resource_attributes {
    name     = "serviceName"
    operator = "stringEquals"
    value    = "cloud-object-storage"
  }

  resource_attributes {
    name     = "accountId"
    operator = "stringEquals"
    value    = data.ibm_iam_account_settings.iam_account_settings.account_id
  }
  resource_attributes {
    name     = "serviceInstance"
    operator = "stringEquals"
    value    = var.cos_instance_id
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
  target_service_name         = local.kms_service
  target_resource_instance_id = local.existing_kms_instance_guid
  roles                       = ["Reader"]
  description                 = "Allow Event Notification instance ${ibm_resource_instance.en_instance.guid} to read from the ${local.kms_service} instance ${local.existing_kms_instance_guid}"
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
  version          = "1.19.1"
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
