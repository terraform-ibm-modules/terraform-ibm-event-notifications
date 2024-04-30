# IBM Cloud Event Notifications module
{: #EN-module}

[![Graduated (Supported)](https://img.shields.io/badge/Status-Graduated%20(Supported)-brightgreen)](https://terraform-ibm-modules.github.io/documentation/#/badge-status)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white)](https://github.com/pre-commit/pre-commit)
[![latest release](https://img.shields.io/github/v/release/terraform-ibm-modules/terraform-ibm-event-notifications?logo=GitHub&sort=semver)](https://github.com/terraform-ibm-modules/terraform-ibm-event-notifications/releases/latest)
[![Renovate enabled](https://img.shields.io/badge/renovate-enabled-brightgreen.svg)](https://renovatebot.com/)
[![semantic-release](https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg)](https://github.com/semantic-release/semantic-release)

This module is used to create an IBM Cloud Event Notifications instance to filter and route event notifications from IBM Cloud services like monitoring, to communication channels like email, SMS, and webhooks. Event Notifications provides you information about critical events that occur in your IBM Cloud account or triggers automated actions by using webhooks. For more information, see [Getting started with Event Notifications](https://cloud.ibm.com/docs/event-notifications?topic=event-notifications-getting-started).


<!-- BEGIN OVERVIEW HOOK -->
## Overview
{: #EN-overview}

* [terraform-ibm-event-notifications](#terraform-ibm-event-notifications)
* [Submodules](./modules)
    * [fscloud](./modules/fscloud)
* [Examples](./examples)
    * [Financial Services Cloud profile example](./examples/fscloud)
    * [Basic example](./examples/basic)
    * [Complete example with BYOK encryption and CBR rules](./examples/complete)
* [Contributing](#contributing)

<!-- END OVERVIEW HOOK -->

## terraform-ibm-event-notifications
{: #terraform-EN}

### Usage
{: #terraform-EN-usage}

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
{: #EN-access}

You need the following permissions to run this module:

* Account Management
    - **Event Notifications** service
        - Platform Management Roles
            - `Editor` platform role access

To create service credentials, access the Event Notifications service, and access to call the Event Notifications API, you need the following access:

* Service access roles
    * `Reader` - View Event Notifications instance data
    * `Writer` - View and edit an Event Notifications instance
    * `Channel Editor` - View, create, and delete Event Notifications subscriptions
    * `Manager`	- View, edit, and delete data in an Event Notifications instance
    * `Service Configuration Reader` - Read services configuration for Governance management
    * `Event Source Manager` - Source integration with Event Notifications by using service to service authorization
    * `Event Notifications Publisher` - Create notification and view notifications count
    * `Device Manager` - Custom role to handle push device registration with the Event Notifications service

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

### Requirements
{: #EN-requirements}

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0, <1.7.0 |
| <a name="requirement_ibm"></a> [ibm](#requirement\_ibm) | >= 1.56.1, < 2.0.0 |
| <a name="requirement_time"></a> [time](#requirement\_time) | >= 0.9.1 |

### Modules
{: #EN-modules}

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cbr_rule"></a> [cbr\_rule](#module\_cbr\_rule) | terraform-ibm-modules/cbr/ibm//modules/cbr-rule-module | 1.19.1 |

### Resources
{: #EN-resources}

| Name | Type |
|------|------|
| [ibm_en_integration.en_kms_integration](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/en_integration) | resource |
| [ibm_iam_authorization_policy.kms_policy](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/iam_authorization_policy) | resource |
| [ibm_resource_instance.en_instance](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/resource_instance) | resource |
| [ibm_resource_key.service_credentials](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/resource_key) | resource |
| [time_sleep.wait_for_authorization_policy](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [ibm_en_integrations.en_integrations](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/data-sources/en_integrations) | data source |

### Inputs
{: #EN-inputs}

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cbr_rules"></a> [cbr\_rules](#input\_cbr\_rules) | The optional list of context-based restrictions (CBR) rules to create. | <pre>list(object({<br>    description = string<br>    account_id  = string<br>    rule_contexts = list(object({<br>      attributes = optional(list(object({<br>        name  = string<br>        value = string<br>    }))) }))<br>    enforcement_mode = string<br>  }))</pre> | `[]` | no |
| <a name="input_existing_kms_instance_crn"></a> [existing\_kms\_instance\_crn](#input\_existing\_kms\_instance\_crn) | "The Cloud Resource Name (CRN) of the Hyper Protect Crypto Services (HPCS) or Key Protect instance. This input is required only if `var.kms\_encryption\_enabled` is set to true. | `string` | `null` | no |
| <a name="input_kms_encryption_enabled"></a> [kms\_encryption\_enabled](#input\_kms\_encryption\_enabled) | Set this input value to `true` to control the encryption keys that are used to encrypt the data that you store in the Event Notifications instance. If this value is set to `false`, the data is encrypted by using randomly generated keys. For more information, see [Managing encryption](https://cloud.ibm.com/docs/event-notifications?topic=event-notifications-en-managing-encryption) | `bool` | `false` | no |
| <a name="input_kms_endpoint_url"></a> [kms\_endpoint\_url](#input\_kms\_endpoint\_url) | The URL of the key management service (KMS) endpoint to use when configuring KMS encryption. The Hyper Protect Crypto Services (HPCS) endpoint URL format is `https://api.private.<REGION>.hs-crypto.cloud.ibm.com:<port>` and the Key Protect (KP) endpoint URL format is `https://<REGION>.kms.cloud.ibm.com` | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the Event Notifications instance that is created by this module. | `string` | n/a | yes |
| <a name="input_plan"></a> [plan](#input\_plan) | The pricing plan of the Event Notifications instance. The following pricing plans are available: `Lite`, `Standard` | `string` | `"standard"` | no |
| <a name="input_region"></a> [region](#input\_region) | The IBM Cloud region where the Event Notifications resource is created. The following regions are supported: `us-south` (Dallas), `eu-gb` (London), `eu-de` (Frankfurt), `au-syd` (Sydney), `eu-es` (Madrid) | `string` | `"us-south"` | no |
| <a name="input_resource_group_id"></a> [resource\_group\_id](#input\_resource\_group\_id) | The ID of the resource group where the Event Notifications instance is created. | `string` | n/a | yes |
| <a name="input_root_key_id"></a> [root\_key\_id](#input\_root\_key\_id) | The key ID of a root key, existing in the key management service (KMS) instance that is passed in `var.existing_kms_instance_crn`, which is used to encrypt the data encryption keys (DEKs) which are then used to encrypt the data. This variable is required if `var.kms_encryption_enabled` is set to `true`. | `string` | `null` | no |
| <a name="input_service_credential_names"></a> [service\_credential\_names](#input\_service\_credential\_names) | The mapping of names and roles for service credentials that you want to create for the Event Notifications instance. | `map(string)` | `{}` | no |
| <a name="input_service_endpoints"></a> [service\_endpoints](#input\_service\_endpoints) | Specify whether you want to enable public, or both public and private service endpoints. The following values are supported: `public`, `public-and-private` | `string` | `"public-and-private"` | no |
| <a name="input_skip_iam_authorization_policy"></a> [skip\_iam\_authorization\_policy](#input\_skip\_iam\_authorization\_policy) | Set this input value to `true` to skip the creation of an IAM authorization policy that permits all Event Notifications instances in the resource group to read the encryption key from the key management service (KMS) instance. No policy is created if `var.kms_encryption_enabled` variable is set to `false`. | `bool` | `false` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Optional list of tags to be added to the Event Notification instance | `list(string)` | `[]` | no |

### Outputs
{: #EN-outputs}

| Name | Description |
|------|-------------|
| <a name="output_crn"></a> [crn](#output\_crn) | The Cloud Resource Name (CRN) of the Event Notifications instance. |
| <a name="output_event_notification_instance_name"></a> [event\_notification\_instance\_name](#output\_event\_notification\_instance\_name) | The name of the Event Notifications instance. |
| <a name="output_guid"></a> [guid](#output\_guid) | The globally unique identifier of the Event Notifications instance. |
| <a name="output_service_credentials_json"></a> [service\_credentials\_json](#output\_service\_credentials\_json) | The generated set of credentials in JSON format. |
| <a name="output_service_credentials_object"></a> [service\_credentials\_object](#output\_service\_credentials\_object) | The generated set of credentials uploaded into the IBM Cloud Object Storage. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

<!-- BEGIN CONTRIBUTING HOOK -->

<!-- Leave this section as is so that your module has a link to local development environment set up steps for contributors to follow -->
## Contributing
{: #EN-contributing}

You can report issues and request features for this module in GitHub issues in the module repo. See [Report an issue or request a feature](https://github.com/terraform-ibm-modules/.github/blob/main/.github/SUPPORT.md).

To set up your local development environment, see [Local development setup](https://terraform-ibm-modules.github.io/documentation/#/local-dev-setup) in the project documentation.
<!-- Source for this readme file: https://github.com/terraform-ibm-modules/common-dev-assets/tree/main/module-assets/ci/module-template-automation -->
<!-- END CONTRIBUTING HOOK -->
