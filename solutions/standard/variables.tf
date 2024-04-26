########################################################################################################################
# Common variables
########################################################################################################################

variable "ibmcloud_api_key" {
  type        = string
  description = "The API key to use for IBM Cloud."
  sensitive   = true
}

variable "use_existing_resource_group" {
  type        = bool
  description = "Specify whether you want to use an existing resource group."
  default     = false
}

variable "resource_group_name" {
  type        = string
  description = "The name of a new or an existing resource group in which Event Notifications resources are provisioned."
}

variable "region" {
  type        = string
  description = "The region in which the Event Notifications resources are provisioned."
  default     = "us-south"
}

########################################################################################################################
# Event Notifications
########################################################################################################################

variable "service_credential_names" {
  type        = map(string)
  description = "The mapping of names and roles for service credentials that you want to create for the Event Notifications instance."
  default     = {}

  validation {
    condition     = alltrue([for name, role in var.service_credential_names : contains(["Manager", "Writer", "Reader", "Event Source Manager", "Channel Editor", "Event Notification Publisher", "Status Reporter", "Device Manager", "Email Sender", "Custom Email Status Reporter"], role)])
    error_message = "The specified service credential role is not valid! The following values are valid for service credential roles: 'Manager', 'Writer', 'Reader', 'Event Source Manager', 'Channel Editor', 'Event Notification Publisher', 'Status Reporter', 'Device Manager', 'Email Sender', 'Custom Email Status Reporter'"
  }
}

variable "event_notification_name" {
  type        = string
  description = "The name of the Event Notifications instance that is created by this solution."
  default     = "base-event-notifications"
}

variable "service_plan" {
  type        = string
  description = "The pricing plan of the Event Notifications instance. The following pricing plans are available: `Lite`, `Standard`"
  default     = "standard"
  validation {
    condition     = contains(["lite", "standard"], var.service_plan)
    error_message = "The specified pricing plan is not available! The following plans are supported: `Lite`, `Standard`"
  }

}

variable "service_endpoints" {
  type        = string
  description = "Specify whether you want to enable public, or both public and private service endpoints. The following values are supported: `public`, `public-and-private`"
  default     = "public-and-private"
  validation {
    condition     = contains(["public", "public-and-private"], var.service_endpoints)
    error_message = "The specified service endpoint is not supported! The following endpoint options are supported: `public`, `public-and-private`"
  }
}

variable "tags" {
  type        = list(string)
  description = "The optional list of tags to add to the Event Notifications instance."
  default     = []
}

########################################################################################################################
# KMS
########################################################################################################################

variable "existing_kms_instance_crn" {
  type        = string
  description = ""The Cloud Resource Name (CRN) of the Hyper Protect Crypto Services (HPCS) or Key Protect instance."
}

variable "existing_kms_root_key_crn" {
  type        = string
  description = "The key Cloud Resource Name (CRN) of a root key, existing in the key management service (KMS) instance passed in `var.existing_kms_instance_crn`, which will be used to encrypt the data encryption keys (DEKs) which are then used to encrypt the data. The code will create the key if one is not passed in."
  default     = null
}

variable "kms_endpoint_url" {
  type        = string
  description = "The key management service (KMS) endpoint URL to use when you configure KMS encryption. The Hyper Protect Crypto Services (HPCS) endpoint URL format is `https://api.private.<REGION>.hs-crypto.cloud.ibm.com:<port>` and the Key Protect (KP) endpoint URL format is `https://<REGION>.kms.cloud.ibm.com`. Only required if not passing existing key."
}

variable "kms_endpoint_type" {
  type        = string
  description = "The type of the endpoint that is used for communicating with the key management service (KMS) instance. The following values are supported: `public` or `private` (default). Only used if not supplying an existing root key."
  default     = "private"
  validation {
    condition     = can(regex("public|private", var.kms_endpoint_type))
    error_message = "The specified key management service (KMS) endpoint type is not supported. The following values are supported: `public` or `private`."
  }
}

variable "en_key_ring_name" {
  type        = string
  default     = "en-key-ring"
  description = "The name of the key ring which will be created for the Event Notifications instance. Not used if supplying an existing Key."
}

variable "en_key_name" {
  type        = string
  default     = "en-key"
  description = "The name to give the Key which will be created for the Event Notifications. Not used if supplying an existing key."
}

variable "skip_en_kms_auth_policy" {
  type        = bool
  description = "Set this variable value to `true` to skip the creation of an IAM authorization policy that permits all Event Notifications instances in the resource group to read the encryption key from the key management service (KMS) instance."
  default     = false
}
