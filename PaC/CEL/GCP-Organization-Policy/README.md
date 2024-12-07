## Organization Policy 
https://cloud.google.com/resource-manager/docs/organization-policy/overview

Control-Plane Access Control (only 32bit allowed)
```
Resource type: container.googleapis.com/Cluster
Conditions: 
  resource.masterAuthorizedNetworksConfig.enabled != true ||
  resource.masterAuthorizedNetworksConfig.cidrBlocks.exists(value,!value.cidrBlock.endsWith("/32"))
Action: Deny

```
