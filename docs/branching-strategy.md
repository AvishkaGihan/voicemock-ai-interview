# Branching Strategy

This repository follows the **GitHub Flow** branching strategy for streamlined development and deployment.

## Overview

GitHub Flow is a lightweight, branch-based workflow that supports teams and projects where deployments are made regularly.

## Main Branches

- **`main`**: The production-ready branch. All code in `main` is deployable.
- **`develop`**: The integration branch for ongoing development. Feature branches are merged here before going to `main`.

## Supporting Branches

### Feature Branches

- **Naming Convention**: `feature/<description>` or `feat/<description>`
- **Purpose**: Used for developing new features or bug fixes.
- **Creation**: Branch from `develop`
- **Merge**: Merge back to `develop` via Pull Request (PR)

### Release Branches

- **Naming Convention**: `release/<version>` (e.g., `release/v1.0.0`)
- **Purpose**: Prepare for a new production release.
- **Creation**: Branch from `develop` when ready for release
- **Merge**: Merge to `main` and tag the release

### Hotfix Branches

- **Naming Convention**: `hotfix/<description>`
- **Purpose**: Urgent fixes for production issues.
- **Creation**: Branch from `main`
- **Merge**: Merge to both `main` and `develop`

## Workflow

1. **Start a Feature**:
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feature/your-feature-name
   ```

2. **Develop and Commit**:
   - Make changes
   - Commit regularly with clear messages

3. **Create Pull Request**:
   - Push your feature branch
   - Create PR to merge into `develop`
   - Get code review and approval

4. **Merge to Develop**:
   - Squash merge or merge commit as appropriate
   - Delete the feature branch

5. **Release Process**:
   - When ready for release, create release branch from `develop`
   - Test thoroughly
   - Merge release branch to `main`
   - Tag the release
   - Deploy from `main`

## Commit Message Guidelines

Follow conventional commits:

- `feat:` for new features
- `fix:` for bug fixes
- `docs:` for documentation
- `style:` for formatting
- `refactor:` for code restructuring
- `test:` for testing
- `chore:` for maintenance

Example: `feat: add voice transcription feature`

## Pull Request Guidelines

- Provide clear description of changes
- Reference related issues
- Ensure CI/CD passes
- Get at least one approval before merging
- Use squash merge for feature branches

## Protection Rules

- `main` branch: Require PR reviews, CI passing
- `develop` branch: Require PR reviews for features

## Tools

- Use GitKraken or VS Code Git for branch management
- Enable branch protection in GitHub