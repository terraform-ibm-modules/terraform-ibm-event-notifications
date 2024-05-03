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

variable "plan" {
  type        = string
  description = "The pricing plan of the Event Notifications instance. Possible values: `Lite`, `Standard`"
  default     = "standard"
  validation {
    condition     = contains(["lite", "standard"], var.plan)
    error_message = "The specified pricing plan is not available. The following plans are supported: `Lite`, `Standard`"
  }
}

variable "tags" {
  type        = list(string)
  description = "The list of tags to add to the Event Notifications instance."
  default     = []
}

variable "region" {
  type        = string
  description = "The IBM Cloud region where the Event Notifications resource is created. Possible values: `us-south` (Dallas), `eu-gb` (London), `eu-de` (Frankfurt), `au-syd` (Sydney), `eu-es` (Madrid)"
  default     = "us-south"
  validation {
    condition     = contains(["us-south", "eu-gb", "eu-de", "au-syd", "eu-es", "eu-fr2"], var.region)
    error_message = "The specified region is not supported. The following regions are supported: `us-south` (Dallas), `eu-gb` (London), `eu-de` (Frankfurt), `au-syd` (Sydney), `eu-es` (Madrid), `eu-fr2` (BNPP)"
  }
}
variable "kms_endpoint_url" {
  description = "The URL of the KMS endpoint to use when configuring KMS encryption. The Hyper Protect Crypto Services endpoint URL format is `https://api.private.<REGION>.hs-crypto.cloud.ibm.com:<port>` and the Key Protect endpoint URL format is `https://<REGION>.kms.cloud.ibm.com`."
  type        = string
  default     = null
}

variable "service_endpoints" {
  type        = string
  description = "Specify whether you want to enable public, or both public and private service endpoints. Possible values: `public`, `public-and-private`"
  default     = "public-and-private"
  validation {
    condition     = contains(["public", "public-and-private"], var.service_endpoints)
    error_message = "The specified service endpoint is not supported. The following endpoint options are supported: `public`, `public-and-private`"
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
  }))
  description = "The list of context-based restrictions rules to create."
  default     = []
}

variable "skip_iam_authorization_policy" {
  type        = bool
  description = "Set to `true` to skip the creation of an IAM authorization policy that permits all Event Notifications instances in the resource group to read the encryption key from the KMS instance. If set to `false`, specify a value for the KMS instance in the `existing_kms_instance_guid` variable. In addition, no policy is created if `kms_encryption_enabled` is set to `false`."
  default     = false.
}

variable "kms_encryption_enabled" {
  type        = bool
  description = "Set to `true` to control the encryption keys that are used to encrypt the data that you store in the Event Notifications instance. If set to `false`, the data is encrypted by using randomly generated keys. For more information, see [Managing encryption](https://cloud.ibm.com/docs/event-notifications?topic=event-notifications-en-managing-encryption)."
  default     = false
}

variable "existing_kms_instance_crn" {
  description = "The CRN of the Hyper Protect Crypto Services or Key Protect instance. Required only if `var.kms_encryption_enabled` is set to `true`."
  type        = string
  default     = null
}

variable "root_key_id" {
  type        = string
  description = "The key ID of a root key, existing in the KMS instance passed in `var.existing_kms_instance_crn`, which will be used to encrypt the data encryption keys which are then used to encrypt the data. Required only if `var.kms_encryption_enabled` is set to `true`."
  default     = null
}


variable "service_credential_names" {
  description = "The mapping of names and roles for service credentials that you want to create for the Event Notifications instance."
  type        = map(string)
  default     = {}

  validation {
    condition     = alltrue([for name, role in var.service_credential_names : contains(["Manager", "Writer", "Reader", "Event Source Manager", "Channel Editor", "Event Notification Publisher", "Status Reporter", "Device Manager", "Email Sender", "Custom Email Status Reporter"], role)])
    error_message = "The specified service credential role is not valid. The following values are valid for service credential roles: 'Manager', 'Writer', 'Reader', 'Event Source Manager', 'Channel Editor', 'Event Notification Publisher', 'Status Reporter', 'Device Manager', 'Email Sender', 'Custom Email Status Reporter'"
  }
}
