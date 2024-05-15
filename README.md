# Event Notification module
[![Graduated (Supported)](https://img.shields.io/badge/Status-Graduated%20(Supported)-brightgreen)](https://terraform-ibm-modules.github.io/documentation/#/badge-status)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white)](https://github.com/pre-commit/pre-commit)
[![latest release](https://img.shields.io/github/v/release/terraform-ibm-modules/terraform-ibm-event-notifications?logo=GitHub&sort=semver)](https://github.com/terraform-ibm-modules/terraform-ibm-event-notifications/releases/latest)
[![Renovate enabled](https://img.shields.io/badge/renovate-enabled-brightgreen.svg)](https://renovatebot.com/)
[![semantic-release](https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg)](https://github.com/semantic-release/semantic-release)

A module to create IBM Cloud Event Notifications.

<!-- BEGIN OVERVIEW HOOK -->
## Overview
* [terraform-ibm-event-notifications](#terraform-ibm-event-notifications)
* [Submodules](./modules)
    * [fscloud](./modules/fscloud)
* [Examples](./examples)
    * [ Financial Services Cloud profile example](./examples/fscloud)
    * [Basic example](./examples/basic)
    * [Complete example with BYOK encryption and CBR rules](./examples/complete)
* [Contributing](#contributing)
<!-- END OVERVIEW HOOK -->

## terraform-ibm-event-notifications

### Usage

```hcl
module "event_notification" {
  source            = "terraform-ibm-modules/event-notifications/ibm"
  version           = "X.X.X" # Replace "X.X.X" with a release version to lock into a specific release
  resource_group_id = "a8cff104f1764e98aac9ab879198230a" # pragma: allowlist secret
  name              = "event-notification"
  tags              = ["dev", "qa"]
  plan              = "lite"
  service_endpoints = "public"
  service_credential_names = {
                                "en_manager" : "Manager",
                                "en_writer" : "Writer",
                                "en_reader" : "Reader",
                             }
}
```

### Required IAM access policies

You need the following permissions to run this module.

- Account Management
    - **Event Notification** service
        - Platform Management Roles
            - `Editor` platform role access

To create service credentials, access to Event Notifications and access to call the Event Notifications API, you need the following access.

- Service Access Roles
    - `Reader` - View Event Notifications instance data
    - `Writer` - View and edit an Event Notifications instance
    - `Channel Editor` - View, create, and delete Event Notifications subscriptions
    - `Manager`	- View, edit, and delete data in an Event Notifications instance
    - `Service Configuration Reader` - Read services configuration for Governance management
    - `Event Source Manager` - Source integration with Event Notifications by using service to service authorization
    - `Event Notifications Publisher` - Create notification and view notifications count
    - `Device Manager` - Custom role to handle push device registration with the Event Notifications service

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0, <1.7.0 |
| <a name="requirement_ibm"></a> [ibm](#requirement\_ibm) | >= 1.63.0, < 2.0.0 |
| <a name="requirement_time"></a> [time](#requirement\_time) | >= 0.9.1 |

### Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cbr_rule"></a> [cbr\_rule](#module\_cbr\_rule) | terraform-ibm-modules/cbr/ibm//modules/cbr-rule-module | 1.19.1 |

### Resources

| Name | Type |
|------|------|
| [ibm_en_destination_cos.cos_en_destination](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/en_destination_cos) | resource |
| [ibm_en_integration.en_kms_integration](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/en_integration) | resource |
| [ibm_iam_authorization_policy.cos_policy](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/iam_authorization_policy) | resource |
| [ibm_iam_authorization_policy.kms_policy](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/iam_authorization_policy) | resource |
| [ibm_resource_instance.en_instance](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/resource_instance) | resource |
| [ibm_resource_key.service_credentials](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/resource_key) | resource |
| [time_sleep.wait_for_cos_authorization_policy](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [time_sleep.wait_for_kms_authorization_policy](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [ibm_en_integrations.en_integrations](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/data-sources/en_integrations) | data source |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cbr_rules"></a> [cbr\_rules](#input\_cbr\_rules) | (Optional, list) List of CBR rules to create | <pre>list(object({<br>    description = string<br>    account_id  = string<br>    rule_contexts = list(object({<br>      attributes = optional(list(object({<br>        name  = string<br>        value = string<br>    }))) }))<br>    enforcement_mode = string<br>  }))</pre> | `[]` | no |
| <a name="input_cos_bucket_name"></a> [cos\_bucket\_name](#input\_cos\_bucket\_name) | The name of an existing IBM Cloud Object Storage bucket which will be used for storage of failed delivery events. Required if `cos_integration_enabled` is set to true. | `string` | `null` | no |
| <a name="input_cos_destination_name"></a> [cos\_destination\_name](#input\_cos\_destination\_name) | The name of the IBM Cloud Object Storage destination which will be created for the storage of failed delivery events. | `string` | `"COS Destination"` | no |
| <a name="input_cos_endpoint"></a> [cos\_endpoint](#input\_cos\_endpoint) | The endpoint URL for your bucket region. For more information, see https://cloud.ibm.com/docs/cloud-object-storage?topic=cloud-object-storage-endpoints. Required if `cos_integration_enabled` is set to true. | `string` | `null` | no |
| <a name="input_cos_instance_id"></a> [cos\_instance\_id](#input\_cos\_instance\_id) | The ID of the IBM Cloud Object Storage instance in which the bucket that is defined in the `cos_bucket_name` variable exists. Required if `cos_integration_enabled` is set to true. | `string` | `null` | no |
| <a name="input_cos_integration_enabled"></a> [cos\_integration\_enabled](#input\_cos\_integration\_enabled) | Set to `true` to connect a Cloud Object Storage service instance to your Event Notifications instance to collect events that failed delivery. If set to false, no failed events will be captured. | `bool` | `false` | no |
| <a name="input_existing_kms_instance_crn"></a> [existing\_kms\_instance\_crn](#input\_existing\_kms\_instance\_crn) | The CRN of the Hyper Protect Crypto Services or Key Protect instance. Required only if var.kms\_encryption\_enabled is set to true. | `string` | `null` | no |
| <a name="input_kms_encryption_enabled"></a> [kms\_encryption\_enabled](#input\_kms\_encryption\_enabled) | Set this to true to control the encryption keys used to encrypt the data that you store in Event Notification. If set to false, the data is encrypted by using randomly generated keys. For more info on Managing Encryption, see https://cloud.ibm.com/docs/event-notifications?topic=event-notifications-en-managing-encryption | `bool` | `false` | no |
| <a name="input_kms_endpoint_url"></a> [kms\_endpoint\_url](#input\_kms\_endpoint\_url) | The KMS endpoint URL to use when configuring KMS encryption. The URL format for Hyper Protect Crypto Services is https://api.private.<REGION>.hs-crypto.cloud.ibm.com:<port>. The URL format for Key Protect is https://<REGION>.kms.cloud.ibm.com. Required only if an existing key is not specified in `existing_kms_root_key_crn`. | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | The name to give the IBM Event Notification instance created by this module. | `string` | n/a | yes |
| <a name="input_plan"></a> [plan](#input\_plan) | The plan for the Event Notifications instance. Available values: `lite`, `standard`. | `string` | `"standard"` | no |
| <a name="input_region"></a> [region](#input\_region) | IBM Cloud region where event notification will be created, supported regions are: us-south (Dallas), eu-gb (London), eu-de (Frankfurt), au-syd (Sydney), eu-es (Madrid) | `string` | `"us-south"` | no |
| <a name="input_resource_group_id"></a> [resource\_group\_id](#input\_resource\_group\_id) | The resource group ID where the Event Notification instance will be created. | `string` | n/a | yes |
| <a name="input_root_key_id"></a> [root\_key\_id](#input\_root\_key\_id) | The Key ID of a root key, existing in the KMS instance passed in var.existing\_kms\_instance\_crn, which will be used to encrypt the data encryption keys (DEKs) which are then used to encrypt the data. Required if var.kms\_encryption\_enabled is set to true. | `string` | `null` | no |
| <a name="input_service_credential_names"></a> [service\_credential\_names](#input\_service\_credential\_names) | Map of name, role for service credentials that you want to create for the event notification | `map(string)` | `{}` | no |
| <a name="input_service_endpoints"></a> [service\_endpoints](#input\_service\_endpoints) | Specify whether you want to enable the public or both public and private service endpoints. Available values: `public`, `public-and-private`. | `string` | `"public-and-private"` | no |
| <a name="input_skip_en_cos_auth_policy"></a> [skip\_en\_cos\_auth\_policy](#input\_skip\_en\_cos\_auth\_policy) | Set to `true` to skip the creation of an IAM authorization policy that permits all Event Notifications instances in the resource group to interact with your Cloud Object Storage instance. No policy is created if `var.cos_integration_enabled` is set to false. | `bool` | `false` | no |
| <a name="input_skip_en_kms_auth_policy"></a> [skip\_en\_kms\_auth\_policy](#input\_skip\_en\_kms\_auth\_policy) | Whether an IAM authorization policy is created that permits all Event Notifications instances in the resource group to read the encryption key from the KMS instance. Set to `true` to use an existing policy. No policy is created if `kms_encryption_enabled` is set to `false`. | `bool` | `false` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | The list of tags to add to the Event Notification instance. | `list(string)` | `[]` | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_crn"></a> [crn](#output\_crn) | Event Notification crn |
| <a name="output_event_notification_instance_name"></a> [event\_notification\_instance\_name](#output\_event\_notification\_instance\_name) | Event Notification name |
| <a name="output_guid"></a> [guid](#output\_guid) | Event Notification guid |
| <a name="output_service_credentials_json"></a> [service\_credentials\_json](#output\_service\_credentials\_json) | Service credentials json map |
| <a name="output_service_credentials_object"></a> [service\_credentials\_object](#output\_service\_credentials\_object) | Service credentials object |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

<!-- BEGIN CONTRIBUTING HOOK -->

<!-- Leave this section as is so that your module has a link to local development environment set up steps for contributors to follow -->
## Contributing

You can report issues and request features for this module in GitHub issues in the module repo. See [Report an issue or request a feature](https://github.com/terraform-ibm-modules/.github/blob/main/.github/SUPPORT.md).

To set up your local development environment, see [Local development setup](https://terraform-ibm-modules.github.io/documentation/#/local-dev-setup) in the project documentation.
<!-- Source for this readme file: https://github.com/terraform-ibm-modules/common-dev-assets/tree/main/module-assets/ci/module-template-automation -->
<!-- END CONTRIBUTING HOOK -->
