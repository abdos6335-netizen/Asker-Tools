from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
required = [
    'AskerTools.ms', 'Core/AT_Core.ms', 'Core/AT_Logger.ms',
    'Core/AT_Settings.ms', 'Core/AT_Compatibility.ms',
    'Modules/Diagnostics/AT_Diagnostics.ms',
    'Modules/SceneAudit/AT_SceneAudit.ms',
    'Modules/SceneManager/AT_SceneManager.ms',
    'Modules/Assets/AT_AssetManager.ms',
    'Modules/Cleanup/AT_Cleanup.ms',
    'Modules/Materials/AT_MaterialManager.ms',
    'Modules/Coordination/AT_SolutionEngine.ms',
    'Modules/Coordination/AT_CoordinationGeometryAdapter.ms',
    'Modules/Coordination/AT_ExactGeometryEngine.ms',
    'Modules/Coordination/AT_DisciplineAdapter.ms',
    'Modules/Coordination/AT_DisciplineManager.ms',
    'Modules/Coordination/AT_RuleEngine.ms',
    'Modules/Coordination/AT_RuleManager.ms',
    'Modules/Coordination/AT_UnitConversionEngine.ms',
    'Modules/Coordination/AT_CoordinationProjectStore.ms',
    'Modules/Coordination/AT_CoordinationSimulation.ms',
    'Modules/Coordination/AT_CoordinationSolutionGenerator.ms',
    'Modules/Coordination/AT_ClashManager.ms',
    'Modules/Coordination/AT_CoordinationGovernance.ms',
    'Modules/Coordination/AT_CoordinationIntegrations.ms',
    'Modules/Coordination/AT_CoordinationReports.ms',
    'Documentation/Modules/MATERIAL_MANAGER.md',
    'Documentation/Modules/SCENE_MANAGER.md',
    'Documentation/Modules/ASSET_MANAGER.md',
    'Documentation/Modules/COORDINATION_SOLUTION_ENGINE.md',
    'Documentation/Modules/COORDINATION_DISCIPLINES_AND_RULES.md',
    'Documentation/Modules/COORDINATION_SOLUTIONS_AND_SIMULATION.md',
    'Documentation/Modules/COORDINATION_REVIEW_AND_GOVERNANCE.md',
    'Documentation/Modules/COORDINATION_INTEGRATIONS_AND_REPORTS.md',
    'Tests/COORDINATION_ENGINE_QA.md',
    'Tests/AT_CoordinationSelfTests.ms',
]
for rel in required:
    path = ROOT / rel
    assert path.is_file(), f'Missing required file: {rel}'
    assert path.stat().st_size > 80, f'File unexpectedly small: {rel}'

for path in ROOT.rglob('*.ms'):
    source = path.read_text(encoding='utf-8')
    assert '\x00' not in source, f'NUL byte in {path}'
    assert source.count('(') == source.count(')'), f'Unbalanced parentheses in {path}'
    assert source.count('[') == source.count(']'), f'Unbalanced brackets in {path}'

checks = {
    'Modules/SceneAudit/AT_SceneAudit.ms': ['DUPLICATE_NAME', 'MISSING_BITMAP', 'ZERO_SCALE', 'fn scan', 'fn selectFinding'],
    'Modules/SceneManager/AT_SceneManager.ms': ['fn inventory', 'fn selectByClass', 'fn selectByLayer', 'fn isolateNodes'],
    'Modules/Assets/AT_AssetManager.ms': ['fn scan', 'doesFileExist', 'fn missing'],
    'Modules/Cleanup/AT_Cleanup.ms': ['UNASSIGNED_MATERIAL_CANDIDATE', 'HIDDEN_NODE', 'fn scan'],
    'Core/AT_Core.ms': ['version = "0.6.0"'],
    'Modules/Materials/AT_MaterialManager.ms': ['#filePostMerge', '#postImport', 'SHA256', 'AutoCollect', 'REV(?:ISION)?', 'centralizeBitmap', 'changeMapsFolder'],
    'Modules/Coordination/AT_SolutionEngine.ms': ['fn validateCandidate', 'INVALID_ROTATION_PARAMETERS', 'UNSUPPORTED_ACTION_TYPE', 'fn buildProposal', 'fn generateProposals', 'fn generateAndRank', 'fn validateProposal', 'fn evaluateProposal', 'fn evaluate', 'fn setWeights', 'SIMULATION_NOT_VALIDATED', 'CRITICAL_RULE_VIOLATION', 'REQUIRED_RULE_MISSING', 'INTRODUCES_NEW_CLASHES'],
    'Modules/Coordination/AT_CoordinationGeometryAdapter.ms': ['fn inspect', 'includeHidden:false', 'isSupportedNode node', 'GeometryClass', 'Shape', 'fn detectClashes', 'fn generateMoveCandidates', 'fn simulateAABBMove', 'AABB_CLEAR_ONLY_REQUIRES_EXACT_VALIDATION', 'simulationValidated = false'],
    'Modules/Coordination/AT_ExactGeometryEngine.ms': ['fn trianglesIntersect', 'axisThreshold:1.0e-12', 'if lengthSquared<=1.0e-24', 'if aa<=1.0e-24', 'if ee<=1.0e-24', 'INVALID_GEOMETRY_TOLERANCE', 'NEGATIVE_GEOMETRY_TOLERANCE_REJECTED', 'maxEdgeSquared<=1.0e-24', 'faceArea2<=1.0e-12*maxEdgeSquared', 'TINY_SEGMENT_POINT_DISTANCE_SCALE', 'TINY_PARALLEL_SEGMENT_OVERLAP_ZERO', 'local unitAxis=axis/axisLength', 'SAT_COPLANAR_OVERLAP', 'SAT_COPLANAR_SEPARATION', 'SAT_VERTEX_TOUCH', 'SAT_EDGE_TOUCH', 'SAT_NEAR_PARALLEL_SEPARATED', 'SAT_TINY_TRIANGLE_OVERLAP', 'SAT_HIGH_ASPECT_RATIO_OVERLAP', 'fn pointSegmentDistanceSquared', 'abs denom<=1.0e-12*aa*ee', 'PARALLEL_OVERLAPPING_SEGMENTS_ZERO_DISTANCE', 'PARALLEL_SEPARATED_SEGMENTS_DISTANCE', 'POINT_TO_SEGMENT_PERPENDICULAR_DISTANCE', 'POINT_TO_DEGENERATE_SEGMENT_DISTANCE', 'SKEW_SEGMENT_INTERIOR_DISTANCE', 'fn triangleDistanceSquared', 'fn inspectPair', 'minimumDistanceKnown=true', 'if result.minimumDistanceKnown then result.clearanceShortfall', 'fn rayHitDistance', 'SHARED_EDGE_RAY_HIT_INCLUSIVE', 'SHARED_VERTEX_RAY_HIT_INCLUSIVE', 'fn pointInsideClosedMesh', 'hitDistances', 'fn addEdgeCount', 'fn vertexLinksManifold', 'invalidFaceCount', 'NO_VALID_TRIANGLE_FACES', 'SOLID_CONTAINMENT_INTERFERENCE', 'CONTAINMENT_UNVERIFIED', 'minimumDistanceKnown', 'EXACT_MESH_INTERFERENCE', 'CLEARANCE_VIOLATION', 'fn detectClashes', 'fn detectClashesWithClearances', 'fn pairClearance', 'fn applyDisciplineMetadata', 'record.serviceClearance=element.serviceClearance', 'e.serviceClearance', 'e.installationClearance', 'fn pairRuleMetadata', 'ruleSeverity', 'AT_ExactPairClearanceRecord', 'pairOverrides:#()', 'requiredClearance=undefined'],
    'Modules/Coordination/AT_DisciplineManager.ms': ['fn refreshMappings', 'fn refreshInventory', 'fn parseClearance', 'fn displayClearance', 'Existing master units', 'edtServiceClearance', 'edtInstallationClearance', 'lblEnvelopeUnits', 'on lbInventory selected index do', 'fn removeMapping', 'btnRegister', '--SELECT--', 'Choose a discipline explicitly', 'btnApplyEnvelope', 'btnClearEnvelope', 'UNKNOWN'],
    'Modules/Coordination/AT_DisciplineAdapter.ms': ['fn removeMapping', 'ARCHITECTURE', 'STRUCTURE', 'ELECTRICAL', 'HVAC', 'FIRE_FIGHTING', 'PLUMBING', 'LOW_CURRENT', 'INTERIOR_ELEMENTS', 'DISCIPLINE_MAPPING_MISSING', 'NODE_USER_PROPERTY', 'INVALID_AT_DISCIPLINE_USER_PROPERTY', 'fn registerMapping', 'normalizedValue', 'fn clearEnvelope', 'mappingRevision=0', 'metadataRevision=0'],
    'Modules/Coordination/AT_CoordinationProjectStore.ms': ['fn save', 'fn load', 'System.Xml.XmlDocument', 'fileClass.Replace', 'IntegrationStates', 'restoreIntegrationToken', 'INVALID_STORED_INTEGRATION_STATE', 'ClashTracking', 'GovernanceAudit', 'UNSUPPORTED_PROJECT_STORE_SCHEMA', 'oldRuleRevision', 'DisciplineMappings', 'DisciplineEnvelopeOverrides', 'INVALID_STORED_DISCIPLINE_MAPPING', 'mapping.matchKind=toUpper mapping.matchKind', 'DUPLICATE_STORED_DISCIPLINE_MAPPING', 'DUPLICATE_STORED_RULE_', 'INVALID_STORED_DISCIPLINE_OVERRIDE_ID', 'DUPLICATE_STORED_DISCIPLINE_OVERRIDE', 'INVALID_STORED_DISCIPLINE_CLEARANCE', 'INVALID_STORED_SERVICE_CLEARANCE', 'INVALID_STORED_INSTALLATION_CLEARANCE', 'serviceClearance', 'installationClearance', 'INVALID_STORED_CLASH_TRACKING', 'AT_CoordinationGovernance.approvals=#()', 'AT_CoordinationSolutionGenerator.clear()', 'lastScanRuleRevision=-1', 'lastDisciplineInventory=#()', 'lastScanMeshes=#()', 'visibleClashIndices=#()', 'AT_DisciplineAdapter.clear()', 'lastDisciplineErrors=#()', 'lastGeometryErrors=#()', 'lastPairClearances=#()'],
    'Modules/Coordination/AT_RuleManager.ms': ['fn addRule', 'fn removeRule', 'fn show', 'btnRegister', 'btnSetRequired', 'Approved / verified source'],
    'Modules/Coordination/AT_UnitConversionEngine.ms': ['fn toSystemUnits', 'units.decodeValue', 'UNSUPPORTED_LENGTH_UNIT'],
    'Modules/Coordination/AT_RuleEngine.ms': ['valueInSystemUnits', 'CLEARANCE_VALUE_REQUIRED', 'CHECK_TYPE_VALIDATOR_NOT_IMPLEMENTED', 'SERVICE_CLEARANCE', 'INSTALLATION_CLEARANCE', 'AT_UnitConversionEngine.toSystemUnits', 'MANDATORY_CODE', 'AUTHORITY_APPROVAL', 'MANUFACTURER_SPEC', 'PROJECT_SPEC', 'ASKER_DEFAULT', 'HIGHEST_PRIORITY_RULE_NOT_APPROVED', 'CONFLICTING_SAME_PRIORITY_RULES', 'checkType:checkType', 'validDiscipline', 'validSeverity', 'rule.sourceName==""', 'rule.checkType=toUpper rule.checkType', 'rule.jurisdiction=toUpper rule.jurisdiction', 'dA=toUpper dA', 'fn evaluateBatch', 'fn evaluateClash', 'recordResults:true', 'recordResult:true', 'if recordResults do append lastEvaluations missing', 'fn setRequiredCheckTypes', 'registryRevision+=1', 'REQUIRED_CHECK_TYPES_NOT_CONFIGURED', 'DISCIPLINE_CLASSIFICATION_REQUIRED'],
    'Modules/Coordination/AT_CoordinationSimulation.ms': ['fn cloneTranslatedMesh', 'copy.isClosed=source.isClosed', 'copy.serviceClearance=source.serviceClearance', 'fn cloneRotatedMesh', 'copy.installationClearance=source.installationClearance', 'fn simulateAction', 'clash.ruleSeverity=="CRITICAL"', 'BLOCKED_CRITICAL_RULE', 'pairOverrides:AT_ClashManager.lastPairClearances', 'fn simulateTranslation', 'fn simulateRotation', 'INVALID_ROTATION_PARAMETERS', 'ruleRevision=AT_RuleEngine.registryRevision', 'copy.requiredClearance', 'pairRequired', 'sourceTransform', 'sourcePivot', 'INVALID_OFFSET_VECTOR', 'EXACT_GEOMETRY_SIMULATION_PASSED', 'NEW_CLASHES_INTRODUCED', 'TARGET_CLASH_ID_REQUIRED', 'TARGET_CLASH_REMAINS', 'BLOCKED_RULE_MISSING', 'BLOCKED_RULE_CHECKS_NOT_SUPPLIED', 'BLOCKED_UNVERIFIED_GEOMETRY', 'BLOCKED_STALE_SCENE', 'INVALID_REQUIRED_CLEARANCE', 'ROTATION_ANGLE_OUT_OF_RANGE', 'ROTATION_PIVOT_MISMATCH', 'AT_ClashManager.validateCurrentScene'],
    'Modules/Coordination/AT_CoordinationSolutionGenerator.ms': ['fn generateTranslations', 'fn generateRotations', 'ROTATION_ANGLE_OUT_OF_RANGE', 'abs angle<=180.0', 'fn generateAllAlternatives', 'actionType="ROTATE"', 'separationOffset', 'requiresEngineeringApproval=true'],
    'Modules/Coordination/AT_ClashManager.ms': ['fn load', 'fn counts', 'fn selectClash', 'fn setTracking', 'fn getTracking', 'fn clashLabel', 'fn countsLabel', 'fn filteredClashIndices', 'fn refreshClashList', 'fn selectVisibleClash', 'ddlStatusFilter', 'statusFilter', 'fn disciplineInventoryMatches', 'fn meshInventoryMatches', 'fn validateCurrentScene', 'DISCIPLINE_METADATA_CHANGED_RESCAN_REQUIRED', 'SCENE_GEOMETRY_CHANGED_RESCAN_REQUIRED', 'RULES_OR_JURISDICTION_CHANGED_RESCAN_REQUIRED', 'AT_CoordinationSimulation.clear(); AT_RuleEngine.clearEvaluations()', 'lastPairClearances', 'lastRuleMissingPairs', 'AT_ExactPairClearanceRecord', 'recordResults:false', 'valueInSystemUnits', 'fn approveAlternative', 'fn applyAlternative', 'fn rollbackTransaction', 'btnRollback', 'edtRollbackTransactionId', 'edtRollbackReason', 'fn rankAlternatives', 'setRequiredCheckTypes', 'btnSetChecks', 'edtJurisdiction', 'btnFilter', 'ddlSeverityFilter', 'ddlDisciplineFilter', 'edtClashSearch', 'btnExportClashes', 'btnExportGeometryErrors', 'btnExportDisciplineErrors', 'btnExportMissing', 'btnExportTracking', 'btnExportAudit', 'btnExportApprovals', 'btnExportProposals', 'btnSelfTests', 'AT_Core.root+"\\Tests\\AT_CoordinationSelfTests.ms"', 'AT_CoordinationSelfTests.run()', 'btnRules', 'btnDisciplines', 'btnSaveProject', 'btnLoadProject', 'fn scan', 'INVALID_REQUIRED_CLEARANCE', 'AT_UnitConversionEngine.clearErrors()', 'fn show', 'lblRuleMissing', 'lblGeometryErrors', 'lblDisciplineErrors', 'btnGenerate', 'btnSimulate', 'btnApprove', 'btnApply', 'btnSave', 'UNDER_REVIEW', 'Detect Exact Mesh Clashes', 'ddlSeverityFilter.selection=1', 'ddlDisciplineFilter.selection=1', 'ddlStatusFilter.selection=1', 'AT_DisciplineAdapter.inspect'],
    'Modules/Coordination/AT_CoordinationGovernance.ms': ['fn approve', 'fn sameStringSet', 'fn candidateMatchesSimulation', 'APPROVAL_BLOCKED_SIMULATION_IDENTITY_MISMATCH', 'not candidate.requiresEngineeringApproval', 'consumed=false', 'a.consumed', 'APPROVAL_CONSUMED', 'elementId:simulation.movingElementId', 'expectedId!=a.elementId', 'AT_SolutionEngine.buildProposal candidate', 'AT_SolutionEngine.evaluateProposal proposal', 'approvedNode.objectTransform!=simulation.sourceTransform', 'AT_ClashManager.validateCurrentScene', 'fn applyAction', 'fn applyTranslation', 'fn applyRotation', 'fn rollback', 'FAILED_ROLLED_BACK', 'APPLY_BLOCKED_STALE_SCENE', 'APPLY_BLOCKED_RULES_CHANGED', 'ROLLBACK_BLOCKED_SCENE_CHANGED', 'tx.nodeRef.objectTransform!=tx.afterObjectTransform', 'objectTransform!=a.sourceTransform', 'afterObjectTransform'],
    'Modules/Coordination/AT_CoordinationIntegrations.ms': ['fn register', 'PROVIDER_REVISION_CHANGED', 'fn exchange', 'SOURCE_REVISION_REQUIRED', 'CAPABILITY_NOT_SUPPORTED', 'REVISION_CONFLICT', 'expectedPreviousRevision'],
    'Tests/AT_CoordinationSelfTests.ms': ['fn run', 'OVERLAPPING_BOXES', 'TRANSLATION_CANDIDATE_COUNT', 'PAIR_RULE_SEVERITY_PROPAGATION', 'CLEARANCE_VIOLATION', 'SERVICE_CLEARANCE_ENFORCED', 'INSTALLATION_CLEARANCE_ENFORCED', 'CLOSED_SOLID_CONTAINMENT', 'OPEN_MESH_CONTAINMENT_UNVERIFIED', 'ROTATION_CANDIDATE_COUNT', 'ROTATION_CANDIDATE_METADATA', 'ROTATION_SNAPSHOT_NON_DESTRUCTIVE', 'STALE_GEOMETRY_SNAPSHOT_DETECTED', 'RISK_NOT_ASSESSED_EXCLUDED_FROM_SCORE', 'APPROVAL_SIMULATION_IDENTITY_MATCH', 'APPROVAL_REJECTS_TAMPERED_RESOLUTION_SET', 'APPROVAL_REJECTS_TAMPERED_NEW_CLASH_SET', 'UNAPPROVED_HIGHER_PRIORITY_BLOCKS_FALLBACK', 'SAME_PRIORITY_RULE_CONFLICT', 'savedRuleRevision'],
    'Modules/Coordination/AT_CoordinationReports.ms': ['fn buildClashRows', 'fn buildProposalRows', 'fn buildClearanceRows', 'fn buildDisciplineRows', 'AT_ClashManager.severityFor c', 'fn buildGeometryErrorRows', 'fn buildDisciplineErrorRows', 'fn buildRuleMissingRows', 'fn buildTrackingRows', 'fn buildApprovalRows', 'Consumed', 'item.elementId', 'riskAssessment', 'fn buildRevisionRows', 'fn buildAuditRows', 'fn buildCriticalRows', 'fn exportCSV', 'fn htmlEscape', 'fn buildHTML', 'fn buildFullReportSections', 'fn exportHTML', 'fn exportFullHTML', 'System.IO.StreamWriter', 'System.Text.UTF8Encoding', 'csvEscape'],
}
for rel, tokens in checks.items():
    source = (ROOT / rel).read_text(encoding='utf-8')
    for token in tokens:
        assert token in source, f'Missing expected marker {token!r} in {rel}'

print(f'PASS: {len(required)} required files; {len(list(ROOT.rglob("*.ms")))} MAXScript files validated.')
