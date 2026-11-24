# ADR-002: Separate MCP service

**Status:** in review

Prompt on the Jobs must provide a MCP server to provide access to the prompt
library from existing agents such as [GovChat-NL](https://www.govchat-nl.nl) and
Copilot. This architecture design record documents the chosen architecture.

## Requirements

- *Must* use oauth2 authentication for all MCP access, using the same identity
  manager as the Prompt on the Job web applications.
- *Should* support the Skills protocol extension.
- *Nice to have* support for the Enterprise-Managed Authorization protocol
  extension.

## Decision

MCP is implemented as a separate service. The data is shared with Kik-OS; MCP
has read-only access to the PostgreSQL instance used by Kik-OS (or a replica).
For authentication MCP will use the same Keycloak instance (also see [001 IDM
architecture](./001-idm-architecture.md)). 

```mermaid
flowchart TD
   MCP
   I0["Identity Manager (keycloak)"]
   A[Agent]@{ shape: console}
   B[Browser]@{ shape: browser}
   W[Kik-OS]
   SQL[(Database)]

   A --> MCP
   MCP --> I0
   MCP --> SQL
   B --> W
   W --> SQL
   W --> I0
```

This architecture provides a lightweight MCP server that is easier to scale.
More importantly it can be build directly on the standard MCP Python SDK, giving
direct access to new MCP features.

## Consequences

Using a shared database results in tight coupling between the MCP service and
Kik-OS. Changes in the database schema need to be made reflect in both services
and deployed in sync.

## Rejected alternaives

### MCP service inside Kik-OS

Implementing a MCP service in Django is difficult. Existing integrations are
either long unmaintained, or still immature. The best current option is
[django-mcpz](https://django-mcpz.readthedocs.io/), which is a one-person
project and has not yet had a release.

Having MCP in the Kik-OS also makes it harder to scale separately. This can
be problematic since MCP is expected to have significantly more users.

