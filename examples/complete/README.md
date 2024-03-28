# Complete example with BYOK encryption and CBR rules

An end-to-end example that does the following:

- Create a new resource group if one is not passed in.
- Create Key Protect instance with root key.
- Create a new Event Notification instance with BYOK encryption.
- Create a Cloud Object Storage Instance and Bucket.
- Connect a Cloud Object Storage Services instance to collect the events which failed delivery.
- Create a Virtual Private Cloud (VPC).
- Create a context-based restriction (CBR) rule to only allow Event Notification to be accessible from within the VPC.
- Create a service credentials for the Event Notification instance.
