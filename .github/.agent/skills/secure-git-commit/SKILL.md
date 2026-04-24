---
name: secure-git-commit
description: Use this skill whenever the user mentions committing code, pushing to GitHub, or saving changes to version control. It ensures that no sensitive data (API keys, secrets, environment variables) is leaked and performs a security audit based on OWASP Top 10 standards before the commit proceeds. Use this even if the user just says "commit these changes" to ensure a secure workflow.
---

# Secure Git Commit

This skill automates a secure workflow for committing code. It prevents the accidental leakage of secrets and ensures code quality through a security audit.

## Workflow

When the user asks to commit changes:

### 1. Identify Changes
First, identify the files to be committed.
- If the user specifies files, use those.
- If the user says "all changes", find modified/untracked files using `git status`.

### 2. Secret Scanning (Mandatory)
Before any commit, you MUST scan the changed files for secrets.
- Use the provided script: `python .github/.agent/skills/secure-git-commit/scripts/scan_secrets.py <file_paths>`
- If the script finds any secrets, **STOP IMMEDIATELY**.
- Report the findings to the user and ask them to remove the secrets or use environment variables/secret managers.
- **NEVER** commit a file that contains an unmasked secret unless the user explicitly confirms it's a false positive or intentional (e.g., test data).

### 3. Security Audit (OWASP Top 10)
Analyze the code changes against the **OWASP Top 10** vulnerabilities:
1.  **Injection**: Look for raw SQL queries, command execution using user input, etc.
2.  **Broken Authentication**: Check for hardcoded credentials, weak session management.
3.  **Sensitive Data Exposure**: Check for cleartext passwords, lack of encryption for PII.
4.  **XML External Entities (XXE)**: Look for insecure XML parsers.
5.  **Broken Access Control**: Look for missing authorization checks on sensitive routes/functions.
6.  **Security Misconfiguration**: Look for debug modes enabled in prod, default passwords, insecure headers.
7.  **Cross-Site Scripting (XSS)**: Look for unescaped user input rendered in HTML.
8.  **Insecure Deserialization**: Look for untrusted data being deserialized.
9.  **Using Components with Known Vulnerabilities**: Check for outdated or vulnerable dependencies (if `package.json`, `pom.xml`, etc., are modified).
10. **Insufficient Logging & Monitoring**: Ensure critical actions are logged.

### 4. Present Findings
Show a summary of the security audit to the user.
- **Example Report:**
  ```markdown
  ## Security Audit Report
  - **Secrets**: Clean (No API keys found)
  - **OWASP Audit**:
    - [XSS]: Found potential unescaped input in `user-profile.js:45`.
    - [Injection]: No issues found.
  ```

### 5. Execute Commit
Only after the user reviews the findings and gives the "OK", proceed with the commit:
1.  `git add <files>`
2.  `git commit -m "<descriptive_message>"` (Ask the user for a message or propose one based on the changes).
3.  `git push` (If the user requested pushing).

## Guidelines
- Be proactive. If you see a `.env` file being added to the commit, warn the user.
- Suggest using `.gitignore` for sensitive files.
- If the user is in a hurry, you can say: "I'll do a quick security scan before committing to keep your repo safe."

## Failure Modes
- If `git` is not initialized, tell the user to run `git init` first.
- If no changes are detected, inform the user.
