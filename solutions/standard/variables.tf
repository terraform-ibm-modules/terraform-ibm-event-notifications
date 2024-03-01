########################################################################################################################
# Common variables
########################################################################################################################
variable "ibmcloud_api_key" {
  type        = string
  description = "The API Key to use for IBM Cloud."
  sensitive   = true
}

variable "existing_resource_group" {
  type        = bool
  description = "Whether to use an existing resource group."
  default     = false
}

variable "resource_group_name" {
  type        = string
  description = "The name of a new or an existing resource group in which to provision Event Notification resources to."
}

variable "region" {
  type        = string
  description = "The region in which to provision KMS resources. If using existing KMS, set this to the region in which it is provisioned in."
  default     = "us-south"
}

########################################################################################################################
# Event Notifications
########################################################################################################################
variable "service_credential_names" {
  type        = map(string)
  description = "Map of name, role for service credentials that you want to create for the event notification"
  default     = {}

  validation {
    condition     = alltrue([for name, role in var.service_credential_names : contains(["Manager", "Writer", "Reader", "Event Source Manager", "Channel Editor", "Event Notification Publisher", "Status Reporter", "Device Manager", "Email Sender", "Custom Email Status Reporter"], role)])
    error_message = "Valid values for service credential roles are 'Manager', 'Writer', 'Reader', 'Event Source Manager', 'Channel Editor', 'Event Notification Publisher', 'Status Reporter', 'Device Manager', 'Email Sender', 'Custom Email Status Reporter'"
  }
}

variable "event_notification_name" {
  type        = string
  description = "The name to give the IBM Event Notification instance created by this module."
}

variable "service_plan" {
  type        = string
  description = "Plan for the event notification instance : lite or standard"
  default     = "standard"
  validation {
    condition     = contains(["lite", "standard"], var.service_plan)
    error_message = "The specified plan is not a valid selection! Supported plans are: lite or standard"
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

variable "tags" {
  type        = list(string)
  description = "Optional list of tags to be added to the Event Notification instance"
  default     = []
}

########################################################################################################################
# KMS
########################################################################################################################
variable "existing_kms_instance_crn" {
  type        = string
  description = "The CRN of the Hyper Protect Crypto Services or Key Protect instance."
  default     = null
}

variable "kms_root_key_id" {
  type        = string
  description = "The Key ID of a root key, existing in the KMS instance passed in var.existing_kms_instance_crn, which will be used to encrypt the data encryption keys (DEKs) which are then used to encrypt the data. The code will create the key if one is not passed in."
  default     = null
}

variable "kms_endpoint_url" {
  type        = string
  description = "The KMS endpoint URL to use when configuring KMS encryption. HPCS endpoint URL format- https://api.private.<REGION>.hs-crypto.cloud.ibm.com:<port> and KP endpoint URL format- https://<REGION>.kms.cloud.ibm.com"
}

variable "kms_region" {
  type        = string
  default     = "us-south"
  description = "The region in which KMS instance exists."
}

variable "existing_kms_guid" {
  type        = string
  default     = null
  description = "The GUID of of the KMS instance used for the Event Notification root Key. Only required if not supplying an existing KMS root key and if 'skip_cos_kms_auth_policy' is true."
}

variable "kms_endpoint_type" {
  type        = string
  description = "The type of endpoint to be used for commincating with the KMS instance. Allowed values are: 'public' or 'private' (default)"
  default     = "private"
  validation {
    condition     = can(regex("public|private", var.kms_endpoint_type))
    error_message = "The kms_endpoint_type value must be 'public' or 'private'."
  }
}

variable "en_key_ring_name" {
  type        = string
  default     = "en-key-ring"
  description = "The name to give the Key Ring which will be created for Event Notifications. Not used if supplying an existing Key."
}

variable "en_key_name" {
  type        = string
  default     = "en-key"
  description = "The name to give the Key which will be created for the Event Notifications. Not used if supplying an existing Key."
}


########################################################################################################################
# IAM
########################################################################################################################
variable "skip_iam_authorization_policy" {
  type        = bool
  description = "Set to true to skip the creation of an IAM authorization policy that permits all Event Notification instances in the resource group to read the encryption key from the KMS instance. No policy is created if var.kms_encryption_enabled is set to false."
  default     = false
}
