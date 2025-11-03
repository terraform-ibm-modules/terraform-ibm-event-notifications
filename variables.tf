##############################################################################
# Input Variables
##############################################################################

variable "resource_group_id" {
  description = "The ID of the resource group where the Event Notifications instance is created."
  type        = string
}

variable "name" {
  type        = string
  description = "The name of the Event Notifications instance that is created by this module."
}

variable "cos_bucket_name" {
  type        = string
  description = "The name of an existing IBM Cloud Object Storage bucket to use for storing failed delivery events. Required if `cos_integration_enabled` is set to `true`."
  default     = null
}

variable "cos_instance_id" {
  type        = string
  description = "The ID of an existing IBM Cloud Object Storage instance that contains the bucket to use for storing failed delivery events. Required if `cos_integration_enabled` is set to `true`."
  default     = null
}

variable "cos_endpoint" {
  type        = string
  description = "The endpoint URL for your bucket region. Required if `cos_integration_enabled` is set to `true`. [Learn more](https://cloud.ibm.com/docs/cloud-object-storage?topic=cloud-object-storage-endpoints)."
  default     = null
}

variable "plan" {
  type        = string
  description = "The pricing plan of the Event Notifications instance. Possible values are `Lite` or `Standard`."
  default     = "standard"
  validation {
    condition     = contains(["lite", "standard"], var.plan)
    error_message = "The specified pricing plan is not available. `Lite` or `Standard` plans are supported."
  }
}

variable "tags" {
  type        = list(string)
  description = "The list of tags to add to the Event Notifications instance."
  default     = []
}

variable "access_tags" {
  type        = list(string)
  description = "A list of access tags to apply to the Event Notifications instance created by the module. [Learn more](https://cloud.ibm.com/docs/account?topic=account-access-tags-tutorial)."
  default     = []

  validation {
    condition = alltrue([
      for tag in var.access_tags : can(regex("[\\w\\-_\\.]+:[\\w\\-_\\.]+", tag)) && length(tag) <= 128
    ])
    error_message = "Tags must match the regular expression `\"[\\w\\-_\\.]+:[\\w\\-_\\.]+\"`. [Learn more](https://cloud.ibm.com/docs/account?topic=account-tag&interface=ui#limits)."
  }
}

variable "region" {
  type        = string
  description = "The IBM Cloud region where the Event Notifications instance is created. Possible values are `jp-osa` (Osaka), `au-syd` (Sydney), `jp-tok` (Tokyo), `eu-de` (Frankfurt), `eu-gb` (London), `eu-es` (Madrid), `eu-fr2` (EU), `us-south` (Dallas), `ca-tor` (Toronto), or `br-sao` (Sao Paulo)."
  default     = "us-south"
  validation {
    condition     = contains(["jp-osa", "au-syd", "jp-tok", "eu-de", "eu-gb", "eu-es", "eu-fr2", "us-south", "ca-tor", "br-sao", "ca-mon"], var.region)
    error_message = "The specified region is not supported. The following regions are supported: `jp-osa` (Osaka), `au-syd` (Sydney), `jp-tok` (Tokyo), `eu-de` (Frankfurt), `eu-gb` (London), `eu-es` (Madrid), `eu-fr2` (EU), `us-south` (Dallas), `ca-tor` (Toronto), or `br-sao` (Sao Paulo)."
  }
}

variable "kms_endpoint_url" {
  description = "The URL of the key management service endpoint to use for key encryption. For more information on the endpoint URL format for Hyper Protect Crypto Services, go to [Instance-based endpoints](https://cloud.ibm.com/docs/hs-crypto?topic=hs-crypto-regions#new-service-endpoints). For more information on the endpoint URL format for Key Protect, go to [Service endpoints](https://cloud.ibm.com/docs/key-protect?topic=key-protect-regions#service-endpoints)."
  type        = string
  default     = null
}

variable "service_endpoints" {
  type        = string
  description = "Specify whether you want to enable public, private, or both public and private service endpoints. Possible values are `public`, `private`, or `public-and-private`."
  default     = "private"
  validation {
    condition     = contains(["public", "private", "public-and-private"], var.service_endpoints)
    error_message = "The specified service endpoint is not supported. The following endpoint options are supported: `public`, `private`, or `public-and-private`."
  }
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
  description = "The context-based restrictions rule to create. Only one rule is allowed."
  default     = []
  validation {
    condition     = length(var.cbr_rules) <= 1
    error_message = "Only one CBR rule is allowed."
  }
}

variable "skip_en_kms_auth_policy" {
  type        = bool
  description = "Set to `true` to skip the creation of an IAM authorization policy that permits the Event Notifications instance to read the encryption key from the key management service instance. If set to `false`, a value must be passed for the key management service instance and key using inputs `existing_kms_instance_crn` and `root_key_id`. In addition, no policy is created if `kms_encryption_enabled` is set to `false`."
  default     = false
}

variable "kms_encryption_enabled" {
  type        = bool
  description = "Set to `true` to control the encryption keys that are used to encrypt the data that you store in the Event Notifications instance. If set to `false`, the data is encrypted by using randomly generated keys. For more information, see [Managing encryption](https://cloud.ibm.com/docs/event-notifications?topic=event-notifications-en-managing-encryption)."
  default     = false
  validation {
    condition     = var.kms_encryption_enabled == false || var.plan == "standard"
    error_message = "key encryption is only supported for the standard plan"
  }
}

variable "skip_en_cos_auth_policy" {
  type        = bool
  description = "Set to `true` to skip creating an IAM authorization policy that permits the Event Notifications instance `Object Writer` and `Reader` access to the given Object Storage bucket. Ignored if `cos_integration_enabled` is set to `false`."
  default     = false
}

variable "cos_integration_enabled" {
  type        = bool
  description = "Set to `true` to connect an Object Storage service instance to your Event Notifications instance to collect events that failed delivery. If set to false, no failed events are captured."
  default     = false
}

variable "existing_kms_instance_crn" {
  description = "The CRN of the Hyper Protect Crypto Services or Key Protect instance. Required only if `var.kms_encryption_enabled` is set to `true`."
  type        = string
  default     = null
}

variable "root_key_id" {
  type        = string
  description = "The key ID of a root key, existing in the key management service instance passed in `var.existing_kms_instance_crn`, which is used to encrypt the data encryption keys which are then used to encrypt the data. Required only if `var.kms_encryption_enabled` is set to `true`."
  default     = null
}


variable "service_credential_names" {
  description = "The mapping of names and roles for service credentials to create for the Event Notifications instance."
  type        = map(string)
  default     = {}

  validation {
    condition     = alltrue([for name, role in var.service_credential_names : contains(["Manager", "Writer", "Reader", "Event Source Manager", "Channel Editor", "Event Notification Publisher", "Status Reporter", "Device Manager", "Email Sender", "Custom Email Status Reporter"], role)])
    error_message = "The specified service credential role is not valid. The following values are valid for service credential roles: 'Manager', 'Writer', 'Reader', 'Event Source Manager', 'Channel Editor', 'Event Notification Publisher', 'Status Reporter', 'Device Manager', 'Email Sender', or 'Custom Email Status Reporter'"
  }
}
