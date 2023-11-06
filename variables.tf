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

variable "plan" {
  type        = string
  description = "Plan for the event notification instance : lite or standard"
  default     = "standard"
  validation {
    condition     = contains(["lite", "standard"], var.plan)
    error_message = "The specified plan is not a valid selection! Supported plans are: lite or standard"
  }
}

variable "tags" {
  type        = list(string)
  description = "Optional list of tags to be added to the Event Notification instance"
  default     = []
}

variable "region" {
  type        = string
  description = "IBM Cloud region where event notification will be created, supported regions are: us-south (Dallas), eu-gb (London), eu-de (Frankfurt), au-syd (Sydney), eu-es (Madrid)"
  default     = "us-south"
  validation {
    condition     = contains(["us-south", "eu-gb", "eu-de", "au-syd"], var.region)
    error_message = "The specified region is not valid, supported regions are: us-south (Dallas), eu-gb (London), eu-de (Frankfurt), au-syd (Sydney), eu-es (Madrid)"
  }
}

variable "kms_region" {
  type        = string
  description = "The region where KMS instance exists if using KMS encryption."
  default     = "us-south"
}

variable "kms_endpoint" {
  description = "The KMS endpoint to use when configuring KMS encryption. Must be private or public."
  type        = string
  default     = "public"
  validation {
    condition     = contains(["public", "private"], var.kms_endpoint)
    error_message = "Valid values for kms_endpoint are 'public' or 'private'."
  }
}

variable "service_endpoints" {
  type        = string
  description = "Specify whether you want to enable the public or both public and private service endpoints. Supported values are 'public' or 'public-and-private'."
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

variable "skip_iam_authorization_policy" {
  type        = bool
  description = "Set to true to skip the creation of an IAM authorization policy that permits all Event Notification instances in the resource group to read the encryption key from the KMS instance."
  default     = false
}

variable "kms_encryption_enabled" {
  type        = bool
  description = "Set this to true to control the encryption keys used to encrypt the data that you store in Event Notification. If set to false, the data is encrypted by using randomly generated keys. For more info on Managing Encryption, see https://cloud.ibm.com/docs/event-notifications?topic=event-notifications-en-managing-encryption"
  default     = false
}

variable "existing_kms_instance_crn" {
  description = "The CRN of the Hyper Protect Crypto Services or Key Protect instance. Required only if var.kms_encryption_enabled is set to true and var.skip_iam_authorization_policy is set to false."
  type        = string
  default     = null
}

variable "root_key_id" {
  type        = string
  description = "The Key ID of a root key, existing in the KMS instance passed in var.existing_kms_instance_crn, which will be used to encrypt the data encryption keys (DEKs) which are then used to encrypt the data. Required if value passed for var.existing_kms_instance_crn. Only used if var.kms_encryption_enabled is set to true."
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
