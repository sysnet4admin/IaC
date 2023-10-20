# init info for keycloak app & infra 
export GCP_PROJECT=dbgong-team-20200512
export GCP_ZONE=us-central1-c
export KUBE_CLUSTER=hj-keycloak
export CLUSTER_VERSION=1.27.5-gke.200

# static ingress IP. It will attach to Domain 
echo "Create Static external IP for Ingress"
gcloud compute addresses create keycloak \
  --global \
  --ip-version IPV4
echo "---"

# enable containerregistry
echo "Enable containerregistry"
gcloud services enable container.googleapis.com containerregistry.googleapis.com
echo "---"


# Deploy GKE cluster for keycloak
echo -e "Create GKE cluster $(CLUSTER_VERSION)"
gcloud container clusters create $KUBE_CLUSTER \
--num-nodes=3 \
--zone=${GCP_ZONE} \
--no-enable-autorepair \
--no-enable-autoupgrade \
--enable-identity-service \
--cluster-version="${CLUSTER_VERSION}" \
--release-channel=None \
--labels=keycloak=test
echo "---"

# Get GKE auth 
echo "GKE get-credentials"
gcloud container clusters get-credentials ${KUBE_CLUSTER} --project ${GCP_PROJECT} --zone ${GCP_ZONE}
echo "---"

# Deploy keycloak 
# notice: helm version should be 3.8.0 at least 
echo "Deploy keycloak to GKE"
echo "wait 5 sec for stable GKE" ; sleep 5 
helm install keycloak oci://registry-1.docker.io/bitnamicharts/keycloak \
--set auth.adminUser=admin \
--set auth.adminPassword=admin \
--set production=true \
--set proxy=edge
echo "---"
