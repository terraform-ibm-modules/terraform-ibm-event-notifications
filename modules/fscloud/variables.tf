##############################################################################
# Input Variables
##############################################################################

variable "resource_group_id" {
  description = "The ID of the resource group to use when creating the event stream instance."
  type        = string
}

variable "name" {
  type        = string
  description = "The name to give the IBM Event Notification instance created by this module."
}

variable "tags" {
  type        = list(string)
  description = "Optional list of tags to add to the Event Notification instance."
  default     = []
}

variable "region" {
  type        = string
  description = "The IBM Cloud region where the Event Notification instance is created. The supported regions are, `us-south` (Dallas), `eu-gb` (London), `eu-de` (Frankfurt), `au-syd` (Sydney), and `eu-es` (Madrid)."
  default     = "us-south"
}

variable "skip_en_kms_auth_policy" {
  type        = bool
  description = "Whether an IAM authorization policy is created that permits all Event Notifications instances in the resource group to read the encryption key from the KMS instance. Set to `true` to use an existing policy."
  default     = false
}

variable "existing_kms_instance_crn" {
  description = "The CRN of the Hyper Protect Crypto Services or Key Protect instance. Use HPCS to ensure compliance with the IBM Cloud Framework for Financial Services."
  type        = string
}

variable "root_key_id" {
  type        = string
  description = "The key ID of a root key that exists in the KMS instance that is specified in `existing_kms_instance_crn`. The key is used to encrypt the data encryption keys, which are then used to encrypt the data. The code creates the key if one is not passed in."
}

variable "kms_endpoint_url" {
  description = "The KMS endpoint URL to use when configuring KMS encryption."
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
  description = "(Optional, list) List of CBR rules to create."
  default     = []
}

########################################################################################################################
# COS
########################################################################################################################

variable "cos_destination_name" {
  type        = string
  description = "The name of the IBM Cloud Object Storage destination which will be created for the storage of failed delivery events."
  default     = "COS Destination"
}

variable "cos_bucket_name" {
  type        = string
  description = "The name of an existing Object Storage bucket to use for the storage of failed delivery events."
  default     = null
}

variable "cos_instance_id" {
  type        = string
  description = "The ID of the Object Storage instance that contains the bucket that is specified in the `cos_bucket_name` variable. Required only if `cos_integration_enabled` is set to `true`."
  default     = null
}

variable "skip_en_cos_auth_policy" {
  type        = bool
  description = "Whether an IAM authorization policy is created that permits all Event Notifications instances in the resource group to interact with your Object Storage instance. Set to `true` to use an existing policy. Ignored if `cos_integration_enabled` is set to `false`."
  default     = false
}

variable "cos_integration_enabled" {
  type        = bool
  description = "Whether to connect an Object Storage service instance to your Event Notifications instance to collect events that fail delivery. If set to `false`, no failed events are captured."
  default     = true
}

variable "cos_endpoint" {
  type        = string
  description = "The endpoint URL for your bucket region. Required if `cos_integration_enabled` is set to `true`. [Learn more](https://cloud.ibm.com/docs/cloud-object-storage?topic=cloud-object-storage-endpoints)."
  default     = null
}
