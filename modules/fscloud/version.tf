terraform {
  required_version = ">= 1.3.0"
  required_providers {
    # The below tflint-ignore is required because although the below provider is not directly required by this submodule,
    # it is required by consuming modules, and if not set here, the top level module calling this module will not be
    # able to set alternative alias for the provider.
    # tflint-ignore: terraform_unused_required_providers
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = ">= 1.65.0, <2.0.0"
    }
  }
}
