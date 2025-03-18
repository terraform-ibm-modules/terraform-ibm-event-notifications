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
  default     = "complete"
}

variable "resource_tags" {
  type        = list(string)
  description = "Optional list of tags to be added to created resources"
  default     = []
}

variable "access_tags" {
  type        = list(string)
  description = "A list of access tags to apply to the Event Notifications instance created by the module. For more information, see https://cloud.ibm.com/docs/account?topic=account-access-tags-tutorial."
  default     = []

  validation {
    condition = alltrue([
      for tag in var.access_tags : can(regex("[\\w\\-_\\.]+:[\\w\\-_\\.]+", tag)) && length(tag) <= 128
    ])
    error_message = "Tags must match the regular expression \"[\\w\\-_\\.]+:[\\w\\-_\\.]+\", see https://cloud.ibm.com/docs/account?topic=account-tag&interface=ui#limits for more details"
  }
}

variable "region" {
  type        = string
  description = "IBM Cloud region where event notification will be created, supported regions are: us-south (Dallas), eu-gb (London), eu-de (Frankfurt), au-syd (Sydney), eu-es (Madrid)"
  default     = "us-south"
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
