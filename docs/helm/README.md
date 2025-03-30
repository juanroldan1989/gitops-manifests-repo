# Manifests

There are 2 ways to provision Kuberentes applications:

## 1. Helm

1. Create namespace for application's resources:

```bash
kubectl create ns my-sample-app
```

2. Provision resources using Helm chart:

```bash
helm install <chart-instance> <chart-folder> -f <custom-values> --namespace <namespace>
helm install my-sample-app ./manifests/base-application -f manifests/my-sample-app/values.yaml --namespace my-sample-app

NAME: my-sample-app
LAST DEPLOYED: Mon Mar  3 21:04:07 2025
NAMESPACE: my-sample-app
STATUS: deployed
REVISION: 1
TEST SUITE: None
```

```bash
helm list -n my-sample-app
NAME      	NAMESPACE 	REVISION	UPDATED                            	STATUS  	CHART            	APP VERSION
my-sample-app	my-sample-app	1       	2025-03-03 21:04:07.29335 +0100 CET	deployed	application-0.1.0	1.16.0
```

3. Validate resources were provisioned properly:

```bash
kubectl get all -n my-sample-app
NAME                        READY   STATUS    RESTARTS   AGE
pod/name-5fbb575f5b-455th   1/1     Running   0          42s
pod/name-5fbb575f5b-mwxrt   1/1     Running   0          42s

NAME           TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
service/name   ClusterIP   10.96.167.182   <none>        5001/TCP   42s

NAME                   READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/name   2/2     2            2           42s

NAME                              DESIRED   CURRENT   READY   AGE
replicaset.apps/name-5fbb575f5b   2         2         2       42s

NAME                                       REFERENCE         TARGETS              MINPODS   MAXPODS   REPLICAS   AGE
horizontalpodautoscaler.autoscaling/name   Deployment/name   cpu: <unknown>/80%   2         5         2          42s
```

4. Remove resources:

```bash
helm uninstall my-sample-app -n my-sample-app
release "my-sample-app" uninstalled
```

```bash
kubectl get all -n my-sample-app
No resources found in my-sample-app namespace.
```

## 1. ArgoCD Applications

Use `ArgoCD` application to provision your applications within the cluster.

Follow the steps in the [ArgoCD setup guide](/argo/ARGOCD.md)
