########################################################################################################################
# Common variables
########################################################################################################################

variable "ibmcloud_api_key" {
  type        = string
  description = "The API key to use for IBM Cloud."
  sensitive   = true
}

variable "existing_resource_group_name" {
  type        = string
  description = "The name of an existing resource group in which to provision the Databases for Elasticsearch in."
  default     = "Default"
  nullable    = false
}

variable "region" {
  type        = string
  description = "The region in which the Event Notifications resources are provisioned."
  default     = "us-south"
  nullable    = false
}

variable "prefix" {
  type        = string
  description = "(Optional) Prefix to add to all resources created by this solution. To not use any prefix value, you can set this value to `null` or an empty string."
  nullable    = true
  validation {
    condition = (var.prefix == null ? true :
      alltrue([
        can(regex("^[a-z]{0,1}[-a-z0-9]{0,14}[a-z0-9]{0,1}$", var.prefix)),
        length(regexall("^.*--.*", var.prefix)) == 0
      ])
    )
    error_message = "Prefix must begin with a lowercase letter, contain only lowercase letters, numbers, and - characters. Prefixes must end with a lowercase letter or number and be 16 or fewer characters."
  }
}

########################################################################################################################
# Event Notifications
########################################################################################################################

variable "service_credential_names" {
  type        = map(string)
  description = "The mapping of names and roles for service credentials that you want to create for the Event Notifications instance. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-event-notifications/tree/main/solutions/fully-configurable/DA-types.md#service-credential-secrets"
  default     = {}

  validation {
    condition     = alltrue([for name, role in var.service_credential_names : contains(["Manager", "Writer", "Reader", "Event Source Manager", "Channel Editor", "Event Notification Publisher", "Status Reporter", "Device Manager", "Email Sender", "Custom Email Status Reporter"], role)])
    error_message = "The specified service credential role is not valid. The following values are valid for service credential roles: 'Manager', 'Writer', 'Reader', 'Event Source Manager', 'Channel Editor', 'Event Notification Publisher', 'Status Reporter', 'Device Manager', 'Email Sender', 'Custom Email Status Reporter'"
  }
}

variable "event_notifications_name" {
  type        = string
  description = "The name of the Event Notifications instance that is created by this solution. If a `prefix` input variable is specified, it is added to this name in the `<prefix>-value` format."
  default     = "base-event-notifications"
}

variable "service_plan" {
  type        = string
  description = "The pricing plan of the Event Notifications instance. Possible values: `Lite`, `Standard`"
  default     = "standard"
  validation {
    condition     = contains(["lite", "standard"], var.service_plan)
    error_message = "The specified pricing plan is not available. The following plans are supported: `Lite`, `Standard`"
  }

}

variable "event_notifications_resource_tags" {
  type        = list(string)
  description = "The list of tags to add to the Event Notifications instance."
  default     = []
}

variable "event_notifications_access_tags" {
  type        = list(string)
  description = "A list of access tags to apply to the Event Notifications instance created by the module. For more information, see https://cloud.ibm.com/docs/account?topic=account-access-tags-tutorial."
  default     = []

  validation {
    condition = alltrue([
      for tag in var.event_notifications_access_tags : can(regex("[\\w\\-_\\.]+:[\\w\\-_\\.]+", tag)) && length(tag) <= 128
    ])
    error_message = "Tags must match the regular expression \"[\\w\\-_\\.]+:[\\w\\-_\\.]+\", see https://cloud.ibm.com/docs/account?topic=account-tag&interface=ui#limits for more details"
  }
}

variable "existing_event_notifications_instance_crn" {
  type        = string
  description = "The CRN of existing event notification instance. If not supplied, a new instance is created."
  default     = null
}

########################################################################################################################
# KMS
########################################################################################################################

variable "existing_kms_instance_crn" {
  type        = string
  description = "The CRN of the KMS instance (Hyper Protect Crypto Services or Key Protect instance). If the KMS instance is in different account you must also provide a value for `ibmcloud_kms_api_key`."
  default     = null
}

variable "existing_kms_root_key_crn" {
  type        = string
  description = "The key CRN of a root key, existing in the KMS instance passed in the `existing_kms_instance_crn` input, which will be used to encrypt the data. If no value passed, a new key will be created in the instance provided in the `existing_kms_instance_crn` input."
  default     = null
}

variable "kms_endpoint_url" {
  type        = string
  description = "The KMS endpoint URL to use when you configure KMS encryption. The Hyper Protect Crypto Services endpoint URL format is `https://api.private.<REGION>.hs-crypto.cloud.ibm.com:<port>` and the Key Protect endpoint URL format is `https://<REGION>.kms.cloud.ibm.com`. Not required if passing an existing instance using the `existing_en_instance_crn` input."
  default     = null
}

variable "event_notifications_key_ring_name" {
  type        = string
  default     = "en-key-ring"
  description = "The name of the key ring which will be created for the Event Notifications instance. Not used if supplying an existing key. If a `prefix` input variable is specified, it is added to this name in the `<prefix>-value` format."
}

variable "event_notifications_key_name" {
  type        = string
  default     = "en-key"
  description = "The name for the key that will be created for the Event Notifications. Not used if an existing key is specfied. If a `prefix` input variable is specified, it is added to this name in the `<prefix>-value` format."
}

variable "cos_key_ring_name" {
  type        = string
  default     = "en-cos-key-ring"
  description = "The name of the key ring which will be created for Object Storage. Not used if supplying an existing key or if `existing_cos_bucket_name` is specified. If a `prefix` input variable is specified, it is added to this name in the `<prefix>-value` format."
}

variable "cos_key_name" {
  type        = string
  default     = "en-cos-key"
  description = "The name of the key which will be created for the Event Notifications. Not used if supplying an existing key. If a `prefix` input variable is specified, it is added to this name in the `<prefix>-value` format."
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
}

########################################################################################################################
# COS
########################################################################################################################

variable "existing_cos_instance_crn" {
  type        = string
  nullable    = false
  description = "The CRN of an IBM Cloud Object Storage instance."
}

variable "cos_bucket_name" {
  type        = string
  description = "The name to use when creating the Object Storage bucket for the storage of failed delivery events. Bucket names are globally unique. If `add_bucket_name_suffix` is set to `true`, a random 4 character string is added to this name to help ensure that the bucket name is unique. If a `prefix` input variable is specified, it is added to this name in the `<prefix>-value` format."
  default     = "base-event-notifications-bucket"
}

variable "skip_event_notifications_cos_auth_policy" {
  type        = bool
  description = "Set to `true` to skip the creation of an IAM authorization policy that permits the Event Notifications instance `Object Writer` and `Reader` access to the given Object Storage bucket. Set to `true` to use an existing policy."
  default     = false
}

variable "skip_cos_kms_auth_policy" {
  type        = bool
  description = "Set to true to skip the creation of an IAM authorization policy that permits the COS instance to read the encryption key from the KMS instance. If set to false, pass in a value for the KMS instance in the `existing_kms_instance_crn` variable. If a value is specified for `ibmcloud_kms_api_key`, the policy is created in the KMS account."
  default     = false
}

variable "cos_bucket_access_tags" {
  type        = list(string)
  description = "A list of access tags to apply to the Cloud Object Storage bucket created by the module. For more information, see https://cloud.ibm.com/docs/account?topic=account-access-tags-tutorial."
  default     = []

  validation {
    condition = alltrue([
      for tag in var.cos_bucket_access_tags : can(regex("[\\w\\-_\\.]+:[\\w\\-_\\.]+", tag)) && length(tag) <= 128
    ])
    error_message = "Tags must match the regular expression \"[\\w\\-_\\.]+:[\\w\\-_\\.]+\", see https://cloud.ibm.com/docs/account?topic=account-tag&interface=ui#limits for more details"
  }
}

variable "add_bucket_name_suffix" {
  type        = bool
  description = "Whether to add a randomly generated 4-character suffix to the newly provisioned Object Storage bucket name. Used only if not using an existing bucket. Set to `false` if you want full control over bucket naming by using the `cos_bucket_name` variable."
  default     = true
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
  description = "Service credential secrets configuration for Event Notification. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-event-notifications/tree/main/solutions/fully-configurable/DA-types.md#service-credential-secrets)."

  validation {
    # Service roles CRNs can be found at https://cloud.ibm.com/iam/roles, select Event Notifications and select the role
    condition = alltrue([
      for group in var.service_credential_secrets : alltrue([
        # crn:v?:bluemix; two non-empty segments; three possibly empty segments; :serviceRole or role: non-empty segment
        for credential in group.service_credentials : can(regex("^crn:v[0-9]:bluemix(:..*){2}(:.*){3}:(serviceRole|role):..*$", credential.service_credentials_source_service_role_crn))
      ])
    ])
    error_message = "service_credentials_source_service_role_crn must be a serviceRole CRN. See https://cloud.ibm.com/iam/roles"
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
  description = "The list of context-based restrictions rules to create.  [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-event-notifications/tree/main/solutions/fully-configurable/DA-cbr_rules.md)"
  default     = []
}
