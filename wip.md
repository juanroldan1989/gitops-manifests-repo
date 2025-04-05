# Work in progress

- Ephemeral environments setup within Pull Request.

- **Monitor and Observe**:

-- Set up comprehensive monitoring (e.g., `Prometheus`, `Grafana`, `ELK/EFK` stack) and logging to keep track of inter-service communications, performance, and failures. Setup in a way it can be re-used to any other applications.

-- [Charts reference](https://www.youtube.com/watch?v=cL0biQxREFI&list=WL&index=1&t=521s).

-- Generate built-in dashboards: `Example App - HPA Replicas`, `Example App - CPU Usage - Avg per Cluster`, `Example App - Memory Usage - Avg per Cluster`, `Example App - CPU Throttling`, and more.

-- Generate "templates" with different sets of dashboards.

- **Add several applications** that rely in N microservices. E.g.: uber-eats

- **Implemement ArgoCD Application Set**: 1 AppSet -> N Applications. To organise better the UI space and clarity on resources.

- **Adopt a Service Mesh**: For internal communications and to provide observability, security, and resilience among 50+ services, a service mesh can be invaluable.

- **Monitor Kubernetes Cloud** Costs: https://www.kubecost.com/install#show-instructions
