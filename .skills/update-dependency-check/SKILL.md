---
name: update-dependency-check
description: Updates the Dependency-Check version in setup.sh. Use when asked to update Dependency-Check or when checking for latest releases on GitHub.
---

# update-dependency-check

This skill automates the process of checking for and applying updates to the Dependency-Check version used in the project's `setup.sh`.

## Workflow

1.  **Check Latest Version**: Fetch the latest release information from the official GitHub repository.
    ```bash
    # Use web_fetch tool to visit:
    # https://github.com/dependency-check/DependencyCheck/releases
    ```

2.  **Compare and Update**: If a newer version is available, use the provided script to update `setup.sh`.
    ```bash
    node scripts/update_version.cjs <latest-version>
    ```

3.  **Verify**: Ensure `setup.sh` has been updated correctly.
    ```bash
    grep 'VERSION=' setup.sh
    ```

## Resources
- **Scripts**: `scripts/update_version.cjs` - Updates the `VERSION` variable in `setup.sh`.
