# Release Model

This repository follows the Lightning IT shared release and quality model.

## Repository Classification

- Repository: `packer-vsphere-template-sources`
- Type: `packer_template`
- Release type: `none`
- Artifact type: `packer_template`
- Visibility: `public`
- Release evidence: `disabled`
- Heavy Incus release validation: `not required`

## Branch Flow

- `develop` is the integration branch for normal work, Renovate updates, and shared-assets-lit synchronization.
- `main` is the protected release branch.
- This repository does not publish release artifacts; `main` still represents the protected stable branch.
- A `develop` to `main` promotion PR is created automatically when releasable changes exist.
- The `develop` to `main` PR may auto-merge only after current-revision Copilot review, required checks, and conversation resolution.
- After `main` changes, a `main` to `develop` backmerge PR is created or updated automatically.
- Backmerge PRs may auto-merge only when required checks are green and there are no conflicts.

## Mandatory Quality Gates

- Required profiles: `pre-commit, packer-fmt, packer-validate`.
- OS matrix: `ubuntu-latest`.
- Product/runtime matrix: `rhel-8, rhel-9, rhel-10, ubuntu-24.04, ubuntu-26.04, vsphere`.
- Fork pull requests run validation without publishing credentials.
- Publishing secrets are available only to trusted `main` release workflows.
- GitHub token permissions must stay least-privilege for each workflow.

## Packer Template Release

- CI validates Packer formatting, template syntax, and sanitized variable examples.
- Image builds that require infrastructure credentials run only in trusted workflows.
- Template sources may reference private media or credentials only through runtime inputs and secrets.

## Release Evidence

Release evidence is disabled because this repository does not publish release artifacts. Evidence records the repository name, repository type, version, tag, commit SHA, workflow run, tested matrix combinations, passed/failed/skipped jobs, built artifacts, published artifacts, changelog link, security scan result, and SBOM/provenance/signature links when available.

Evidence files must not contain tokens, credentials, private inventory values, or secret material.
