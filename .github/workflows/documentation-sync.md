---
description: "Review changes pushed to main and update repository documentation when necessary."

on:
  workflow_dispatch:

  push:
    branches:
      - main
    paths-ignore:
      - "README.md"
      - "docs/**"
      - ".github/workflows/**"

engine: copilot

permissions:
  contents: read
  copilot-requests: write

checkout:
  fetch-depth: 0

tools:
  edit:
  bash:
    - "git:*"
    - "cat"
    - "jq:*"

safe-outputs:
  create-pull-request:
    base-branch: main
    title-prefix: "docs: "
    draft: true
    max: 1
    allowed-files:
      - "README.md"
      - "docs/**"
    protected-files:
      policy: blocked
      exclude:
        - "README.md"
---

# Keep the documentation synchronized with the main branch

Review the code changes introduced by the push that triggered this workflow and
determine whether the repository documentation must be updated.

## Language requirements

All content produced by this workflow must be written in English, including:

- Documentation changes
- Commit messages
- Pull request titles
- Pull request descriptions
- Explanations and summaries

Preserve existing technical terminology and the documentation style already used
by the repository.

## Determine the change scope

Use the GitHub push event payload and the Git history to identify the exact
commit range introduced by the current push.

Inspect the event payload when necessary and compare the `before` and `after`
commit SHAs.

Review only changes introduced by the triggering push, but inspect related
source files when additional context is necessary.

Do not treat documentation-only changes as evidence that another documentation
update is required.

## Review the documentation

Compare the current implementation against:

- `README.md`
- Existing files under `docs/`

Pay particular attention to changes involving:

- Command-line arguments and options
- Default values
- Authentication behavior
- Supported token or credential types
- Input and output formats
- Configuration
- Dependencies and installation requirements
- User-visible behavior
- Error messages
- Validation rules
- Rate limits
- Security considerations
- Usage examples
- Feature additions, removals, or behavioral changes

Check whether documented commands and examples still match the current
implementation.

## Decide whether an update is required

A documentation update is required only when the current documentation is:

- Incorrect
- Incomplete because of the new code
- Misleading after the new code
- Missing a user-visible behavior introduced by the change
- Describing behavior that has been removed or changed

Do not make changes merely to rephrase, reorganize, or restyle documentation
that is already accurate.

Do not invent functionality, requirements, limitations, or implementation
details.

## When no update is required

If the documentation is already accurate:

- Do not modify any file
- Do not create a commit
- Do not create a pull request
- Finish the workflow with a brief explanation of why no documentation update
  was necessary

## When an update is required

If documentation changes are necessary:

1. Modify only `README.md` and existing or new files under `docs/`.
2. Keep the patch minimal and directly related to the triggering code changes.
3. Preserve the structure and style of the existing documentation.
4. Ensure every statement is supported by the current implementation.
5. Verify all changed commands, options, paths, and examples against the code.
6. Review the final diff before creating the pull request.
7. Create exactly one draft pull request targeting `main`.

Do not modify:

- Source code
- Tests
- Dependency manifests
- Lock files
- Build configuration
- GitHub Actions workflows
- Agent instructions
- Security policies
- Any file outside `README.md` and `docs/`

## Pull request requirements

Use a concise English title describing the documentation update.

The pull request description must contain:

### Summary

A concise explanation of the documentation changes.

### Code changes that required documentation updates

A list connecting each documentation update to the relevant implementation
change.

### Validation

A description of how commands, options, behavior, and examples were verified
against the current code.

Do not claim that tests were executed unless they were actually executed.
