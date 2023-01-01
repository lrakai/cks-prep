## GCP Provisioning

### Setup

1. Create a `infra/vars.sh` file with the following structure:

    ```sh
    #!/usr/bin/env bash
    export GOOGLE_PROJECT={replace_with_your_gcp_project_id}
    ```

2. Source the variables, create cluster key, and deploy:

    ```sh
    source infra/vars.sh
    ssh-keygen -t rsa -q -f "infra/key/cluster" -N ""
    terraform -chdir=infra init
    terraform -chdir=infra apply -auto-approve -var your_ip=$(curl -s ifconfig.me) -var project_id=$GOOGLE_PROJECT -var user=$USER
    echo -en "Connect with\n\n$(terraform -chdir=infra output -raw bastion_ssh_command)\n\n"
    ```

### Stop

```sh
gcloud compute instances stop control-plane worker1 worker2 bastion --project=$GOOGLE_PROJECT --zone=us-central1-a
```

### Start

```sh
gcloud compute instances start control-plane worker1 worker2 bastion --project=$GOOGLE_PROJECT --zone=us-central1-a
```

### Teardown

```sh
terraform -chdir=infra destroy -auto-approve -var your_ip=$(curl -s ifconfig.me) -var project_id=$GOOGLE_PROJECT -var user=$USER
```

## Domains

### 10% - Cluster Setup
- Use Network security policies to restrict cluster level access
    - network policy
- Use CIS benchmark to review the security configuration of Kubernetes components (etcd, kubelet, kubedns, kubeapi)
    - for kubeadm install, Knowing how to configure and secure the Kubernetes components is vital to use functionality such as admission controllers, RBAC and avoid a setup where --anonymous-auth was set to true.
- Properly set up Ingress objects with security control
    - Questions could include adding TLS to a previous ingress object or setting up an IngressClass
        - The TLS secret must contain keys named tls.crt and tls.key
- Protect node metadata and endpoints
    - maybe disable kubelet --read-only-port [deprecated]
    - Another use case might be a simple service check. There may be multiple services set up in the exam cluster, and then it is up to the student to weed out any unnecessary services and remove it. It will be worth brushing up on kubectl filtering capabilities and searching by spec.
- Minimize use of, and access to, GUI elements
    - There may be a question on the exam that requires changing NodePort services or proxying to a dashboard.
    - Another option could be minimizing the permissions of a Dashboard within the cluster.
- Verify platform binaries before deploying
    - `sha256sum`

### 15% - Cluster Hardening
- Restrict access to Kubernetes API
- Use Role Based Access Controls to minimize exposure
- Exercise caution in using service accounts e.g. disable defaults, minimize permissions on newly created ones
- Update Kubernetes frequently

### 15% - System Hardening
- Minimize host OS footprint (reduce attack surface)
- Minimize IAM roles
- Minimize external access to the network
- Appropriately use kernel hardening tools such as AppArmor, seccomp

### 20% - Minimize Microservice Vulnerabilities
- Setup appropriate OS level security domains 
    - e.g. using PSP, OPA, security contexts
- Manage kubernetes secrets
- Use container runtime sandboxes in multi-tenant environments (e.g. gvisor, kata containers)
    - 'runtimeClassName:' of PodSpec
        ```yaml
        apiVersion: node.k8s.io/v1beta1
        kind: RuntimeClass
        metadata:
            name: gvisor
        handler: runsc
        ```
    - 'runtimeClassName:' of PodSpec
        ```yaml
        spec:
            runtimeClassName: gvisor #<<--This must match the name of the runtime above
            containers:
        ```
- Implement pod to pod encryption by use of mTLS

### 20% - Supply Chain Security
- Minimize base image footprint
- Secure your supply chain: whitelist allowed image registries, sign and validate images
- Use static analysis of user workloads (e.g. kubernetes resources, docker files)
- Scan images for known vulnerabilities
    - trivy image --severity CRITICAL,HIGH {image}

### 20% - Monitoring, Logging and Runtime Security
- Perform behavioral analytics of syscall process and file activities at the host and container
 level to detect malicious activities
- Detect threats within physical infrastructure, apps, networks, data, users and workloads
- Detect all phases of attack regardless where it occurs and how it spreads
- Perform deep analytical investigation and identification of bad actors within environment
- Ensure immutability of containers at runtime
- Use Audit Logs to monitor access
    - https://kubernetes.io/docs/tasks/debug/debug-cluster/audit/