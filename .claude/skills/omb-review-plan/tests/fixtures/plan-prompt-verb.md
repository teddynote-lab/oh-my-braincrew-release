## Plan: Interactive CLI Tool

### Context
This plan builds a CLI tool that will prompt the user for input at various
stages. The tool will show a prompt dialog to collect configuration values
before starting the pipeline.

### Tasks
| # | Task | Agent | Deliverable |
|---|------|-------|-------------|
| 1 | Build interactive input handler | executor | `cli/input.py` |
| 2 | Add prompt dialog for config | executor | `cli/config_prompt.py` |
