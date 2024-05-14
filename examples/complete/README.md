# Complete example with BYOK encryption and CBR rules

An end-to-end example that does the following:

- Create a new resource group if one is not passed in.
- Create Key Protect instance with root key.
- Create a new Event Notifications instance with bring your own key encryption.
- Create a Cloud Object Storage service instance and a bucket.
- Connect a Cloud Object Storage service instance to collect events that failed delivery.
- Create a Virtual Private Cloud (VPC).
- Create a context-based restriction (CBR) rule to only allow Event Notifications to be accessible from within the VPC.
- Create service credentials for the Event Notifications instance.
