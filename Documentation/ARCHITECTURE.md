# Architecture

Asker Tools uses a small core with isolated feature modules. Core services must not depend on renderer-specific APIs. Integrations expose capability checks and adapters; modules consume those adapters only after availability is confirmed.

## Module contract

A module is a `.ms` file located one directory below `Modules/`. It may define a globally namespaced struct (prefix `AT_`) and should avoid changing global 3ds Max state during file load. Runtime actions should be explicit functions. Errors must be caught at module boundaries and sent to `AT_Logger`.

## Compatibility policy

The declared target is 3ds Max 2022–2026. 2027 is experimental until tested in-host. Corona and V-Ray compatibility is feature-specific and must be verified against actual renderer versions; detection alone is not certification.
