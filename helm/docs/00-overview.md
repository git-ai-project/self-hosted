# Overview

This Helm package is a Kubernetes POC Git AI self-hosting stack.

Goals:

- One umbrella chart
- Full in-cluster stack
- Minikube-friendly defaults
- Storage backend switch between local PVC and cloud bucket modes
- Traffic entry switch between nginx ingress and Istio
- Portable base defaults with optional AWS/GCP/Azure overlay values
