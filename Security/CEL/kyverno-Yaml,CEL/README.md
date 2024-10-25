1. Deploy Kyverno
kubectl apply -f install.yaml

2-1. deploy validation rule.
k apply -f native-policy.yaml # rule set
k apply -f cel-policy.yaml # rule set

3. test admission webhook
k apply ../workloads/failed.yaml # see error message
k apply ../workloads/success.yaml # deploy successfully