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
  description = "The name of a new or an existing resource group in which to provision the Databases for Elasicsearch in.  If a `prefix` input variable is specified, it is added to this name in the `<prefix>-value` format."
}

variable "region" {
  type        = string
  description = "The region in which the Event Notifications resources are provisioned."
  default     = "us-south"
}

variable "existing_monitoring_crn" {
  type        = string
  nullable    = true
  default     = null
  description = "The CRN of an IBM Cloud Monitoring instance used to monitor the IBM Cloud Object Storage bucket that is used for storing failed events. If no value passed, metrics are sent to the instance associated to the container's location unless otherwise specified in the Metrics Router service configuration. Ignored if using existing Object Storage bucket."
}

variable "prefix" {
  type        = string
  description = "(Optional) Prefix to add to all resources created by this solution."
  default     = null
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
    error_message = "The specified service credential role is not valid. The following values are valid for service credential roles: 'Manager', 'Writer', 'Reader', 'Event Source Manager', 'Channel Editor', 'Event Notification Publisher', 'Status Reporter', 'Device Manager', 'Email Sender', 'Custom Email Status Reporter'"
  }
}

variable "event_notification_name" {
  type        = string
  description = "The name of the Event Notifications instance that is created by this solution. If a `prefix` input variable is specified, it is added to this name in the `<prefix>-value` format."
  default     = "base-event-notifications"
}

variable "service_plan" {
  type        = string
  description = "The pricing plan of the Event Notifications instance. Possible values: `Lite`, `Standard`"
  default     = "standard"
  validation {
    condition     = contains(["lite", "standard"], var.service_plan)
    error_message = "The specified pricing plan is not available. The following plans are supported: `Lite`, `Standard`"
  }

}

variable "service_endpoints" {
  type        = string
  description = "Specify whether you want to enable public, or both public and private service endpoints. Possible values: `public`, `public-and-private`"
  default     = "public-and-private"
  validation {
    condition     = contains(["public", "public-and-private"], var.service_endpoints)
    error_message = "The specified service endpoint is not supported. The following endpoint options are supported: `public`, `public-and-private`"
  }
}

variable "tags" {
  type        = list(string)
  description = "The list of tags to add to the Event Notifications instance."
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
  description = "The key CRN of a root key, existing in the KMS instance passed in `var.existing_kms_instance_crn`, which will be used to encrypt the data encryption keys which are then used to encrypt the data. The code will create the key if one is not passed in."
  default     = null
}

variable "kms_endpoint_url" {
  type        = string
  description = "The KMS endpoint URL to use when you configure KMS encryption. The Hyper Protect Crypto Services endpoint URL format is `https://api.private.<REGION>.hs-crypto.cloud.ibm.com:<port>` and the Key Protect endpoint URL format is `https://<REGION>.kms.cloud.ibm.com`. Only required if not passing existing key."
}

variable "kms_endpoint_type" {
  type        = string
  description = "The type of the endpoint that is used for communicating with the KMS instance. Possible values: `public` or `private` (default). Only used if not supplying an existing root key."
  default     = "private"
  validation {
    condition     = can(regex("public|private", var.kms_endpoint_type))
    error_message = "The specified KMS endpoint type is not supported. The following values are supported: `public` or `private`."
  }
}

variable "en_key_ring_name" {
  type        = string
  default     = "en-key-ring"
  description = "The name of the key ring which will be created for the Event Notifications instance. Not used if supplying an existing key. If a `prefix` input variable is specified, it is added to this name in the `<prefix>-value` format."
}

variable "en_key_name" {
  type        = string
  default     = "en-key"
  description = "The name for the key that will be created for the Event Notifications. Not used if an existing key is specfied. If a `prefix` input variable is specified, it is added to this name in the `<prefix>-value` format."
}

variable "cos_key_ring_name" {
  type        = string
  default     = "en-cos-key-ring"
  description = "The name of the key ring which will be created for Object Storage. Not used if supplying an existing key or if `existing_cos_bucket_name` is specified. If a `prefix` input variable is specified, it is added to this name in the `<prefix>-value` format."
}

variable "cos_key_name" {
  type        = string
  default     = "en-cos-key"
  description = "The name of the key which will be created for the Event Notifications. Not used if supplying an existing key. If a `prefix` input variable is specified, it is added to this name in the `<prefix>-value` format."
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

variable "cos_bucket_name" {
  type        = string
  description = "The name to use when creating the Object Storage bucket for the storage of failed delivery events. Bucket names are globally unique. If `add_bucket_name_suffix` is set to `true`, a random 4 character string is added to this name to help ensure that the bucket name is unique. If a `prefix` input variable is specified, it is added to this name in the `<prefix>-value` format."
  default     = "base-event-notifications-bucket"
}

variable "skip_en_cos_auth_policy" {
  type        = bool
  description = "Whether an IAM authorization policy is created for your Event Notifications instance to interact with your Object Storage bucket. Set to `true` to use an existing policy. Ignored if `cos_integration_enabled` is set to `false`."
  default     = false
}

variable "skip_cos_kms_auth_policy" {
  type        = bool
  description = "Whether an IAM authorization policy is created for your Cloud Object Storage instance to read the encryption key from the KMS instance. Set to `true` to use an existing policy."
  default     = false
}

variable "cos_instance_name" {
  type        = string
  default     = "base-security-services-cos"
  description = "The name to use when creating the Object Storage instance. If a `prefix` input variable is specified, it is added to this name in the `<prefix>-value` format."
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
  description = "The plan that is used for creating the Object Storage instance. Available values: `lite`, `standard` and `cos-one-rate-plan`."
  type        = string
  default     = "standard"
  validation {
    condition     = contains(["standard", "lite", "cos-one-rate-plan"], var.cos_plan)
    error_message = "The specified cos_plan is not a valid selection."
  }
}

variable "cross_region_location" {
  description = "Specify the cross-regional bucket location. Possiblevalues: `us`, `eu`, and `ap`. If you pass a value for this variable, you must set the value of `cos_bucket_region` to null. If `cross_region_location` and `cos_bucket_region` are both set to null, then `region` will be used."
  type        = string
  default     = null

  validation {
    condition     = var.cross_region_location == null || can(regex("us|eu|ap", var.cross_region_location))
    error_message = "The variable `cross_region_location` value must be `us` or `eu`, `ap`, or `null`."
  }
}

variable "cos_bucket_region" {
  type        = string
  description = "The COS bucket region. If you pass a value for this variable, you must set the value of `cross_region_location` to null. If `cross_region_location` and `cos_bucket_region` are both set to null, then `region` will be used."
  default     = null
}

variable "archive_days" {
  description = "Specifies the number of days when the archive rule action takes effect. This must be set to null when when using var.cross_region_location as archive data is not supported with this feature."
  type        = number
  default     = null
}

variable "retention_enabled" {
  type        = bool
  description = "Set to `true` to skip the creation of an IAM authorization policy that permits all Event Notifications instances in the resource group to read the encryption key from the KMS instance."
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
  description = "The CRN of an Activity Tracker instance to configure on the IBM Cloud Object Storage bucket that is used for storing failed events. If no value passed, events are sent to the instance associated to the container's location unless otherwise specified in the Activity Tracker Event Routing service configuration. Ignored if using existing Object Storage bucket."
}

variable "existing_cos_endpoint" {
  type        = string
  description = "The endpoint URL for your bucket region. [Learn more](https://cloud.ibm.com/docs/cloud-object-storage?topic=cloud-object-storage-endpoints). Only required if using an existing bucket with the `existing_cos_bucket_name` variable."
  default     = null
}
