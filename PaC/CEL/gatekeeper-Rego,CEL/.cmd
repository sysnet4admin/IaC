1. Deploy Gatekeeper
kubectl apply -f install.yaml

2-1. deploy validation rule.
k apply -f rego-constraint-template.yaml # rule set
k apply -f cel-constraint-template.yaml # rule set

2-2. apply policy rule set.
k apply -f rego-constraint.yaml
k apply -f cel-constraint.yaml

3. test admission webhook
k apply ../workloads/failed.yaml # see error message
k apply ../workloads/success.yaml # deploy successfully