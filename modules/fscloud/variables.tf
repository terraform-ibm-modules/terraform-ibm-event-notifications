##############################################################################
# Input Variables
##############################################################################

variable "resource_group_id" {
  description = "The resource group ID to use when creating the Event Streams instance."
  type        = string
}

variable "name" {
  type        = string
  description = "The name of the Event Notifications instance that is created by this module."
}

variable "tags" {
  type        = list(string)
  description = "The optional list of tags to add to the Event Notifications instance."
  default     = []
}

variable "region" {
  type        = string
  description = "The IBM Cloud region where the Event Notifications resource is created. The following regions are supported: `us-south` (Dallas), `eu-gb` (London), `eu-de` (Frankfurt), `au-syd` (Sydney), `eu-es` (Madrid)"
  default     = "us-south"
}

variable "skip_iam_authorization_policy" {
  type        = bool
  description = "Set this variable value to `true` to skip the creation of an IAM authorization policy that permits all Event Notifications instances in the resource group reader access to the instance specified in the `existing_kms_instance_guid` variable."
  default     = false
}

variable "existing_kms_instance_crn" {
  description = "The Cloud Resource Name (CRN) of the Hyper Protect Crypto Services (HPCS) or Key Protect instance. To ensure compliance with IBM Cloud Framework for Financial Services (FS Cloud) standards, it is required to use HPCS only."
  type        = string
}

variable "root_key_id" {
  type        = string
  description = "The key ID of a root key, existing in the key management service (KMS) instance passed in `var.existing_kms_instance_crn`, which will be used to encrypt the data encryption keys (DEKs) which are then used to encrypt the data."
}

variable "kms_endpoint_url" {
  description = "The key management service (KMS) endpoint URL to use when you configure KMS encryption."
  type        = string
}

variable "service_credential_names" {
  description = "The mapping of names and roles for service credentials that you want to create for the Event Notifications instance."
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
  description = "The optional list of context-based restrictions (CBR) rules to create."
  default     = []
}
