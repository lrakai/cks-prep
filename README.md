### 10% - Cluster Setup
- Use Network security policies to restrict cluster level access
    - network policy
- Use CIS benchmark to review the security configuration of Kubernetes components (etcd, kubelet, kubedns, kubeapi)
    - for kubeadm install, Knowing how to configure and secure the Kubernetes components is vital to use functionality such as admission controllers, RBAC and avoid a setup where --anonymous-auth was set to true.
- Properly set up Ingress objects with security control
    - Questions could include adding TLS to a previousingress object or setting up an IngressClass
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
- Setup appropriate OS level security domains e.g. using PSP, OPA, security contexts
- Manage kubernetes secrets
- Use container runtime sandboxes in multi-tenant environments (e.g. gvisor, kata containers)
    - 'runtimeClassName:' of PodSpec
- Implement pod to pod encryption by use of mTLS

### 20% - Supply Chain Security
- Minimize base image footprint
- Secure your supply chain: whitelist allowed image registries, sign and validate images
- Use static analysis of user workloads (e.g. kubernetes resources, docker files)
- Scan images for known vulnerabilities

### 20% - Monitoring, Logging and Runtime Security
- Perform behavioral analytics of syscall process and file activities at the host and container
 level to detect malicious activities
- Detect threats within physical infrastructure, apps, networks, data, users and workloads
- Detect all phases of attack regardless where it occurs and how it spreads
- Perform deep analytical investigation and identification of bad actors within environment
- Ensure immutability of containers at runtime
- Use Audit Logs to monitor access