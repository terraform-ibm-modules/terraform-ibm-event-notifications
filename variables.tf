##############################################################################
# Input Variables
##############################################################################

variable "resource_group_id" {
  description = "The resource group ID where the Event Notification instance will be created."
  type        = string
}

variable "name" {
  type        = string
  description = "The name to give the IBM Event Notification instance created by this module."
}

variable "cos_destination_name" {
  type        = string
  description = "The name of the IBM Cloud Object Storage destination which will be created for the storage of failed delivery events."
  default     = "COS Destination"
}

variable "cos_bucket_name" {
  type        = string
  description = "The name of an existing IBM Cloud Object Storage bucket which will be used for storage of failed delivery events. Required if `cos_integration_enabled` is set to true."
  default     = null
}

variable "cos_instance_id" {
  type        = string
  description = "The ID of the IBM Cloud Object Storage instance in which the bucket that is defined in the `cos_bucket_name` variable exists. Required if `cos_integration_enabled` is set to true."
  default     = null
}

variable "cos_endpoint" {
  type        = string
  description = "The endpoint URL for your bucket region. For more information, see https://cloud.ibm.com/docs/cloud-object-storage?topic=cloud-object-storage-endpoints. Required if `cos_integration_enabled` is set to true."
  default     = null
}

variable "plan" {
  type        = string
  description = "The plan for the Event Notifications instance. Available values: `lite`, `standard`."
  default     = "standard"
  validation {
    condition     = contains(["lite", "standard"], var.plan)
    error_message = "The specified plan is not a valid selection! Supported plans are `lite` or `standard`"
  }
}

variable "tags" {
  type        = list(string)
  description = "The list of tags to add to the Event Notification instance."
  default     = []
}

variable "region" {
  type        = string
  description = "IBM Cloud region where event notification will be created, supported regions are: us-south (Dallas), eu-gb (London), eu-de (Frankfurt), au-syd (Sydney), eu-es (Madrid)"
  default     = "us-south"
  validation {
    condition     = contains(["us-south", "eu-gb", "eu-de", "au-syd", "eu-es", "eu-fr2"], var.region)
    error_message = "The specified region is not valid, supported regions are: us-south (Dallas), eu-gb (London), eu-de (Frankfurt), au-syd (Sydney), eu-es (Madrid), eu-fr2 (BNPP)"
  }
}
variable "kms_endpoint_url" {
  description = "The KMS endpoint URL to use when configuring KMS encryption. The URL format for Hyper Protect Crypto Services is https://api.private.<REGION>.hs-crypto.cloud.ibm.com:<port>. The URL format for Key Protect is https://<REGION>.kms.cloud.ibm.com. Required only if an existing key is not specified in `existing_kms_root_key_crn`."
  type        = string
  default     = null
}

variable "service_endpoints" {
  type        = string
  description = "Specify whether you want to enable the public or both public and private service endpoints. Available values: `public`, `public-and-private`."
  default     = "public-and-private"
  validation {
    condition     = contains(["public", "public-and-private"], var.service_endpoints)
    error_message = "The specified service endpoint is not a valid selection! Supported options are: public or public-and-private."
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
  description = "(Optional, list) List of CBR rules to create"
  default     = []
}

variable "skip_en_kms_auth_policy" {
  type        = bool
  description = "Whether an IAM authorization policy is created that permits all Event Notifications instances in the resource group to read the encryption key from the KMS instance. Set to `true` to use an existing policy. No policy is created if `kms_encryption_enabled` is set to `false`."
  default     = false
}

variable "kms_encryption_enabled" {
  type        = bool
  description = "Set this to true to control the encryption keys used to encrypt the data that you store in Event Notification. If set to false, the data is encrypted by using randomly generated keys. For more info on Managing Encryption, see https://cloud.ibm.com/docs/event-notifications?topic=event-notifications-en-managing-encryption"
  default     = false
}

variable "skip_en_cos_auth_policy" {
  type        = bool
  description = "Set to `true` to skip the creation of an IAM authorization policy that permits all Event Notifications instances in the resource group to interact with your Cloud Object Storage instance. No policy is created if `var.cos_integration_enabled` is set to false."
  default     = false
}

variable "cos_integration_enabled" {
  type        = bool
  description = "Set to `true` to connect a Cloud Object Storage service instance to your Event Notifications instance to collect events that failed delivery. If set to false, no failed events will be captured."
  default     = false
}

variable "existing_kms_instance_crn" {
  description = "The CRN of the Hyper Protect Crypto Services or Key Protect instance. Required only if var.kms_encryption_enabled is set to true."
  type        = string
  default     = null
}

variable "root_key_id" {
  type        = string
  description = "The Key ID of a root key, existing in the KMS instance passed in var.existing_kms_instance_crn, which will be used to encrypt the data encryption keys (DEKs) which are then used to encrypt the data. Required if var.kms_encryption_enabled is set to true."
  default     = null
}


variable "service_credential_names" {
  description = "Map of name, role for service credentials that you want to create for the event notification"
  type        = map(string)
  default     = {}

  validation {
    condition     = alltrue([for name, role in var.service_credential_names : contains(["Manager", "Writer", "Reader", "Event Source Manager", "Channel Editor", "Event Notification Publisher", "Status Reporter", "Device Manager", "Email Sender", "Custom Email Status Reporter"], role)])
    error_message = "Valid values for service credential roles are 'Manager', 'Writer', 'Reader', 'Event Source Manager', 'Channel Editor', 'Event Notification Publisher', 'Status Reporter', 'Device Manager', 'Email Sender', 'Custom Email Status Reporter'"
  }
}
