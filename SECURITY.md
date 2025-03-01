# Security

Items to improve network security across cluster resources

- add readiness probe to check if the application is ready to serve traffic
- add liveness probe to check if the application is alive
- add pod budget quota to limit the number of pods that can be created

## `greeter` application

- add network policy to restrict traffic between pods
- greeting pod should only accept traffic from the greeter pod
- name pod should only accept traffic from the greeter pod
- greeting and name pod should not be able to communicate with each other
