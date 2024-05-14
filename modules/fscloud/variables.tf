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

variable "skip_en_kms_auth_policy" {
  type        = bool
  description = "Set to true to skip the creation of an IAM authorization policy that permits all event notification instances in the provided resource group reader access to the instance specified in the existing_kms_instance_guid variable."
  default     = false
}

variable "existing_kms_instance_crn" {
  description = "The CRN of the Hyper Protect Crypto Services or Key Protect instance. To ensure compliance with FSCloud standards, it is required to use HPCS only."
  type        = string
}

variable "root_key_id" {
  type        = string
  description = "The Key ID of a root key, existing in the KMS instance passed in var.existing_kms_instance_crn, which will be used to encrypt the data encryption keys (DEKs) which are then used to encrypt the data."
}

variable "kms_endpoint_url" {
  description = "The KMS endpoint URL to use when configuring KMS encryption."
  type        = string
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

########################################################################################################################
# COS
########################################################################################################################

variable "cos_destination_name" {
  type        = string
  description = "The name to give the IBM Cloud Object Storage destination which will be created for storage of failed delivery events."
  default     = "COS Destination"
}

variable "cos_bucket_name" {
  type        = string
  description = "The name of an existing IBM Cloud Object Storage bucket which will be used for storage of failed delivery events."
  default     = null
}

variable "cos_instance_id" {
  type        = string
  description = "The ID of the IBM Cloud Object Storage instance in which the bucket defined in the cos_bucket_name variable exists. Required only if var.cos_integration_enabled is set to true."
  default     = null
}

variable "skip_en_cos_auth_policy" {
  type        = bool
  description = "Set to true to skip the creation of an IAM authorization policy that permits all Event Notification instances in the resource group to interact with your Cloud Object Storage instance. No policy is created if var.cos_integration_enabled is set to false."
  default     = false
}

variable "cos_integration_enabled" {
  type        = bool
  description = "Set this to true to connect a Cloud Object Storage Services instance to your Event Notifications instance to collect the events which failed delivery. If set to false, no failed events will be captured."
  default     = true
}

variable "cos_endpoint" {
  type        = string
  description = "The endpoint url for your bucket region, for further information refer to the official docs https://cloud.ibm.com/docs/cloud-object-storage?topic=cloud-object-storage-endpoints. Required if `cos_integration_enabled` is set to true."
  default     = null
}
