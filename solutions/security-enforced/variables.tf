########################################################################################################################
# Common variables
########################################################################################################################

variable "existing_resource_group_name" {
  type        = string
  description = "The name of an existing resource group to provision the resources."
  default     = "Default"
}

variable "ibmcloud_api_key" {
  type        = string
  description = "The API key to use for IBM Cloud."
  sensitive   = true
}

variable "region" {
  type        = string
  description = "The region in which the Event Notifications resources are provisioned. [Learn more](https://terraform-ibm-modules.github.io/documentation/#/region) about how to select different regions for different services."
  default     = "us-south"
}

variable "existing_monitoring_crn" {
  type        = string
  nullable    = true
  default     = null
  description = "The CRN of an IBM Cloud Monitoring instance used to monitor the IBM Cloud Object Storage bucket that is used for storing failed events. Only applicable if failed events are enabled using the `enable_collecting_failed_events` input. If no value passed, metrics are sent to the instance associated to the container's location unless otherwise specified in the Metrics Router service configuration."
}

variable "prefix" {
  type        = string
  description = "The prefix to be added to all resources created by this solution. To skip using a prefix, set this value to null or an empty string. The prefix must begin with a lowercase letter and may contain only lowercase letters, digits, and hyphens '-'. It should not exceed 16 characters, must not end with a hyphen('-'), and can not contain consecutive hyphens ('--'). Example: en-0435. [Learn more](https://terraform-ibm-modules.github.io/documentation/#/prefix)."
  validation {
    condition = var.prefix == null || var.prefix == "" ? true : alltrue([
      can(regex("^[a-z][-a-z0-9]*[a-z0-9]$", var.prefix)), length(regexall("--", var.prefix)) == 0
    ])
    error_message = "Prefix must begin with a lowercase letter and may contain only lowercase letters, digits, and hyphens '-'. It must not end with a hyphen('-'), and cannot contain consecutive hyphens ('--')."
  }

  validation {
    condition     = var.prefix == null || var.prefix == "" ? true : length(var.prefix) <= 16
    error_message = "Prefix must not exceed 16 characters."
  }
}

########################################################################################################################
# Event Notifications
########################################################################################################################

variable "service_credential_names" {
  type        = map(string)
  description = "A mapping of names and associated roles for service credentials that you want to create for the Event Notifications instance. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-event-notifications/blob/main/solutions/fully-configurable/DA-types.md#service-credentials-)."
  default     = {}

  validation {
    condition     = alltrue([for name, role in var.service_credential_names : contains(["Manager", "Writer", "Reader", "Event Source Manager", "Channel Editor", "Event Notification Publisher", "Status Reporter", "Device Manager", "Email Sender", "Custom Email Status Reporter"], role)])
    error_message = "The specified service credential role is not valid. The following values are valid for service credential roles: 'Manager', 'Writer', 'Reader', 'Event Source Manager', 'Channel Editor', 'Event Notification Publisher', 'Status Reporter', 'Device Manager', 'Email Sender', 'Custom Email Status Reporter'."
  }
}

variable "event_notifications_instance_name" {
  type        = string
  description = "The name of the Event Notifications instance that is created by this solution. If a `prefix` input variable is specified, it is added to this name in the `<prefix>-value` format."
  default     = "event-notifications"
}

variable "event_notifications_resource_tags" {
  type        = list(string)
  description = "The list of tags to add to the Event Notifications instance."
  default     = []
}

variable "existing_event_notifications_instance_crn" {
  type        = string
  description = "The CRN of existing Event Notifications instance. If not supplied, a new instance is created."
  default     = null
}

########################################################################################################################
# KMS
########################################################################################################################

variable "existing_kms_instance_crn" {
  type        = string
  description = "The CRN of the KMS instance (Hyper Protect Crypto Services or Key Protect instance). If the KMS instance is in different account you must also provide a value for `ibmcloud_kms_api_key`. To use an existing kms instance you must also provide a value for 'kms_endpoint_url' and 'existing_kms_root_key_crn' should be null. A value should not be passed passing existing EN instance using the `existing_event_notifications_instance_crn` input."
  default     = null

  validation {
    condition = anytrue([
      can(regex("^crn:(.*:){3}(kms|hs-crypto):(.*:){2}[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}::$", var.existing_kms_instance_crn)),
      var.existing_kms_instance_crn == null,
    ])
    error_message = "The provided KMS instance CRN in the input 'existing_kms_instance_crn' in not valid."
  }

  validation {
    condition     = var.existing_kms_instance_crn != null ? var.existing_event_notifications_instance_crn == null : true
    error_message = "A value should not be passed for 'existing_kms_instance_crn' when passing an existing EN instance using the 'existing_event_notifications_instance_crn' input."
  }
}

variable "kms_endpoint_url" {
  type        = string
  description = "The KMS endpoint URL to use when you configure KMS encryption. When set to true, a value must be passed for either `existing_kms_root_key_crn` or `existing_kms_instance_crn` (to create a new key). The Hyper Protect Crypto Services endpoint URL format is `https://api.private.<REGION>.hs-crypto.cloud.ibm.com:<port>` and the Key Protect endpoint URL format is `https://<REGION>.kms.cloud.ibm.com`. Not required if passing an existing instance using the `existing_event_notifications_instance_crn` input."
  default     = null

  validation {
    condition     = var.kms_endpoint_url != null ? var.existing_event_notifications_instance_crn == null : true
    error_message = "A value should not be passed for 'kms_endpoint_url' when passing an existing EN instance using the 'existing_event_notifications_instance_crn' input."
  }
}

variable "existing_kms_root_key_crn" {
  type        = string
  description = "The key CRN of a root key which will be used to encrypt the data. To use an existing key you must also provide a value for 'kms_endpoint_url' and 'existing_kms_instance_crn' should be null. If no value passed, a new key will be created in the instance provided in the `existing_kms_instance_crn` input."
  default     = null

  validation {
    condition     = var.existing_kms_root_key_crn != null ? var.existing_event_notifications_instance_crn == null : true
    error_message = "A value should not be passed for 'existing_kms_root_key_crn' when passing an existing EN instance using the 'existing_event_notifications_instance_crn' input."
  }

  validation {
    condition     = var.existing_kms_root_key_crn != null ? var.existing_kms_instance_crn == null : true
    error_message = "A value should not be passed for 'existing_kms_instance_crn' when passing an existing key value using the 'existing_kms_root_key_crn' input."
  }

  validation {
    condition     = var.existing_kms_root_key_crn == null ? var.existing_kms_instance_crn != null : true
    error_message = "A value must be passed for either 'existing_kms_instance_crn' (to create a new key) or 'existing_kms_root_key_crn' (to use existing key) to encrypt the COS bucket."
  }
}

variable "event_notifications_key_name" {
  type        = string
  default     = "event-notifications-key"
  description = "The name for the key that will be created for the Event Notifications instance. Not used if an existing key is specified. If a `prefix` input variable is specified, it is added to this name in the `<prefix>-value` format."
}

variable "cos_key_name" {
  type        = string
  default     = "event-notifications-cos-key"
  description = "The name of the key which will be created for the Event Notifications. Not used if supplying an existing key. If a `prefix` input variable is specified, it is added to this name in the `<prefix>-value` format."
}

variable "event_notifications_key_ring_name" {
  type        = string
  default     = "event-notifications-key-ring"
  description = "The name of the key ring which will be created for the Event Notifications instance. Not used if supplying an existing key. If a `prefix` input variable is specified, it is added to this name in the `<prefix>-value` format."
}

variable "skip_event_notifications_kms_auth_policy" {
  type        = bool
  description = "Set to true to skip the creation of an IAM authorization policy that permits the Event Notifications instance to read the encryption key from the KMS instance. If a value is specified for `ibmcloud_kms_api_key`, the policy is created in the KMS account."
  default     = false
}

variable "ibmcloud_kms_api_key" {
  type        = string
  description = "The IBM Cloud API key that can create a root key and key ring in the key management service (KMS) instance. If not specified, the 'ibmcloud_api_key' variable is used. Specify this key if the instance in `existing_kms_instance_crn` is in an account that's different from the Event Notifications instance. Leave this input empty if the same account owns both instances."
  sensitive   = true
  default     = null

  validation {
    condition     = var.ibmcloud_kms_api_key != null ? var.existing_event_notifications_instance_crn == null : true
    error_message = "A value should not be passed for 'ibmcloud_kms_api_key' when passing an existing EN instance using the 'existing_event_notifications_instance_crn' input."
  }
}

########################################################################################################################
# COS
########################################################################################################################

variable "existing_cos_instance_crn" {
  type        = string
  nullable    = true
  default     = null
  description = "The CRN of an IBM Cloud Object Storage instance. If not supplied, Cloud Object Storage will not be configured."
  validation {
    condition     = var.existing_cos_instance_crn == null ? var.existing_event_notifications_instance_crn != null : true
    error_message = "A value must be passed for 'existing_cos_instance_crn' when creating a new instance."
  }
}

variable "cos_bucket_name" {
  type        = string
  description = "The name to use when creating the Object Storage bucket for the storage of failed delivery events. Bucket names are globally unique. If `add_bucket_name_suffix` is set to `true`, a random 4 character string is added to this name to help ensure that the bucket name is unique. If a `prefix` input variable is specified, it is added to this name in the `<prefix>-value` format."
  default     = "base-event-notifications-bucket"
}

variable "add_bucket_name_suffix" {
  type        = bool
  description = "Whether to add a randomly generated 4-character suffix to the newly provisioned Object Storage bucket name. Set to `false` if you want full control over bucket naming by using the `cos_bucket_name` variable."
  default     = true
}

variable "cos_bucket_access_tags" {
  type        = list(string)
  description = "A list of access tags to apply to the Cloud Object Storage bucket created by the solution. For more information, [see here](https://cloud.ibm.com/docs/account?topic=account-access-tags-tutorial)."
  default     = []

  validation {
    condition = alltrue([
      for tag in var.cos_bucket_access_tags : can(regex("[\\w\\-_\\.]+:[\\w\\-_\\.]+", tag)) && length(tag) <= 128
    ])
    error_message = "Tags must match the regular expression \"[\\w\\-_\\.]+:[\\w\\-_\\.]+\", [learn more](https://cloud.ibm.com/docs/account?topic=account-tag&interface=ui#limits) for more details."
  }
}

variable "skip_event_notifications_cos_auth_policy" {
  type        = bool
  description = "Set to `true` to skip the creation of an IAM authorization policy that permits the Event Notifications instance `Object Writer` and `Reader` access to the given Object Storage bucket. Set to `true` to use an existing policy."
  default     = false
}

variable "skip_cos_kms_auth_policy" {
  type        = bool
  description = "Set to true to skip the creation of an IAM authorization policy that permits the COS instance to read the encryption key from the KMS instance. If set to false, pass in a value for the KMS instance in the `existing_key_management_service_instance_crn` variable. If a value is specified for `ibmcloud_kms_api_key`, the policy is created in the KMS account."
  default     = false
}

variable "cos_bucket_region" {
  type        = string
  description = "The COS bucket region. If `cos_bucket_region` is set to null, then `region` will be used."
  default     = null
}

##############################################################################
## Secrets Manager Service Credentials
##############################################################################

variable "existing_secrets_manager_instance_crn" {
  type        = string
  default     = null
  description = "The CRN of existing secrets manager to use to create service credential secrets for Event Notification instance."
}

variable "service_credential_secrets" {
  type = list(object({
    secret_group_name        = string
    secret_group_description = optional(string)
    existing_secret_group    = optional(bool)
    service_credentials = list(object({
      secret_name                                 = string
      service_credentials_source_service_role_crn = string
      secret_labels                               = optional(list(string))
      secret_auto_rotation                        = optional(bool)
      secret_auto_rotation_unit                   = optional(string)
      secret_auto_rotation_interval               = optional(number)
      service_credentials_ttl                     = optional(string)
      service_credential_secret_description       = optional(string)

    }))
  }))
  default     = []
  description = "Provided value of `service_credentials_source_service_role_crn` is not valid. Refer [this](https://cloud.ibm.com/iam/roles) for allowed role/values."

  validation {
    # Service roles CRNs can be found at https://cloud.ibm.com/iam/roles, select Event Notifications and select the role
    condition = alltrue([
      for group in var.service_credential_secrets : alltrue([
        # crn:v?:bluemix; two non-empty segments; three possibly empty segments; :serviceRole or role: non-empty segment
        for credential in group.service_credentials : can(regex("^crn:v[0-9]:bluemix(:..*){2}(:.*){3}:(serviceRole|role):..*$", credential.service_credentials_source_service_role_crn))
      ])
    ])
    error_message = "service_credentials_source_service_role_crn must be a serviceRole CRN. [Learn more](https://cloud.ibm.com/iam/roles)."
  }
}

variable "skip_event_notifications_secrets_manager_auth_policy" {
  type        = bool
  default     = false
  description = "Whether an IAM authorization policy is created for Secrets Manager instance to create a service credential secrets for Event Notification.If set to false, the Secrets Manager instance passed by the user is granted the Key Manager access to the Event Notifications instance created by the Deployable Architecture. Set to `true` to use an existing policy. The value of this is ignored if any value for 'existing_secrets_manager_instance_crn' is not passed."
}
variable "cbr_rules" {
  type = list(object({
    description = string
    account_id  = string
    rule_contexts = list(object({
      attributes = optional(list(object({
        name  = string
        value = string
    }))) }))
    enforcement_mode = string
    operations = optional(list(object({
      api_types = list(object({
        api_type_id = string
      }))
    })))
  }))
  description = "The list of context-based restrictions rules to create. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-event-notifications/tree/main/solutions/fully-configurable/DA-cbr_rules.md)."
  default     = []
}
