# Scene Manager & Asset Management (v0.3.0)

## Scene Manager
- Builds a read-only node inventory (name, class, layer, hidden/frozen state).
- Selects nodes by class or layer.
- Offers explicit hide-by-layer, isolate-nodes, and restoration of the pre-isolation visibility snapshot.
- Inventory does not rename, regroup, re-layer, or otherwise rewrite the scene.

## Asset Manager
- Enumerates Bitmaptexture references and checks whether each referenced file exists.
- Missing paths are reported only. No automatic relinking, path rewriting, or file copying.

## Cleanup Review
- Lists hidden nodes and scene materials not directly assigned to a scene node as review candidates.
- A material candidate may still be referenced by nested materials, maps, or external workflows; it is not proof of being unused.
- No delete operation is provided.

## Safety
All scans are non-destructive. Visibility commands in Scene Manager are explicit user actions and can be reversed with Unhide All. In-host validation remains required for each supported 3ds Max build.
