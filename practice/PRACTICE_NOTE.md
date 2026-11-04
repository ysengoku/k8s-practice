# K8S practice

## Create a cluster with k3d

[K3d](https://k3d.io/stable/) is a lightweight wrapper to run k3s in Docker.
Each Kubernetes **node** is actually a **Docker container**, so a cluster can be created (and deleted) in seconds.

```bash
# Connect to the VM via ssh (from the directory where the Vagrantfile is located)
vagrant ssh

# Create a cluster, connecting port 8080 of the host (VM) to port 80 of the cluster.
# Port 80 of the cluster is where the Ingress (Traefik) listens.
k3d cluster create <cluster name> -p "8080:80@loadbalancer"
```

### Check the nodes

```bash
kubectl get nodes

# -- Output --
# NAME                    STATUS   ROLES           AGE   VERSION
# k3d-practice-server-0   Ready    control-plane   84m   v1.35.5+k3s1
```

- `STATUS Ready`: the node can run Pods.
- `ROLES control-plane`: this node manages the cluster (= K3s **server**).

The node is a Docker container:

```bash
docker ps
# -> k3d-practice-server-0 (node), k3d-practice-serverlb (load balancer for port 8080)
```

### Check the pods

`-A` (`--all-namespaces`) shows Pods in every namespace.

```bash
kubectl get pods -A

# -- Output --
# NAMESPACE     NAME                                      READY   STATUS      RESTARTS   AGE
# kube-system   coredns-8db54c48d-4kjdj                   1/1     Running     0          92m
# kube-system   helm-install-traefik-7flk9                0/1     Completed   1          92m
# kube-system   helm-install-traefik-crd-whvqk            0/1     Completed   0          92m
# kube-system   local-path-provisioner-5d9d9885bc-nfnh6   1/1     Running     0          92m
# kube-system   metrics-server-786d997795-wk8s4           1/1     Running     0          92m
# kube-system   svclb-traefik-b6a57a3b-nfrdt              2/2     Running     0          92m
# kube-system   traefik-9bcdbbd9-hj4xq                    1/1     Running     0          92m
```

Even without deploying anything, Kubernetes runs its own components in the `kube-system` namespace:

| Pod | Role |
| --- | --- |
| `coredns` | DNS inside the cluster (resolves Service names) |
| `traefik` | Ingress controller (used for host-based routing later) |
| `svclb-traefik` | Exposes Traefik on ports 80/443 of the node |
| `local-path-provisioner` | Provides storage for Pods |
| `metrics-server` | Collects CPU / memory usage (`kubectl top`) |
| `helm-install-traefik*` | One-time jobs that installed Traefik. `Completed` is normal |

### Manage the cluster

```bash
k3d cluster list                    # list clusters
k3d cluster stop <cluster name>     # stop (keeps the cluster)
k3d cluster start <cluster name>    # start again
k3d cluster delete <cluster name>   # delete everything
```

## Create and delete a pod

### Create a pod

```bash
# Create a pod called 'hello' from nginx image
kubectl run hello --image=nginx

# -- Output --
# pod/hello created

# Check if it's created
kubectl get pods

# -- Output --
# NAME    READY   STATUS    RESTARTS   AGE
# hello   1/1     Running   0          28s
```
- `READY 1/1`: 1 container out of 1 is ready.
- `STATUS Running`: the container is running

### Inspect the pod

```bash
kubectl describe pod hello # Show the details of the pod
kubectl logs hello # Show the logs of the container
```

### Delete the pod

```bash
# Delete the pod 'hello'
kubectl delete pod hello

# -- Output --
# pod "hello" deleted from default namespace

# Check if it's deleted
vagrant@practice:~$ kubectl get pods

# -- Output --
# No resources found in default namespace.
```

## Share files between host and VM

Synced folders with `rsync` require `rsync` on the **host**. It is not installed on the 42 host (no sudo), so files have to be uploaded manually.

```bash
# On the HOST (in the directory where the Vagrantfile is located)
# Upload the confs directory to /home/vagrant/confs in the VM
vagrant upload confs /home/vagrant/confs
```

Run it again every time a file in `confs/` is modified.

## Deployment

A **Deployment** (cf. [confs/app1.yaml](./confs/app1.yaml)) keeps the desired number of Pods running.
If a Pod is deleted, the Deployment creates a new one automatically (self-healing).

### Ceate a Deployment

```bash
# Create a Deployment from confs/app1.yaml (This creates Pods.)
kubectl apply -f confs/app1.yaml

# --Output --
# deployment.apps/app1 created

kubectl get deployments
# -- Output --
# NAME   READY   UP-TO-DATE   AVAILABLE   AGE
# app1   1/1     1            1           23s

kubectl get pods
# -- Output --
# NAME                    READY   STATUS    RESTARTS   AGE
# app1-754c878d98-8g8s2   1/1     Running   0          23s
```

Pod name: `<deployment name>-<template hash>-<random id>`.
The random id changes every time the Pod is recreated.

### Self-healing

```bash
# Delete the pod
kubectl delete pod app1-754c878d98-8g8s2

# -- Output --
# pod "app1-754c878d98-8g8s2" deleted from default namespace

kubectl get pods
# -- Output --
# NAME                    READY   STATUS    RESTARTS   AGE
# app1-754c878d98-mtxsg   1/1     Running   0          6s
```

A new Pod (`mtxsg`) was created: same Deployment, new random id, `AGE` reset.

### Scaling

Change `replica` in `confs/app1.yaml` from `1` to `3`, then upload it to VM.

```yaml
spec:
  replicas: 1  # Change to 3
```
```bash
# Create a Deployment from confs/app1.yaml (This creates Pods.)
kubectl apply -f confs/app1.yaml

kubectl get pods
# -- Output --
# NAME                    READY   STATUS    RESTARTS   AGE
# app1-754c878d98-bxtds   1/1     Running   0          4s
# app1-754c878d98-f7dpk   1/1     Running   0          4s
# app1-754c878d98-w6w6s   1/1     Running   0          4s

vagrant@practice:~$ kubectl get deployments
# -- Output --
# NAME   READY   UP-TO-DATE   AVAILABLE   AGE
# app1   3/3     3            3           7s
```

### Clean up

```bash
kubectl delete -f confs/app1.yaml
```

## Service

Pods' IP addresses change whenever they are recreated (scaling, failures, updates).

A **Service** provides a fixed endpoint (virtual IP + DNS name) for clients to reach the Pods.
It finds its Pods by **label** (`selector`), and load-balances between them if there are several.

```
client -> Service app1 (port 80) -> Pod app1-xxx (port 5678)
                                 -> Pod app1-yyy (port 5678)
```

### Create a Service with a command

```bash
# Create service
kubectl expose deployment app1 --port=80 --target-port=5678
# -- Output --
# service/app1 exposed
```
- `--port=80`: port of the Service (what clients call)
- `--target-port=5678`: port the container listens on (`containerPort` in the Deployment)

```bash
kubectl get svc
# -- Output --
# NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
# app1         ClusterIP   10.43.189.102   <none>        80/TCP    22s
#kubernetes   ClusterIP   10.43.0.1       <none>        443/TCP   21h
```
- `ClusterIP`: reachable only from inside the cluster

### Access the Service from the VM

```bash
# Forward VM port 9000 to the service port 80
kubectl port-forward svc/app1 9000:80
# -- Output --
# Forwarding from 127.0.0.1:9000 -> 80
# Forwarding from [::1]:9000 -> 80
# Handling connection for 9000
```

From another terminal:
```bash
vargrant ssh

curl localhost:9000
# --Output --
# Hello from app1
```

### Create a Service with YAML

Easier to reproduce and manage with git. A Deployment and a Service can be written in the same file, separated by `---` (cf. [confs/app2.yaml](./confs/app2.yaml)).

```bash
kubectl apply -f confs/app2.yaml

# -- Output --
# deployment.apps/app2 created
# service/app2 created
```

### Clean up

```bash
kubectl delete svc app1            # created with a command
kubectl delete -f confs/app2.yaml  # created with YAML (Deployment & Service)
```

## Ingress

An **Ingress** routes HTTP traffic from outside the cluster to Services, based on the **host name** or the **path**.
In k3s/k3d, the Ingress controller is **Traefik** (already running in `kube-system`).

```
curl localhost:8080
  -> k3d load balancer (8080 -> 80)  # set with -p "8080:80"
  -> Traefik (Ingress controller)
  -> Ingress rules (check the Host header)
  -> Service app1 / app2 / app3
  -> Pods
```

Manifest: [confs/ingress.yaml](./confs/ingress.yaml)

### Create Ingress

```bash
kubectl apply -f confs/ingress.yaml 
# -- Output --
# ingress.networking.k8s.io/my-ingress created

kubectl get ingress
# NAME         CLASS     HOSTS               ADDRESS      PORTS   AGE
# my-ingress   traefik   app1.com,app2.com   172.18.0.2   80      11m
```

### Test   
`app1.com` does not exist in DNS, so the `Host` header is set manually with `-H`.

```bash
curl -H "Host: app1.com" localhost:8080
# Hello from app1
curl -H "Host: app2.com" localhost:8080
# Hello from app2
curl localhost:8080
# Hello from app3
```

### Clean up

```bash
kubectl delete -f confs/ingress.yaml
```