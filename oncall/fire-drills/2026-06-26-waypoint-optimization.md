# Fire Drill: Waypoint Optimization API

## Scenario

Fire drill for the Waypoint Optimization API service. Participants practice accessing relevant runbooks, documentation, repositories, and verifying cluster/pod health for the Waypoint Optimization API.

Reference links used during drill:

- Access checklist: https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/1950418249
- On-call runbook (PULNS): https://tomtom.atlassian.net/wiki/spaces/PULNS/pages/139536835
- Public API docs: https://developer.tomtom.com/waypoint-optimization/documentation/waypoint-optimization
- Source repository: https://github.com/tomtom-internal/routing-waypoint-optimization
- Feature examples (HTTP): https://github.com/tomtom-internal/routing-waypoint-optimization/blob/main/for_presentations/feature_examples.http
- Functional examples: https://github.com/tomtom-internal/routing-waypoint-optimization/tree/main/functional-examples

## Participants

<!-- Fill in during/after the drill -->

## Steps Performed

1. Verified access checklist at https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/1950418249
2. Reviewed on-call runbook at https://tomtom.atlassian.net/wiki/spaces/PULNS/pages/139536835
3. Checked pod status in the default [Kubernetes](https://kubernetes.io/) namespace and `waypoints` namespace:

```
adrian.pedziwiatr@pl1lxl-PW0KZ9F6:~$ kubectl get pod
NAME                                    READY   STATUS    RESTARTS   AGE
backend12-deployment-6b9f49884b-9f9lj   1/1     Running   0          4d14h
backend12-deployment-6b9f49884b-hlf4g   1/1     Running   0          2d23h
backend13-deployment-8594bcf496-hdqnl   1/1     Running   0          2d23h
backend13-deployment-8594bcf496-p2qr7   1/1     Running   0          4d14h
backend13-deployment-8594bcf496-xptgc   1/1     Running   0          2d23h
front12-deployment-c55c5c857-5vrwx      1/1     Running   0          4d14h
front12-deployment-c55c5c857-h9kd4      1/1     Running   0          2d23h
front13-deployment-64fcbd4d-52bnd       1/1     Running   0          4d14h
front13-deployment-64fcbd4d-6hgkf       1/1     Running   0          4d14h
front13-deployment-64fcbd4d-mffbx       1/1     Running   0          4d14h

adrian.pedziwiatr@pl1lxl-PW0KZ9F6:~$ kubectl get pod -n waypoints
NAME                                             READY   STATUS    RESTARTS   AGE
waypoints-waypoints-deployment-66d9775bb-7jf92   1/1     Running   0          2d23h
waypoints-waypoints-deployment-66d9775bb-mj7bd   1/1     Running   0          4d14h
```

4. Reviewed feature examples and functional examples from the repository.

## Issues Encountered

<!-- Fill in during/after the drill -->

## Lessons Learned

<!-- Fill in during/after the drill -->

## Action Items

<!-- Fill in during/after the drill -->
