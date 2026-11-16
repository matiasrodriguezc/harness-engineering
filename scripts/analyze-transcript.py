"""Summarizes a `claude -p --output-format stream-json` transcript.

Usage: python3 analyze-transcript.py <transcript.jsonl>

Prints duration, turns, cost, how many actions the agent took before its first
code edit (rediscovery cost) and which files it read before editing.
"""
import json
import sys

EDIT_TOOLS = {"Edit", "Write", "MultiEdit", "NotebookEdit"}

lines = [json.loads(l) for l in open(sys.argv[1]) if l.strip()]
result = [d for d in lines if d.get("type") == "result"][-1]
tool_uses = [
    c
    for d in lines
    if d.get("type") == "assistant"
    for c in d["message"].get("content", [])
    if c.get("type") == "tool_use"
]

def is_edit(c):
    if c["name"] in EDIT_TOOLS:
        return True
    cmd = c["input"].get("command", "") if c["name"] == "Bash" else ""
    return any(s in cmd for s in ("cat >", "sed -i", "python3 - <<", "> src/", ">> src/"))

first_edit = next((i for i, c in enumerate(tool_uses) if is_edit(c)), len(tool_uses))
before = tool_uses[:first_edit]
reads = [c["input"].get("file_path", "") for c in before if c["name"] == "Read"]
bash_before = [c["input"].get("command", "")[:90] for c in before if c["name"] == "Bash"]

print(f"result: {result.get('subtype')}  turns: {result.get('num_turns')}  "
      f"duration: {result.get('duration_ms', 0) / 1000:.0f} s  cost: US${result.get('total_cost_usd', 0):.2f}")
print(f"total actions: {len(tool_uses)}  actions before the first edit: {first_edit}")
print("files read before editing:", [r.split("/")[-1] for r in reads])
print("commands before editing:")
for b in bash_before:
    print("  -", b)
