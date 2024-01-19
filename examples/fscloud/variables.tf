##############################################################################
# Input Variables
##############################################################################

variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud API Key"
  sensitive   = true
}

variable "resource_group" {
  type        = string
  description = "The name of an existing resource group to provision resources in to. If not set a new resource group will be created using the prefix variable"
  default     = null
}

variable "prefix" {
  type        = string
  description = "Prefix to append to all resources created by this example"
  default     = "en-fs"
}

variable "resource_tags" {
  type        = list(string)
  description = "Optional list of tags to be added to the Event Notification instance"
  default     = []
}

variable "region" {
  type        = string
  description = "IBM Cloud region where event notification will be created, supported regions are: us-south (Dallas), eu-gb (London), eu-de (Frankfurt), au-syd (Sydney), eu-es (Madrid)"
  default     = "us-south"
}

variable "existing_kms_instance_crn" {
  description = "The CRN of the Hyper Protect Crypto Services or Key Protect instance. Required only if var.kms_encryption_enabled is set to true. To ensure compliance with FSCloud standards, it is required to use HPCS only"
  type        = string
}

variable "root_key_id" {
  type        = string
  description = "The Key ID of a root key, existing in the KMS instance passed in var.existing_kms_instance_crn, which will be used to encrypt the data encryption keys (DEKs) which are then used to encrypt the data. Required if var.kms_encryption_enabled is set to true."
}

variable "service_credential_names" {
  description = "Map of name, role for service credentials that you want to create for the event notification"
  type        = map(string)
  default = {
    "en_manager" : "Manager",
    "en_writer" : "Writer",
    "en_reader" : "Reader",
    "en_channel_editor" : "Channel Editor",
    "en_device_manager" : "Device Manager",
    "en_event_source_manager" : "Event Source Manager",
    "en_event_notifications_publisher" : "Event Notification Publisher",
    "en_status_reporter" : "Status Reporter",
    "en_email_sender" : "Email Sender",
    "en_custom_email_status_reporter" : "Custom Email Status Reporter",
  }
}
