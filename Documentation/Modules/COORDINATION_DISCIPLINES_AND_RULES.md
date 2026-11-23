# Coordination disciplines and engineering rule engine

## Discipline adapter (0.1.0)
The adapter supports Architecture, Structure, Electrical, HVAC, Fire Fighting, Plumbing, Low Current, and Interior Elements. It does not infer a discipline from visual appearance or approximate names.

Classification precedence:
1. Explicit `AT_DISCIPLINE` user property, when a matching project mapping is registered.
2. Exact layer-name mapping.
3. Exact MAXScript class-name mapping.
4. Exact node-name mapping.

Unmapped elements are retained as `UNKNOWN` and listed in `lastUnclassified`. Each inventory record carries node handle ID, source/revision, bounds, warnings, and optional explicit clearance/service/installation envelopes. The Clash Manager now applies the greater of the two elements' explicitly assigned required-clearance values, falling back to the scan default when neither side supplies one. Service and installation envelope geometry is stored as metadata but is not yet expanded into collision geometry. No envelope or engineering clearance is invented. The mapping registry is project configuration and must be populated by the user or an approved importer.

API: `registerMapping`, `clearMappings`, `inspect`, `setEnvelope`, `clear`.

## Rule engine (0.1.0)
Rule records are explicit and versionable. The approved source hierarchy is:
1. Mandatory laws/codes.
2. Consultant/authority approvals (within jurisdiction).
3. Manufacturer specifications.
4. Project/contract specifications.
5. Asker Tools defaults only when no higher approved rule exists.

Only approved rules are eligible for selection. The engine first identifies the highest-priority matching source; if that source is unapproved, lower-priority rules cannot silently override it and the result is `RULE_MISSING`. A missing rule returns a reason; no fallback numeric value is fabricated. Selection uses the highest-priority approved source among matching discipline pairs and check type. If any matching jurisdiction-scoped rule exists and the caller omits jurisdiction, evaluation returns `JURISDICTION_REQUIRED` rather than falling back to a global or lower-priority rule. When jurisdiction is supplied, only global rules and rules matching that exact jurisdiction are eligible. Within the same source tier, more specific discipline-pair and jurisdiction rules take precedence. Conflicting rules at equal priority return `CONFLICTING_SAME_PRIORITY_RULES`; the engine never chooses one arbitrarily.

API: `registerRule`, `removeRule`, `evaluate`, `evaluateClash`, `evaluateBatch`, `clearEvaluations`, `clearAll`. The Clash Manager scan joins exact-geometry clash records to the discipline inventory by stable node handle; unknown classifications explicitly block discipline-rule evaluation.

Rule values are data supplied by an authoritative project source; this module does not provide code tables or claim compliance by itself. Mandatory code violations remain non-overridable in downstream eligibility gates. Rule registration and lookup are deterministic and do not modify scene geometry.

## Validation boundary
These modules have been added as source-level implementation. MAXScript runtime behavior, actual user-property access, node layer behavior, and integration with real project metadata must be validated inside each supported 3ds Max version. No 3ds Max execution is claimed.


## Project rule manager UI (0.1.0)
The Rule Manager rollout provides explicit entry/edit-by-rule-ID, removal, authority/source metadata, jurisdiction, approval flag, mandatory flag, severity, numeric value/unit, and project-required check-type configuration. It ships no assumed building-code values. Rule entries should be transcribed from approved project/authority/manufacturer documents and retain their source name, revision, and jurisdiction. Unapproved higher-priority entries continue to block lower-priority fallback.


## Rule measurement units
Length-based check types (`CLEARANCE`, `MIN_CLEARANCE`, `SERVICE_CLEARANCE`, `INSTALLATION_CLEARANCE`) require an explicit numeric value and supported unit. The unit adapter converts tagged mm/cm/m/km/in/ft values through 3ds Max `units.decodeValue` into internal master units; `system`/ `master` explicitly means the caller already supplied master units. Unknown units or missing values produce `RULE_MISSING` and block simulation. Other check types currently return `CHECK_TYPE_VALIDATOR_NOT_IMPLEMENTED` and block simulation; a registered rule value alone is not treated as proof that access, fire-rating, structural, maintenance or installation checks passed.


## Discipline Manager UI (0.1.0)
The Discipline Manager provides exact mapping by user property, layer, class or node name. A valid `AT_DISCIPLINE` node user property is accepted directly when no explicit mapping exists; an invalid non-empty value blocks fallback classification. mapping source/revision; and per-element required clearance with explicit unit conversion. Service/installation envelope fields are currently stored as references/metadata only and are not yet expanded into 3D collision geometry. Mapping and envelope changes invalidate the previous clash scan and require a rescan before simulation.


Per-element envelope overrides can store three independent numeric clearances—general, service, and installation—entered in mm/cm/m/in/ft/system units and converted to 3ds Max master units. Service/installation envelope references may also be stored as metadata; those references are not yet converted into volumetric geometry. The numeric clearances participate conservatively in exact surface-distance checks.


The geometric clearance validator supports `CLEARANCE`, `SERVICE_CLEARANCE`, and `INSTALLATION_CLEARANCE`. All three use measured triangle-surface distance and explicit rule values; per-element general/service/installation clearance overrides are combined conservatively using the strictest applicable distance. Other check types remain blocked until a dedicated validator is implemented.
