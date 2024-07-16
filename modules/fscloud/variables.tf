##############################################################################
# Input Variables
##############################################################################

variable "resource_group_id" {
  description = "The resource group ID to use when creating the Event Notifications instance."
  type        = string
}

variable "name" {
  type        = string
  description = "The name of the Event Notifications instance that is created by this module."
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
}

variable "skip_en_kms_auth_policy" {
  type        = bool
  description = "Set to `true` to skip the creation of an IAM authorization policy that permits all Event Notifications instances in the resource group reader access to the instance specified in the `existing_kms_instance_guid` variable."
  default     = false
}

variable "existing_kms_instance_crn" {
  description = "The CRN of the Hyper Protect Crypto Services or Key Protect instance. To ensure compliance with IBM Cloud Framework for Financial Services standards, it is required to use Hyper Protect Crypto Services only."
  type        = string
}

variable "root_key_id" {
  type        = string
  description = "The key ID of a root key, existing in the KMS instance passed in `var.existing_kms_instance_crn`, which will be used to encrypt the data encryption keys which are then used to encrypt the data."
}

variable "kms_endpoint_url" {
  description = "The KMS endpoint URL to use when you configure KMS encryption."
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
  description = "The list of context-based restrictions rules to create."
  default     = []
}

########################################################################################################################
# COS
########################################################################################################################

variable "cos_bucket_name" {
  type        = string
  description = "The name of an existing Object Storage bucket to use for the storage of failed delivery events."
  default     = null
}

variable "cos_instance_id" {
  type        = string
  description = "The ID of the IBM Cloud Object Storage instance in which the bucket that is defined in the `cos_bucket_name` variable exists. Required if `cos_integration_enabled` is set to true."
  default     = null
}

variable "skip_en_cos_auth_policy" {
  type        = bool
  description = "Whether an IAM authorization policy is created for your Event Notifications instance to interact with your Object Storage bucket. Set to `true` to use an existing policy. Ignored if `cos_integration_enabled` is set to `false`."
  default     = false
}

variable "cos_integration_enabled" {
  type        = bool
  description = "Whether to connect an Object Storage service instance to your Event Notifications instance to collect events that failed delivery. If set to `false`, no failed events are captured."
  default     = true
}

variable "cos_endpoint" {
  type        = string
  description = "The endpoint URL for your bucket region. Required if `cos_integration_enabled` is set to `true`. [Learn more](https://cloud.ibm.com/docs/cloud-object-storage?topic=cloud-object-storage-endpoints)."
  default     = null
}
