---
name: trace-to-code
description: "Map a memory address to source code — calculate RVA, identify the .NET method or native function, trace cross-references"
---

# /trace-to-code — Map Memory Address to Code

When the user runs `/trace-to-code`, trace a runtime memory address back to the corresponding source code.

## Required Input
- **Memory address**: The runtime address to trace (from CE breakpoint hits, scan results, etc.)
- **Context**: How the address was found (data breakpoint hit, scan result, etc.)

## Workflow

### Phase 1: Address Classification
1. Use `cheatengine:get_address_info` to determine which module the address belongs to.
2. Calculate the RVA: `address - module_base_address`.
3. Use `cheatengine:enum_modules` if needed to find the module base.
4. Report: module name, RVA, region type (code/data/heap).

### Phase 2: Code Identification

**If the address is in a .NET assembly (managed code):**
5. Use `re-orchestrator:enumerate_dotnet_methods` on the assembly to find which method contains this RVA (find the method whose RVA range contains the target).
6. Once the method is identified, use `re-orchestrator:disassemble_dotnet_method` to see the IL.
7. Use `re-orchestrator:enumerate_dotnet_fields` on the containing type for context.

**If the address is in a native binary:**
5. Use `ghidra:get_function_by_address` with the module-relative address.
6. Use `ghidra:decompile_function_by_address` for the pseudocode.
7. Use `cheatengine:find_function_boundaries` for the function extent.

### Phase 3: Cross-Reference Analysis

**For .NET methods:**
8. Search for the method name across the assembly using `re-orchestrator:search_dotnet_assembly`.
9. Look at the containing class's other methods for related functionality.

**For native functions:**
8. Use `ghidra:get_xrefs_to` to find callers.
9. Use `ghidra:get_xrefs_from` to find callees.
10. Decompile key callers to understand the call chain.

### Phase 4: Context Building
11. Use `cheatengine:disassemble` around the original address for native instruction context.
12. If from a data breakpoint, use `cheatengine:get_instruction_info` for register values.
13. Identify the data structure being accessed (field offsets, struct layout).

### Phase 5: Save Findings
14. Save the function finding: `re-orchestrator:save_finding` with type `function`.
15. Update project notes with the trace analysis.

## Output Format
Present a clear trace path: Address -> Module+RVA -> Function -> Class -> Purpose.
Include the decompiled/disassembled code for the identified function.
