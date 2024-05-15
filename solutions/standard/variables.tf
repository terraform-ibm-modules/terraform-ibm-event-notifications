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
  description = "Whether to use an existing resource group."
  default     = false
}

variable "resource_group_name" {
  type        = string
  description = "The name of a new or existing resource group to provision Event Notifications resources to."
}

variable "region" {
  type        = string
  description = "The IBM Cloud region where the Event Notification instance is created."
  default     = "us-south"
}

variable "existing_monitoring_crn" {
  type        = string
  nullable    = true
  default     = null
  description = "(Optional) The CRN of an existing IBM Cloud Monitoring instance. It is used to monitor the IBM Cloud Object Storage bucket that is used for storing failed events."
}

########################################################################################################################
# Event Notifications
########################################################################################################################

variable "service_credential_names" {
  type        = map(string)
  description = "The mapping of names and roles for service credentials that you want to create for the Event Notifications instance. Available values: `Manager`, `Writer`, `Reader`, `Event Source Manager`, `Channel Editor`, `Event Notification Publisher`, `Status Reporter`, `Device Manager`, `Email Sender`, and `Custom Email Status Reporter`"
  default     = {}

  validation {
    condition     = alltrue([for name, role in var.service_credential_names : contains(["Manager", "Writer", "Reader", "Event Source Manager", "Channel Editor", "Event Notification Publisher", "Status Reporter", "Device Manager", "Email Sender", "Custom Email Status Reporter"], role)])
    error_message = "Valid values for service credential roles are 'Manager', 'Writer', 'Reader', 'Event Source Manager', 'Channel Editor', 'Event Notification Publisher', 'Status Reporter', 'Device Manager', 'Email Sender', 'Custom Email Status Reporter'"
  }
}

variable "event_notification_name" {
  type        = string
  description = "The name to give the IBM Event Notification instance created by this solution."
  default     = "base-event-notifications"
}

variable "service_plan" {
  type        = string
  description = "The plan for the Event Notifications instance. Available values: `lite`, `standard`."
  default     = "standard"
  validation {
    condition     = contains(["lite", "standard"], var.service_plan)
    error_message = "The plan you specified is not valid. The supported plans are `lite` or `standard`."
  }

}

variable "service_endpoints" {
  type        = string
  description = "Specify whether you want to enable the public or both public and private service endpoints. Available values: `public`, `public-and-private`."
  default     = "public-and-private"
  validation {
    condition     = contains(["public", "public-and-private"], var.service_endpoints)
    error_message = "The specified service endpoint is not a valid selection. Supported options are: `public` or `public-and-private`."
  }
}

variable "tags" {
  type        = list(string)
  description = "The list of tags to add to the Event Notification instance."
  default     = []
}

########################################################################################################################
# KMS
########################################################################################################################

variable "existing_kms_instance_crn" {
  type        = string
  description = "The CRN of the Hyper Protect Crypto Services or Key Protect instance."
}

variable "existing_kms_root_key_crn" {
  type        = string
  description = "The key CRN of a root key that exists in the KMS instance that is specified in the `existing_kms_instance_crn` input. The key is used to encrypt the data encryption keys, which are then used to encrypt the data. The code creates the key, if one is not passed in."
  default     = null
}

variable "kms_endpoint_url" {
  type        = string
  description = "The KMS endpoint URL to use when configuring KMS encryption. The URL format for Hyper Protect Crypto Services is https://api.private.<REGION>.hs-crypto.cloud.ibm.com:<port>. The URL format for Key Protect is https://<REGION>.kms.cloud.ibm.com. Required only if an existing key is not specified in `existing_kms_root_key_crn`."
}

variable "kms_endpoint_type" {
  type        = string
  description = "The type of endpoint to use to communicate with the KMS instance. Available values: `public`, `private` (default). Used only if an existing key is not specified in `existing_kms_root_key_crn`."
  default     = "private"
  validation {
    condition     = can(regex("public|private", var.kms_endpoint_type))
    error_message = "The kms_endpoint_type value must be 'public' or 'private'."
  }
}

variable "en_key_ring_name" {
  type        = string
  default     = "en-key-ring"
  description = "The name to give the key ring to create for the Event Notifications service. Not used if an existing key is specfied."
}

variable "en_key_name" {
  type        = string
  default     = "en-key"
  description = "The name for the key that will be created for the Event Notifications. Not used if an existing key is specfied."
}

variable "cos_key_ring_name" {
  type        = string
  default     = "en-cos-key-ring"
  description = "The name of the key ring which will be created for Object Storage. Not used if supplying an existing key or if `existing_cos_bucket_name` is specified."
}

variable "cos_key_name" {
  type        = string
  default     = "en-cos-key"
  description = "The name of the key which will be created for Object Storage. Not used if supplying an existing key or if `existing_cos_bucket_name` is specified."
}

variable "skip_en_kms_auth_policy" {
  type        = bool
  description = "Whether an IAM authorization policy is created that permits all Event Notifications instances in the resource group to read the encryption key from the KMS instance. Set to `true` to use an existing policy."
  default     = false
}

########################################################################################################################
# COS
########################################################################################################################

variable "existing_cos_instance_crn" {
  type        = string
  nullable    = true
  default     = null
  description = "The CRN of an IBM Cloud Object Storage instance. If not supplied, a new instance is created."
}

variable "existing_cos_bucket_name" {
  type        = string
  nullable    = true
  default     = null
  description = "The name of an existing bucket inside the existing Object Storage instance. If not supplied, a new bucket is created."
}

variable "cos_destination_name" {
  type        = string
  description = "The name of the Object Storage destination which to create for the storage of failed delivery events."
  default     = "COS Destination"
}

variable "cos_bucket_name" {
  type        = string
  description = "The name to use when creating the Object Storage bucket for the storage of failed delivery events. Bucket names are globally unique. If `add_bucket_name_suffix` is set to `true`, a random 4 character string is added to this name to help ensure that the bucket name is unique."
  default     = "base-event-notifications-bucket"
}

variable "skip_en_cos_auth_policy" {
  type        = bool
  description = "Whether an IAM authorization policy is created that permits all Event Notifications instances in the resource group to interact with your Object Storage instance. Set to `true` to use an existing policy."
  default     = false
}

variable "cos_instance_name" {
  type        = string
  default     = "base-security-services-cos"
  description = "The name to use when creating the Object Storage instance."
}

variable "cos_instance_tags" {
  type        = list(string)
  description = "The optional list of tags to add to the Object Storage instance. Only used if not supplying an existing instance."
  default     = []
}

variable "cos_instance_access_tags" {
  type        = list(string)
  description = "The list of access tags to apply to the Object Storage instance. Only used if not supplying an existing instance."
  default     = []
}

variable "add_bucket_name_suffix" {
  type        = bool
  description = "Whether to add a randomly generated 4-character suffix to the newly provisioned Object Storage bucket name. Used only if not using an existing bucket. Set to `false` if you want full control over bucket naming by using the `cos_bucket_name` variable."
  default     = true
}

variable "cos_plan" {
  description = "The plan that is used for creating the Object Storage instance. Only used if `create_cos_instance` is true. Available values: `lite`, `standard` and `cos-one-rate-plan`."
  type        = string
  default     = "standard"
  validation {
    condition     = contains(["standard", "lite", "cos-one-rate-plan"], var.cos_plan)
    error_message = "The specified cos_plan is not a valid selection."
  }
}

variable "cross_region_location" {
  description = "Specify the cross-regional bucket location. Possiblevalues: `us`, `eu`, and `ap`. If you pass a value for this variable, set the value of `region` and `single_site_location` to null."
  type        = string
  default     = null

  validation {
    condition     = var.cross_region_location == null || can(regex("us|eu|ap", var.cross_region_location))
    error_message = "The variable `cross_region_location` value must be `us` or `eu`, `ap`, or `null`."
  }
}

variable "retention_enabled" {
  description = "Set to `true` to enable retention for the Object Storage bucket. Used only if `create_cos_bucket` is set to `true`."
  type        = bool
  default     = false
}

variable "management_endpoint_type_for_bucket" {
  description = "The type of endpoint for the IBM Terraform provider to use to manage Object Storage buckets. Available values: `public`, `private`, `direct`. Make sure to enable virtual routing and forwarding in your account if you specify `private`, and that the Terraform runtime has access to the IBM Cloud private network."
  type        = string
  default     = "private"
  validation {
    condition     = contains(["public", "private", "direct"], var.management_endpoint_type_for_bucket)
    error_message = "The specified `management_endpoint_type_for_bucket` is not a valid selection."
  }
}

variable "existing_activity_tracker_crn" {
  type        = string
  nullable    = true
  default     = null
  description = "(Optional) The CRN of an existing Activity Tracker instance. Used to send Object Storage bucket log data and all object write events to the Activity Tracker. Used only if not supplying an existing Object Storage bucket."
}

variable "existing_cos_endpoint" {
  type        = string
  description = "The endpoint URL for your bucket region. [Learn more](https://cloud.ibm.com/docs/cloud-object-storage?topic=cloud-object-storage-endpoints)"
  default     = null
}
