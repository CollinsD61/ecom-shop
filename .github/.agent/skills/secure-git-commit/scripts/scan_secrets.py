import re
import os
import sys

# Common patterns for secrets
SECRET_PATTERNS = {
    "Generic API Key": r"(?i)(api[-|_]?key|secret|token|password|auth|access[-|_]?token)[:=]\s*['\"]([a-zA-Z0-9_\-\.]{16,})['\"]",
    "AWS Access Key": r"AKIA[0-9A-Z]{16}",
    "AWS Secret Key": r"(?i)aws_secret_access_key[:=]\s*['\"]([a-zA-Z0-9/+=]{40})['\"]",
    "GitHub Personal Access Token": r"ghp_[a-zA-Z0-9]{36}",
    "Stripe API Key": r"sk_live_[0-9a-zA-Z]{24}",
    "Google API Key": r"AIza[0-9A-Za-z\\-_]{35}",
    "Firebase API Key": r"AIza[0-9A-Za-z\\-_]{35}",
    "Heroku API Key": r"[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}",
    "Slack Webhook": r"https://hooks.slack.com/services/T[a-zA-Z0-9_]{8}/B[a-zA-Z0-9_]{8}/[a-zA-Z0-9_]{24}",
}

def scan_file(filepath):
    findings = []
    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
            for name, pattern in SECRET_PATTERNS.items():
                matches = re.finditer(pattern, content)
                for match in matches:
                    line_no = content.count('\n', 0, match.start()) + 1
                    findings.append({
                        "type": name,
                        "line": line_no,
                        "match": match.group(0)[:10] + "..." # Masking for safety in logs
                    })
    except Exception as e:
        print(f"Error reading {filepath}: {e}")
    return findings

def main():
    paths_to_scan = sys.argv[1:]
    if not paths_to_scan:
        # Default to staged files if no paths provided? 
        # For simplicity, just scan provided paths.
        return

    all_findings = {}
    for path in paths_to_scan:
        if os.path.isfile(path):
            file_findings = scan_file(path)
            if file_findings:
                all_findings[path] = file_findings
        elif os.path.isdir(path):
            for root, dirs, files in os.walk(path):
                for file in files:
                    # Basic exclusion
                    if any(x in root for x in ['.git', 'node_modules', 'vendor']):
                        continue
                    fpath = os.path.join(root, file)
                    file_findings = scan_file(fpath)
                    if file_findings:
                        all_findings[fpath] = file_findings

    if all_findings:
        print("CRITICAL: Secrets found!")
        for path, findings in all_findings.items():
            print(f"\nFile: {path}")
            for f in findings:
                print(f"  - {f['type']} at line {f['line']} ({f['match']})")
        sys.exit(1)
    else:
        print("No secrets detected.")
        sys.exit(0)

if __name__ == "__main__":
    main()
