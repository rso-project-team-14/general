# Gateway API with Envoy instead of the nginx Ingress

Date: 2026-11-11 19:01:19 UTC

The nginx Ingress controller is not used, because it is no longer supported. The cluster entry point is a Kubernetes Gateway API `Gateway` with Envoy as the implementation, and `HTTPRoute` resources route `/` to the frontend and `/api/` to the services. TLS terminates at the gateway. The frontend container still serves its static files with its own nginx. Updated `plan.md` sections 1.3 (communication rules), 1.9, 1.10, 1.14 (frontend variant of the standard sections), and 2.1 (the bootstrap endpoint is not routed through the public gateway).
