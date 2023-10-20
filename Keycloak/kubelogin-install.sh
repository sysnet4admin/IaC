#!/usr/bin/env bash

#  keycloak-loing-config 
mkdir ~/.keycloak
kubectl get clientconfig -n kube-public default -o yaml > ~/.keycloak/config

if [ ! -f "/usr/local/bin/kubelogin" ]; then
echo "install wrapper"
cat > "/usr/local/bin/kubelogin" <<'EOF'
#!/usr/bin/env bash

function kubelogin() {
    local vender="$(cat ~/.kube/config | grep current-context | cut -d ':' -f2 | grep gke)"

    if [ "$vender" != "" ]; then
        kubectl oidc login --cluster="hj-keycloak" --login-config="/Users/mz01-hj/.keycloak/config"
    else
        kubectl oidc-login get-token \
          --oidc-issuer-url=https://oncloud-2.site/realms/kubernetes \
          --oidc-client-id=k8s-auth \
          --oidc-client-secret=Sw37vsOW7GdPQMAbjPqfR1q3bhD7sdLa
    fi
}

kubelogin
EOF

sudo chmod 755 "/usr/local/bin/kubelogin"
echo "set permission executable all user and system."

else
    echo "kubelogin install already"
fi

