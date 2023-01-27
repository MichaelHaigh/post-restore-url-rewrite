# Post Restore Container Image URL Rewrite

Astra Control Post Restore Hook that rewrites an image source URL.

* [Setup](#setup)
* [Restore](#restore)
* [Known Limitations](#known-limitations)

## Setup

First, create the sample application:

```text
$ kubectl apply -f sample-app.yaml 
namespace/demo created
service/demo-service created
deployment.apps/demo-deployment created
```

Next, create the Astra Control execution hook service account, role binding, and deployment:

```text
$ kubectl apply -f astra-hook-components.yaml 
serviceaccount/kubectl-ns-admin-sa created
rolebinding.rbac.authorization.k8s.io/kubectl-ns-admin-sa created
deployment.apps/astra-hook-deployment created
```

Next, protect the `demo` namespace with Astra Control (either with the UI or `actoolkit`):

```text
$ actoolkit list namespaces
+---------+--------------------------------------+------------------+------------------+--------------------------------------+
| name    | namespaceID                          | namespaceState   | associatedApps   | clusterID                            |
+=========+======================================+==================+==================+======================================+
| default | 756b10a5-7a94-4935-a574-7ca47779b21b | discovered       |                  | 72f18463-98f0-4bd2-b669-7d6bc80f8bf4 |
+---------+--------------------------------------+------------------+------------------+--------------------------------------+
| demo    | 15ce1002-addb-4f0f-a3e0-bd65fa4b87b4 | discovered       |                  | 72f18463-98f0-4bd2-b669-7d6bc80f8bf4 |
+---------+--------------------------------------+------------------+------------------+--------------------------------------+
$ actoolkit manage app demo demo 72f18463-98f0-4bd2-b669-7d6bc80f8bf4
{"type": "application/astra-app", "version": "2.1", "id": "60c6990a-9d99-41a4-a7a5-3f8e19dff94e", "name": "demo", "namespaceScopedResources": [{"namespace": "demo"}], "clusterScopedResources": [], "state": "discovering", "lastResourceCollectionTimestamp": "2023-01-27T15:22:35Z", "stateTransitions": [{"to": ["pending"]}, {"to": ["provisioning"]}, {"from": "pending", "to": ["discovering", "failed"]}, {"from": "discovering", "to": ["ready", "failed"]}, {"from": "ready", "to": ["discovering", "restoring", "unavailable", "failed"]}, {"from": "unavailable", "to": ["ready", "restoring"]}, {"from": "provisioning", "to": ["discovering", "failed"]}, {"from": "restoring", "to": ["discovering", "failed"]}], "stateDetails": [], "protectionState": "none", "protectionStateDetails": [], "namespaces": [], "namespaceMapping": [], "clusterName": "uscentral1-cluster", "clusterID": "72f18463-98f0-4bd2-b669-7d6bc80f8bf4", "clusterType": "gke", "metadata": {"labels": [], "creationTimestamp": "2023-01-27T15:22:35Z", "modificationTimestamp": "2023-01-27T15:22:35Z", "createdBy": "8146d293-d897-4e16-ab10-8dca934637ab"}}
```

Next, create the hooks source script with Astra Control (either with the UI or `actoolkit`):

```text
$ actoolkit create script container-image-change post-restore-hook.sh \
    -d "Script to change the container image path"
{"metadata": {"labels": [], "creationTimestamp": "2023-01-27T15:36:44Z", "modificationTimestamp": "2023-01-27T15:36:44Z", "createdBy": "8146d293-d897-4e16-ab10-8dca934637ab"}, "type": "application/astra-hookSource", "version": "1.0", "id": "02def8ea-acab-4216-8236-132d42ae0dda", "name": "container-image-change", "private": "false", "preloaded": "false", "sourceType": "script", "source": "IyEvYmluL3NoCgpSRUdJT04xPSJ1cy5nY3IuaW8iClJFR0lPTjI9ImV1Lmdjci5pbyIKCiMgTG9vcCB0aHJvdWdoIG5vbi0iYXN0cmEtaG9vay1kZXBsb3ltZW50IiBkZXBsb3ltZW50cwpkZXBsb3lzPSQoa3ViZWN0bCBnZXQgZGVwbG95bWVudHMgLW8ganNvbiB8IGpxIC1yICcuaXRlbXNbXS5tZXRhZGF0YSB8IHNlbGVjdCgubmFtZSAhPSAiYXN0cmEtaG9vay1kZXBsb3ltZW50IikgfCAubmFtZScpCmZvciBkIGluICR7ZGVwbG95c307IGRvCgogICAgIyBMb29wIHRocm91Z2ggdGhlIGNvbnRhaW5lcnMgd2l0aGluIGEgZGVwbG95bWVudAogICAgY29udGFpbmVyTmFtZXM9JChrdWJlY3RsIGdldCBkZXBsb3ltZW50IGRlbW8tZGVwbG95bWVudCAtbyBqc29uIHwganEgLXIgJy5zcGVjLnRlbXBsYXRlLnNwZWMuY29udGFpbmVyc1tdLm5hbWUnKQogICAgZm9yIGMgaW4gJHtjb250YWluZXJOYW1lc307IGRvCgogICAgICAgICMgR2V0IHRoZSBpbWFnZSBhbmQgaW1hZ2UgcmVnaW9uCiAgICAgICAgZnVsbF9pbWFnZT0kKGt1YmVjdGwgZ2V0IGRlcGxveW1lbnQgZGVtby1kZXBsb3ltZW50IC1vIGpzb24gfCBqcSAtciAtLWFyZyBjb24gIiRjIiAnLnNwZWMudGVtcGxhdGUuc3BlYy5jb250YWluZXJzW10gfCBzZWxlY3QoLm5hbWUgPT0gJGNvbikgfCAuaW1hZ2UnKQogICAgICAgIHJlZ2lvbj0kKGVjaG8gJHtmdWxsX2ltYWdlfSB8IGN1dCAtZCAiLyIgLWYgLTEpCiAgICAgICAgYmFzZV9pbWFnZT0kKGVjaG8gJHtmdWxsX2ltYWdlfSB8IGN1dCAtZCAiLyIgLWYgMi0pCgogICAgICAgICMgU3dhcCB0aGUgcmVnaW9uCiAgICAgICAgaWYgW1sgJHtyZWdpb259ID09ICR7UkVHSU9OMX0gXV0gOyB0aGVuCiAgICAgICAgICAgIG5ld19yZWdpb249JHtSRUdJT04yfQogICAgICAgIGVsc2UKICAgICAgICAgICAgbmV3X3JlZ2lvbj0ke1JFR0lPTjF9CiAgICAgICAgZmkKCiAgICAgICAgIyBSZWJ1aWxkIHRoZSBpbWFnZSBzdHJpbmcKICAgICAgICBuZXdfZnVsbF9pbWFnZT0kKGVjaG8gJHtuZXdfcmVnaW9ufS8ke2Jhc2VfaW1hZ2V9KQoKICAgICAgICAjIFVwZGF0ZSB0aGUgaW1hZ2UKICAgICAgICBrdWJlY3RsIHNldCBpbWFnZSBkZXBsb3ltZW50LyR7ZH0gJHtjfT0ke25ld19mdWxsX2ltYWdlfQogICAgZG9uZQpkb25l", "sourceMD5Checksum": "b5c2ee0f6479ca00e8c1122963a6ca5f", "description": "Script to change the container image path"}
```

Finally, create the post-restore execution hook with Astra Control (either with the UI or `actoolkit`):

```text
$ actoolkit list apps
+-----------+--------------------------------------+--------------------+-------------+---------+
| appName   | appID                                | clusterName        | namespace   | state   |
+===========+======================================+====================+=============+=========+
| demo      | 60c6990a-9d99-41a4-a7a5-3f8e19dff94e | uscentral1-cluster | demo        | ready   |
+-----------+--------------------------------------+--------------------+-------------+---------+
$ actoolkit list scripts
+------------------------+--------------------------------------+-------------------------------------------+
| scriptName             | scriptID                             | description                               |
+========================+======================================+===========================================+
| container-image-change | 02def8ea-acab-4216-8236-132d42ae0dda | Script to change the container image path |
+------------------------+--------------------------------------+-------------------------------------------+
```

```text
$ actoolkit create hook 60c6990a-9d99-41a4-a7a5-3f8e19dff94e post-restore-image-rewrite \
    02def8ea-acab-4216-8236-132d42ae0dda -o post-restore -c alpine-astra-hook
{"metadata": {"labels": [], "creationTimestamp": "2023-01-27T15:53:10Z", "modificationTimestamp": "2023-01-27T15:53:10Z", "createdBy": "8146d293-d897-4e16-ab10-8dca934637ab"}, "type": "application/astra-executionHook", "version": "1.2", "id": "84e4fb3f-da86-4ea2-8c7a-08ccdfda6222", "name": "post-restore-image-rewrite", "hookType": "custom", "matchingCriteria": [{"type": "containerName", "value": "alpine-astra-hook"}], "action": "restore", "stage": "post", "hookSourceID": "02def8ea-acab-4216-8236-132d42ae0dda", "arguments": [], "appID": "60c6990a-9d99-41a4-a7a5-3f8e19dff94e", "enabled": "true"}
```

Validate that there's a container match:

```text
$ actoolkit list hooks                                                                                                                                           
+--------------------------------------+----------------------------+--------------------------------------+------------------+
| appID                                | hookName                   | hookID                               | matchingImages   |
+======================================+============================+======================================+==================+
| 60c6990a-9d99-41a4-a7a5-3f8e19dff94e | post-restore-image-rewrite | 84e4fb3f-da86-4ea2-8c7a-08ccdfda6222 | alpine:latest    |
+--------------------------------------+----------------------------+--------------------------------------+------------------+
```

## Restore

First, view the current container image of the sample app:

```text
$ kubectl get -n demo deployment demo-deployment -o json | \
    jq '.spec.template.spec.containers[].image'
"us.gcr.io/google-containers/nginx"
```

Next, create an ad-hoc snapshot (can skip if a snapshot / protection policy already exists):

```text
$ actoolkit create snapshot 60c6990a-9d99-41a4-a7a5-3f8e19dff94e adhoc-demo-snap
{"type": "application/astra-appSnap", "version": "1.1", "id": "5d076272-40ed-4c77-ad30-0677de370a78", "metadata": {"createdBy": "8146d293-d897-4e16-ab10-8dca934637ab", "creationTimestamp": "2023-01-27T16:15:03Z", "modificationTimestamp": "2023-01-27T16:15:03Z", "labels": []}, "snapshotCreationTimestamp": "2023-01-27T16:15:03Z", "name": "adhoc-demo-snap", "state": "discovering"}
Starting snapshot of 60c6990a-9d99-41a4-a7a5-3f8e19dff94e
Waiting for snapshot to complete....Success!
```

Next, restore the application:

```text
$ actoolkit list snapshots -a demo
+--------------------------------------+-----------------+--------------------------------------+-----------------+----------------------+
| appID                                | snapshotName    | snapshotID                           | snapshotState   | creationTimestamp    |
+======================================+=================+======================================+=================+======================+
| 60c6990a-9d99-41a4-a7a5-3f8e19dff94e | adhoc-demo-snap | 5d076272-40ed-4c77-ad30-0677de370a78 | completed       | 2023-01-27T16:15:03Z |
+--------------------------------------+-----------------+--------------------------------------+-----------------+----------------------+
```

```text
$ actoolkit restore -b 60c6990a-9d99-41a4-a7a5-3f8e19dff94e \
    --snapshotID 5d076272-40ed-4c77-ad30-0677de370a78
Restore job submitted successfully
Background restore flag selected, run 'list apps' to get status
```

Verify the application was restored properly, and the container image has changed:

```text
$ kubectl -n demo get pods
NAME                                     READY   STATUS    RESTARTS   AGE
astra-hook-deployment-64d98c965d-rvbbh   1/1     Running   0          39s
demo-deployment-66676f958-m8swp          1/1     Running   0          33s
```

```text
$ kubectl get -n demo deployment demo-deployment -o json | \
    jq '.spec.template.spec.containers[].image'
"eu.gcr.io/google-containers/nginx"
```

## Known Limitations

There are two current known limitations to this setup:

1. It currently only works for deployments.  Other resources (replicat sets, stateful sets, etc.) should be very simple to add to the script with an additional for loop.
1. It currently only performs a dumb containder image swap between two regions, there is not any intelligence around kubernetes cluster <--> region mapping.
