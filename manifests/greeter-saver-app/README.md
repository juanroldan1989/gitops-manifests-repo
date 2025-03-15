# Greeter Saver App

## Local environment

### 1. Provision database

```bash
docker run --name local-postgres \
  -e POSTGRES_USER=user \
  -e POSTGRES_PASSWORD=password \
  -e POSTGRES_DB=mydatabase \
  -p 5432:5432 \
  -d postgres:13-alpine
```

### 2. Setup `env` variables within App

Within `values.yaml` file, adjust localhost's IP:

```bash
...

- name: DATABASE_URL
  value: "postgresql://user:password@<local-ip>:5432/mydatabase"
```

- `<local-ip>` obtained through:

```
ifconfig
```

```bash
...
en0: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
...
	inet 192.168.178.131 netmask 0xffffff00 broadcast 192.168.178.255
	status: active
...
```

```
192.168.178.131
```

### 3. Provision Apps within K8S Cluster

#### Using `application` Helm chart

- Provision `name` app:

```bash
helm upgrade \
  --install name ./manifests/application \
  --namespace greeter-app \
  --values ./manifests/name-app/values.yaml
```

- Provision `greeting` app:

```bash
helm upgrade \
  --install greeting ./manifests/application \
  --namespace greeter-app \
  --values ./manifests/greeting-app/values.yaml
```

- Provision `greeter-saver` app:

```bash
helm upgrade \
  --install greeter-saver ./manifests/application \
  --namespace greeter-app \
  --values ./manifests/greeter-saver-app/values.yaml
```

#### Using `ArgoCD` apps

- Validate `argocd` and `argo-rollouts` are provisioned -> [steps](/argocd/README.md)

- Then provision apps:

```bash
kubectl apply -f argocd/apps/greeter-saver-app.yaml
kubectl apply -f argocd/apps/name-app.yaml
kubectl apply -f argocd/apps/greeting-app.yaml
```

### 4. Launch `greeter-saver` app

```bash
kubectl port-forward svc/greeter-saver 5008:5008 -n greeter-app
```

### 5. Access App

```bash
curl localhost:5008/greet

{"message":"Salutations, Charlie!"}
```

### 6. Validate data stored properly

```bash
docker exec -it local-postgres psql -U user -d mydatabase

psql (13.20)
Type "help" for help.

mydatabase=# SELECT * FROM "greetings";
 id |        message        |         created_at
----+-----------------------+----------------------------
  1 | Hey, Bob!             | 2025-03-15 12:37:23.400845
  2 | Hi, Daisy!            | 2025-03-15 12:37:24.197722
  3 | Hello, Eve!           | 2025-03-15 12:37:24.53659
  4 | Salutations, Eve!     | 2025-03-15 12:37:24.835507
  5 | Salutations, Daisy!   | 2025-03-15 12:37:25.076832
  6 | Greetings, Charlie!   | 2025-03-15 12:37:25.376727
  7 | Greetings, Daisy!     | 2025-03-15 12:37:25.629115
  8 | Hey, Daisy!           | 2025-03-15 12:37:25.821496
  9 | Hello, Alice!         | 2025-03-15 12:37:26.027783
 10 | Hello, Alice!         | 2025-03-15 12:37:26.333541
 11 | Salutations, Bob!     | 2025-03-15 12:37:26.547872
 12 | Greetings, Daisy!     | 2025-03-15 12:37:26.766079
 13 | Hey, Eve!             | 2025-03-15 12:37:27.032531
 14 | Greetings, Bob!       | 2025-03-15 12:37:27.218642
 15 | Salutations, Bob!     | 2025-03-15 12:37:27.401385
 16 | Salutations, Charlie! | 2025-03-15 12:37:44.923726
(16 rows)
```
