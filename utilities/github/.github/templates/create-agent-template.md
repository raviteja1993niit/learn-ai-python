```markdown
Hi Agent,

Generate an agent responsible for creating GitHub Copilot agents according to the client's requirements. Ensure the agent adheres to proper standards and best practices. Name the agent "meta-agent" and place it under #file:agents.

#file:agents/meta-agent

Agent Format (important sections):

- agent_name: meta-agent
- description: Short summary of agent responsibility
- version: Semantic version (e.g., 1.0.0)
- author: Contact or identity

Sections to include:

1. agent_name
	 - Unique identifier for the agent (e.g., meta-agent)
2. description
	 - One-line summary and key responsibilities
3. tools
	 - List of tools the agent may use. Example:
		 - code-editor (read/write project files)
		 - linter (static analysis)
		 - test-runner (execute unit tests)
		 - git (commit/push changes)
		 - ci (configure CI pipelines)
4. inputs
	 - Expected client inputs (requirements, constraints, repo link)
5. outputs
	 - Deliverables (agent code, tests, docs, manifest)
6. behavior
	 - Rules and best practices (security, code style, tests, minimal permissions)
7. triggers
	 - Invocation methods (CLI, API, webhook)
8. permissions
	 - Required scopes and least-privilege principles
9. examples
	 - Sample request and sample response
10. validation
	 - Checks to ensure produced agents meet standards (lint, tests, security scan)

Sample manifest (YAML):
```yaml
agent_name: meta-agent
description: "Generates GitHub Copilot agents per client requirements, enforcing standards and practices."
version: "1.0"
tools:
	- code-editor
	- linter
	- test-runner
	- git
	- ci
inputs:
	- requirements_document
	- repository_url
	- coding_standards
outputs:
	- agent_source_code
	- tests
	- documentation
	- deployment_manifest
behavior:
	- enforce_minimal_permissions: true
	- require_tests: true
	- run_linters: true
	- security_scans: true
triggers:
	- api_call
	- cli_command
permissions:
	- repo:write
	- actions:write
validation:
	- lint_passed
	- tests_passed
	- security_scan_passed
examples:
	request: |
		Create an agent that...
	response: |
		Generated agent at #file:agents/meta-agent
```

Place the resulting agent under #file:agents as a new folder/file named "meta-agent".
```