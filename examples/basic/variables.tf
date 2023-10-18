##############################################################################
# Input variables
##############################################################################

variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud API Key"
  sensitive   = true
}

variable "region" {
  type        = string
  description = "IBM Cloud region where event notification will be created, supported regions are: us-south (Dallas), eu-gb (London), eu-de (Frankfurt), au-syd (Sydney)"
  default     = "us-south"
  validation {
    condition     = contains(["us-south", "eu-gb", "eu-de", "au-syd"], var.region)
    error_message = "The specified region is not valid, supported regions are: us-south (Dallas), eu-gb (London), eu-de (Frankfurt), au-syd (Sydney)"
  }
}

variable "prefix" {
  type        = string
  description = "Prefix to append to all resources created by this example"
  default     = "basic"
}

variable "resource_group" {
  type        = string
  description = "The name of an existing resource group to provision resources in to. If not set a new resource group will be created using the prefix variable"
  default     = null
}

variable "tags" {
  type        = list(string)
  description = "Optional list of tags to be added to created resources"
  default     = []
}
