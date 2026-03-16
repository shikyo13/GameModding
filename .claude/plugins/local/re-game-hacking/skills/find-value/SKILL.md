---
name: find-value
description: "Guided memory scanning workflow — scan for game values, narrow results, set breakpoints, generate AOB signatures"
---

# /find-value — Find a Game Value in Memory

When the user runs `/find-value`, guide them through finding a specific game value using Cheat Engine.

## Required Input
- **Value description**: What the user wants to find (e.g., "gold", "health", "ammo")
- **Current value**: The current in-game value (if visible), OR indication that value is unknown
- **Value type hint**: Integer, float, or unknown (ask if not provided)

## Workflow

### Phase 1: Initial Scan
1. Confirm Cheat Engine is attached to the game process using `cheatengine:get_process_info`.
2. Determine scan parameters:
   - Known value: `scan_all` with `exact` scan type
   - Unknown value: `scan_all` with `unknown_initial_value`
   - For displayed integers, try `int32` first. If that fails, try `float`.
3. Run `cheatengine:scan_all` with appropriate parameters.
4. Report the result count.

### Phase 2: Narrow Down
5. Ask the user to change the value in-game (take damage, spend gold, etc.).
6. Run `cheatengine:next_scan` with the new value (or `decreased`/`increased` for unknown).
7. Repeat steps 5-6 until results are 1-5 addresses.
8. Use `cheatengine:get_scan_results` to retrieve candidates.

### Phase 3: Verify
9. Read each candidate with `cheatengine:read_integer` or `cheatengine:read_memory`.
10. Write a test value with `cheatengine:write_integer` to confirm the correct address.
11. Ask user to verify the in-game value changed.

### Phase 4: Find Accessing Code
12. Set a data breakpoint: `cheatengine:set_data_breakpoint` with type `write`.
13. Ask user to trigger a value change in-game.
14. Retrieve hits: `cheatengine:get_breakpoint_hits`.
15. Disassemble around each hit: `cheatengine:disassemble`.
16. Remove the breakpoint when done.

### Phase 5: Generate Signature
17. Use `cheatengine:generate_signature` on the accessing instruction.
18. Verify uniqueness with `cheatengine:aob_scan`.
19. If not unique, extend the pattern.

### Phase 6: Save Findings
20. Save the address finding: `re-orchestrator:save_finding` with type `address`.
21. Save the AOB pattern: `re-orchestrator:save_finding` with type `pattern`.
22. If a pointer chain is needed, offer to trace it.

## Tips
- If exact int32 scan finds nothing, try float (some games store "100" as 100.0f)
- If float scan finds nothing, try normalized values (e.g., 0.75 for 75%)
- For timers/cooldowns, use `decreased` scans while timer is running, `unchanged` when stopped
- Health bars without numbers: use `unknown_initial_value` then `decreased` after damage then `increased` after heal
