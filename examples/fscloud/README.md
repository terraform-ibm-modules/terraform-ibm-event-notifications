 # Financial Services Cloud profile example

An end-to-end example that uses the [Profile for IBM Cloud Framework for Financial Services](https://github.com/terraform-ibm-modules/terraform-ibm-event-notifications/tree/main/modules/fscloud) to deploy an instance of Event Notification.

The example uses the IBM Cloud Terraform provider to create the following infrastructure:

- A resource group, if one is not passed in.
- An IAM authorization between all Event Notification instances in the given resource group and the KMS instance that is passed in.
- An Event Notification instance that is encrypted with the KMS root key that is passed in.
- A sample virtual private cloud (VPC).
- A context-based restriction (CBR) rule to only allow Event Notification to be accessible from within the VPC.

:exclamation: **Important:** In this example, only the Event Notification instance complies with the IBM Cloud Framework for Financial Services. Other parts of the infrastructure do not necessarily comply.

## Before you begin

- You need a KMS instance and root key available in the region that you want to deploy your Event Notification instance to.
- To ensure compliance with FSCloud standards, it is required to use HPCS only.
