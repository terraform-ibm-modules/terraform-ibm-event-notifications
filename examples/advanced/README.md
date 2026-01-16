# Advanced example with BYOK encryption and CBR rules

<!-- BEGIN SCHEMATICS DEPLOY HOOK -->
<a href="https://cloud.ibm.com/schematics/workspaces/create?workspace_name=event-notifications-advanced-example&repository=https://github.com/terraform-ibm-modules/terraform-ibm-event-notifications/tree/main/examples/advanced"><img src="https://img.shields.io/badge/Deploy%20with IBM%20Cloud%20Schematics-0f62fe?logo=ibm&logoColor=white&labelColor=0f62fe" alt="Deploy with IBM Cloud Schematics" style="height: 16px; vertical-align: text-bottom;"></a>
<!-- END SCHEMATICS DEPLOY HOOK -->


An end-to-end example that creates the following infrastructure:

- A resource group, if one is not passed in.
- A Key Protect instance with a root key.
- An Event Notifications instance with bring-your-own-key encryption.
- Service credentials for the Event Notifications instance.
- An IBM Cloud Object Storage service instance and bucket to collect events that fail delivery.
- An Event Notifications webhook destination, topic and subscription.

<!-- BEGIN SCHEMATICS DEPLOY TIP HOOK -->
:information_source: Ctrl/Cmd+Click or right-click on the Schematics deploy button to open in a new tab
<!-- END SCHEMATICS DEPLOY TIP HOOK -->
