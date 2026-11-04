# Exercises

## Exercise 1: Cluster

### Tasks

Create a cluster named `exam` with **1 server + 2 agents**, mapping port **8081** of the host to port 80 of the cluster.

### Expected results

- `kubectl get nodes` shows **3** nodes, all `Ready`.
- `docker ps` shows one container per node (3) and the load balancer.

```bash
k3d cluster delete practice
k3d cluster create exam --agents 2 -p "8081:80@loadbalancer"
```

- **server**: control-plane, manages the cluster (can also run Pods).
- **agent**: worker, only runs Pods (`ROLES <none>`).

## Exercise 2: Pod

### Tasks

1. Create a Pod named `web` with the `httpd` image.
2. Find **which node** the Pod is running on.
3. Create a Pod named `broken` with the image `nginx:doesnotexist`, and find the reason of the failure in Events.
4. Delete both Pods.

### Expected results

- 2: The name of one of the `k3d-exam-...` nodes.
- 3: `STATUS` becomes `ErrImagePull` or `ImagePullBackOff`, and Events show why the image cannot be pulled.

```bash
kubectl run web --image=httpd
kubectl describe pod web        # see "Node:"
kubectl get pods -o wide        # shortcut: NODE and IP columns

kubectl run broken --image=nginx:doesnotexist
kubectl describe pod broken
# Warning  Failed ... Failed to pull image "nginx:doesnotexist": ... docker.io/library/nginx:doesnotexist: not found

kubectl delete pod web
kubectl delete pod broken
```

- `not found`: the image `nginx` exists, but not the tag `doesnotexist`.
- Without a registry in the name, images are pulled from Docker Hub (`docker.io`).

## Exercise 3: Deployment

### Tasks

1. Write `confs/hello.yaml` from scratch: Deployment `hello`, image `hashicorp/http-echo`, text `Hi from hello`, **replicas 2**.
2. Delete one Pod.
3. **Edit the YAML** to set replicas to 4.
4. Delete the Deployment.

### Expected results

- 1: **2** Pods `Running`.
- 2: A new Pod is created immediately, back to **2** (one with a younger `AGE`).
- 3: **4** Pods (`deployment.apps/hello configured`, only 2 new Pods are added).
- 4: **All** Pods are deleted.

### Question

In step 2, which part of the new Pod's name changed, and which part stayed the same?

**Answer**

```
hello - 5c78887b8b - fzhqf   (deleted)
hello - 5c78887b8b - 2tw24   (new)
```

- `hello`: Deployment name (same)
- `5c78887b8b`: hash of the Pod template (same)
- `fzhqf` -> `2tw24`: random id of each Pod (changed)

Changing `replicas` does not change the template hash.
Changing the template (image, args, ...) creates a new hash and replaces the Pods one by one (**rolling update**).

## Exercise 4: Service

### Tasks

1. Add a Service to `hello.yaml` (separated by `---`). Service name `hello`, port 80.
2. Apply it, and check with port-forward (port **9100** of the VM) and curl.
3. **Break it**: change the Service's `selector` to `app: helo` (typo) and apply.
4. Check what changed with `kubectl describe svc hello`, then restore it.

### Expected results

- 2: `Hi from hello` is returned.
- 3-4: `Endpoints` is **empty** (the Service cannot find any Pod). After restoring, the Pods' IPs are shown.

```bash
kubectl describe svc hello      # see "Endpoints:"
kubectl get endpointslices      # all endpoints (describe may show "+ 1 more...")
```

> `containerPort` is only documentation: it does **not** change the port the app listens on.
> http-echo listens on 5678 by default. To use another port: `args: ["-text=...", "-listen=:5679"]`.

### Question

With replicas 4, how many IPs are listed in `Endpoints`?

**Answer**: 4 (one per Pod). A Service and its Pods are connected **only by labels**.

## Exercise 5: Ingress

### Tasks

1. Create another app `bye` (text `Bye from bye`) with a Deployment + a Service.
2. Write an Ingress with these rules:
   - `hello.local` -> hello
   - `bye.local` -> bye
   - anything else -> hello
3. Check the 3 cases with curl.
4. **Break it (1)**: delete only the `bye` Service, and curl `bye.local`.
5. **Break it (2)**: restore the `bye` Service, set the replicas of `bye` to **0**, and curl `bye.local`.

### Expected results

- 3: `hello.local` -> `Hi from hello`, `bye.local` -> `Bye from bye`, no host -> `Hi from hello` (port **8081**).
- 4: `Hi from hello`. Traefik ignores the `bye.local` rule (no Service), so the request falls to the **default rule**.
  Without a default rule, the result is `404 page not found`.
- 5: `no available server` (the Service exists, but no Pod).

> Be careful: in case 4 there is no error, but the **wrong app** answers.

## Final challenge

Delete the `exam` cluster and create it again.
Then restore hello, bye and the Ingress **only with `kubectl apply -f`**.
Success if step 3 of Exercise 5 works.
