# Coordination disciplines and engineering rule engine

## Discipline adapter (0.1.0)
The adapter supports Architecture, Structure, Electrical, HVAC, Fire Fighting, Plumbing, Low Current, and Interior Elements. It does not infer a discipline from visual appearance or approximate names.

Classification precedence:
1. Explicit `AT_DISCIPLINE` user property, when a matching project mapping is registered.
2. Exact layer-name mapping.
3. Exact MAXScript class-name mapping.
4. Exact node-name mapping.

Unmapped elements are retained as `UNKNOWN` and listed in `lastUnclassified`. Each inventory record carries node handle ID, source/revision, bounds, warnings, and optional explicit clearance/service/installation envelopes. No envelope or engineering clearance is invented. The mapping registry is project configuration and must be populated by the user or an approved importer.

API: `registerMapping`, `clearMappings`, `inspect`, `setEnvelope`, `clear`.

## Rule engine (0.1.0)
Rule records are explicit and versionable. The approved source hierarchy is:
1. Mandatory laws/codes.
2. Consultant/authority approvals (within jurisdiction).
3. Manufacturer specifications.
4. Project/contract specifications.
5. Asker Tools defaults only when no higher approved rule exists.

Only approved rules are eligible for selection. A missing rule or only-unapproved rule set returns `RULE_MISSING` with a reason; no fallback numeric value is fabricated. Selection uses the highest-priority approved source among matching discipline pairs and check type. Jurisdiction is filtered when supplied.

API: `registerRule`, `removeRule`, `evaluate`, `evaluateBatch`, `clearEvaluations`, `clearAll`.

Rule values are data supplied by an authoritative project source; this module does not provide code tables or claim compliance by itself. Mandatory code violations remain non-overridable in downstream eligibility gates. Rule registration and lookup are deterministic and do not modify scene geometry.

## Validation boundary
These modules have been added as source-level implementation. MAXScript runtime behavior, actual user-property access, node layer behavior, and integration with real project metadata must be validated inside each supported 3ds Max version. No 3ds Max execution is claimed.
