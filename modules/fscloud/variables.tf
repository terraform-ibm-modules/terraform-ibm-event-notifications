##############################################################################
# Input Variables
##############################################################################

variable "resource_group_id" {
  description = "ID of resource group to use when creating the event stream instance"
  type        = string
}

variable "name" {
  type        = string
  description = "The name to give the IBM Event Notification instance created by this module."
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
}

variable "kms_region" {
  type        = string
  description = "The region where KMS instance exists if using KMS encryption."
  default     = "us-south"
}

variable "skip_iam_authorization_policy" {
  type        = bool
  description = "Set to true to skip the creation of an IAM authorization policy that permits all event notification instances in the provided resource group reader access to the instance specified in the existing_kms_instance_guid variable."
  default     = false
}

variable "existing_kms_instance_crn" {
  description = "The CRN of the Hyper Protect Crypto Services or Key Protect instance. Required only if var.kms_encryption_enabled is set to true. To ensure compliance with FSCloud standards, it is required to use HPCS only."
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
  description = "(Optional, list) List of CBR rules to create."
  default     = []
}
