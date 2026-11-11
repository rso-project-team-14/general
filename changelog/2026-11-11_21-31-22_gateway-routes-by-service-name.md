# The gateway routes by service name and rewrites the path

Date: 2026-11-11 21:31:22 UTC

Every service has the same paths inside (for example `/api/v1/ping`), so the gateway needs a way to tell them apart. Added a short note to `plan.md` section 1.10: `HTTPRoute` resources route `/api/<service>/` to the matching service, where `<service>` is the short name from 1.3, and the gateway rewrites the path by removing the service name, so `/api/challenge/v1/ping` reaches the `challenge` service as `/api/v1/ping`. The services never see the service name. The base path convention in 1.6 now says the paths are the same in every service and that the gateway adds the service name. Stage 1: the frontend page calls the ping endpoint of each service through the gateway, with a pointer to 1.10. This addresses a possible problem raised in the review of the branch (the gateway routing was not defined). This follows a decision made in conversation.
