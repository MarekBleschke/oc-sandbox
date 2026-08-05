---
description: "Code quality reviewer for bugs, regressions, test gaps, and maintainability. Read-only review. No edits."
model: {{MODEL_REVIEWER}}
mode: subagent
hidden: true
color: warning
permission:
  edit: allow
  bash:
    "*": allow
    "git push *": deny
    "git commit *": deny
---

