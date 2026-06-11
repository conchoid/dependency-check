---
name: dependency-check-dockerfile-security-check
description: Analyzes Dockerfiles in the dependency-check repository for security vulnerabilities and provides improvement recommendations. Use when creating or modifying Dockerfiles to ensure they follow best practices like running as non-root, using specific tags, and optimizing package management.
options:
  --push: Push the built image to ECR and fetch official scan findings after passing local Trivy scan.
---

# dependency-check-dockerfile-security-check

This skill helps ensure that Dockerfiles in the dependency-check repository are secure and optimized.

## Triggers
- When the user asks to "check security" of a Dockerfile.
- When a new Dockerfile is created or an existing one is modified.
- When specifically asked to improve Dockerfile security.

## Workflow

1.  **Prepare Branch**: Create a new branch with the `-sec1` suffix to isolate security changes.
    ```bash
    git checkout -b $(git rev-parse --abbrev-ref HEAD)-sec1
    ```

### 1. Local Security Validation (Default)

2.  **Analyze**: Run the `check_security.cjs` script against the target Dockerfile to identify immediate issues.
    ```bash
    node scripts/check_security.cjs <path-to-dockerfile>
    ```
3.  **Consult Best Practices**: Refer to `references/best_practices.md` for the rationale and recommended code patterns for each finding.
4.  **Propose Changes**: Present the findings to the user and propose specific code changes to the Dockerfile.
5.  **Implement**: Once approved, apply the changes to the Dockerfile.
6.  **Build and Verify**: Build the Docker image locally.   (Note: Use the 'Suggested Tag' provided by the Analyze step if available)
    ```bash
    docker build --provenance=false -t <tag-name>-sec1 <context-dir>
    ```
7.  **Local Scan (Trivy)**: Perform a local vulnerability scan using Trivy. Repeat the "Implement" and "Build" steps until HIGH/CRITICAL findings are minimized.
    ```bash
    trivy image <tag-name>-sec1
    ```

### 2. Remote Validation and Delivery (with --push)

If the `--push` option is provided, proceed with the following steps after successful local validation:

1.  **Tag for ECR**: Add a specific tag for the project's ECR repository.
    ```bash
    docker tag <local-tag>-sec1 520300048555.dkr.ecr.us-west-2.amazonaws.com/codelift-plugins/tools/conchoid-dependency-check:<suggested-tag>-sec1
    ```
2.  **Push to ECR**: Push the secured image to the remote repository.
    ```bash
    docker push 520300048555.dkr.ecr.us-west-2.amazonaws.com/codelift-plugins/tools/conchoid-dependency-check:<suggested-tag>-sec1
    ```
3.  **Fetch Scan Findings**: Retrieve vulnerability scan results from ECR. Wait for the scan to complete before fetching.
    ```bash
    aws ecr wait image-scan-complete --profile Masato.Oikawa --region us-west-2 --repository-name codelift-plugins/tools/conchoid-dependency-check --image-id imageTag=<suggested-tag>-sec1 && \
    aws ecr describe-image-scan-findings --profile Masato.Oikawa --region us-west-2 --repository-name codelift-plugins/tools/conchoid-dependency-check --image-id imageTag=<suggested-tag>-sec1 > ./.sec/findings.json
    ```

## Key Security Areas
- **Non-Root Execution**: Ensure the `USER` instruction is used.
- **Image Pinning**: Use specific tags instead of `latest`.
- **Package Optimization**: Use `--no-install-recommends` and clean up `/var/lib/apt/lists/*`.
- **Layer Optimization**: Combine `RUN` commands where appropriate to reduce image size.
