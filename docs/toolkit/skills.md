# Skills — Slash Command Cheat Sheet

Quick reference for all slash commands available in the GameModding workspace.
Use these for structured, repeatable tasks. For open-ended exploration, spawn an agent instead.

---

## Project Management

| Skill | Description | Input | Output |
|-|-|-|-|
| `/new-project` | Create a new RE project with game metadata | Game name, engine type, game path | Project ID, initial directory scan |
| `/update-notes` | Add or update project notes | Project ID, notes text | Confirmation |
| `/export-findings` | Export all findings to a report | Project ID, format (md/json) | Formatted report file |

## Analysis

| Skill | Description | Input | Output |
|-|-|-|-|
| `/analyze-assembly` | Deep-dive into a .NET assembly | Assembly path or name | Type list, method signatures, references |
| `/analyze-game` | Auto-detect engine and scan game directory | Game directory path | Engine type, assembly list, asset summary |
| `/detect-engine` | Identify the game engine from files | Game directory path | Engine name and version |
| `/il2cpp-dump` | Run IL2CPP dumper and parse output | GameAssembly.dll + metadata path | Searchable type/method dump |
| `/search-assembly` | Text search across .NET assembly contents | Query string, optional assembly filter | Matching types, methods, strings |

## Hook Discovery

| Skill | Description | Input | Output |
|-|-|-|-|
| `/find-hooks` | Identify moddable methods in an assembly | Assembly path, target area (e.g. "combat") | Ranked list of hook candidates with rationale |
| `/trace-xrefs` | Follow cross-references from a function | Function name or address | Call graph (callers and callees) |
| `/find-references` | Find all references to an address or symbol | Address or symbol name | List of referencing locations |

## Memory Analysis

| Skill | Description | Input | Output |
|-|-|-|-|
| `/scan-value` | Start a new value scan in the target process | Value, data type | Initial result count |
| `/narrow-scan` | Refine scan results after value change | New value or change direction | Filtered result count and addresses |
| `/find-pointer` | Build a pointer chain to a known address | Target address, max depth | Pointer chain with offsets |
| `/aob-scan` | Scan for an array-of-bytes pattern | Hex pattern with wildcards | Matching addresses |
| `/watch-address` | Monitor an address for changes | Address, data type | Change log with timestamps and accessing code |

## Code Generation

| Skill | Description | Input | Output |
|-|-|-|-|
| `/generate-mod` | Generate a complete mod from findings | Project ID, mod framework, target findings | Source files, build instructions |
| `/generate-patch` | Create a Harmony prefix/postfix patch | Method signature, patch type, patch logic | C# source file |
| `/generate-trainer` | Build a Cheat Engine trainer | List of addresses with types and labels | .CT file or standalone trainer |
| `/generate-script` | Write a Frida interception script | Target function, hook behavior | JavaScript file |

---

## The Standard Pipeline

Most modding projects follow this sequence:

```
/new-project  -->  /analyze-assembly  -->  /find-hooks  -->  /generate-mod
     |                    |                      |                  |
  Register game     Understand code        Pick targets       Produce code
```

1. **`/new-project`** — Register the game, auto-detect engine, scan directories.
2. **`/analyze-assembly`** — Load the main game assembly, enumerate types and methods.
3. **`/find-hooks`** — Search for methods worth patching based on your goal.
4. **`/generate-mod`** — Produce a working mod using findings from previous steps.

For runtime-focused work, insert memory skills between steps 3 and 4:

```
/find-hooks  -->  /scan-value  -->  /narrow-scan  -->  /find-pointer  -->  /generate-trainer
```

---

## Skills vs Agents: When to Use Which

**Use a skill when:**
- The task is well-defined with clear input and output
- You want a repeatable, structured result
- The task maps to a single pipeline step
- You know exactly what you're looking for

**Spawn an agent when:**
- The task is exploratory ("figure out how combat works")
- Multiple tools need to be used iteratively based on intermediate results
- You need to make judgment calls about what to investigate next
- The task crosses multiple domains (analysis + memory + generation)

**Rule of thumb:** Skills are verbs (scan, generate, analyze). Agents are roles
(analyst, hunter, builder). If you can describe the task in one sentence with a
clear expected output, use a skill. If you need to say "figure out" or "explore",
use an agent.
