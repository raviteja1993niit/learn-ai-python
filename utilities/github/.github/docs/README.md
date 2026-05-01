# Documentation Structure

This folder contains all project documentation organized by category.

## Folder Structure

```
.github/docs/
├── README.md                 # This file - documentation index
├── archives/                 # Archived documentation
├── diagrams/                 # Architecture and flow diagrams
├── reports/                  # Generated comparison reports
│   └── comparison-report.md  # Latest ATF vs Flow comparison
└── temp/                     # Temporary files for bot creation
    ├── README.md             # Temp folder documentation
    ├── *.md                  # Archived markdown reports
    └── debug*.txt            # Debug output files
```

## Quick Links

### Active Documentation
| Document | Location | Description |
|----------|----------|-------------|
| Project README | `/readme.md` | Main project documentation |
| Project Spec | `/pgs-acquirer-elavon-interface.md` | Service specification |
| Migration Guide | `/.github/dynamic-migration-prompt.md` | ATF to Flow migration guide |
| System Docs | `/.github/SYSTEM_DOCUMENTATION.md` | System architecture docs |

### Agent Documentation
| Document | Location | Description |
|----------|----------|-------------|
| Agent Index | `/.github/agents/MASTER_INDEX.md` | Master index for all agents |
| Report Analyzer | `/.github/agents/report-analyzer-agent.md` | Report analyzer agent guide |
| Test Fixer | `/.github/agents/test-fixer-agent.md` | Test fixer agent guide |

### Generated Reports
| Document | Location | Description |
|----------|----------|-------------|
| Comparison Report | `/flow_reports/comparison-report.md` | Latest ATF vs Flow field comparison |
| Flow Testcases | `/flow_reports/flow_testcases.csv` | Parsed Flow test cases |
| ATF Testcases | `/flow_reports/atf_testcases.csv` | Parsed ATF test cases |
| Gap Report (JSON) | `/flow_reports/test-comparison-gaps.json` | Machine-readable gap report |

### Archived Files
| Location | Description |
|----------|-------------|
| `/.github/docs/temp/` | Old reports and debug files preserved for bot creation |

## Documentation Guidelines

1. **Active docs** stay in their current locations
2. **Generated reports** go to `/flow_reports/`
3. **Archived/old files** go to `/.github/docs/temp/`
4. **Agent docs** stay in `/.github/agents/`

---
*Last updated: 2026-01-21*
