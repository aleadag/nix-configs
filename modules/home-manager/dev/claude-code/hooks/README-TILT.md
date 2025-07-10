# Tilt/Starlark Support in Claude Code Hooks

This document describes the Tilt/Starlark support added to the Claude Code smart hooks.

## Overview

The smart-lint and smart-test hooks now automatically detect and handle Tilt projects, providing:

1. **Automatic Detection**: Recognizes projects with Tiltfiles
2. **Buildifier Integration**: Uses Google's official Starlark linter if available
3. **Custom Linting**: Runs project-specific linters if present
4. **Test Support**: Runs Tiltfile tests using various methods
5. **Security Checks**: Detects hardcoded secrets and AWS account IDs

## How It Works

### Project Detection

The hooks detect Tilt projects by looking for:
- `Tiltfile` in the root or subdirectories
- Files with `.tiltfile` extension
- Files with `.star` or `.bzl` extensions (Starlark files)

When detected, the project type is set to "tilt" or included in a "mixed" project type.

### Linting (smart-lint.sh)

When Tiltfiles are detected, the lint hook will:

1. **Check for Makefile targets**: If `make lint-tilt` exists, use it
2. **Run buildifier**: Auto-format and lint with buildifier if available
3. **Basic syntax check**: Use Python to validate Starlark syntax
4. **Custom linters**: Run `scripts/lint-tiltfiles.sh` or `scripts/tiltfile-custom-lint.py` if present
5. **Security checks**: Look for hardcoded secrets, AWS account IDs, etc.

### Testing (smart-test.sh)

When Tiltfiles are edited, the test hook will:

1. **Check for Makefile targets**: If `make test-tilt` exists, use it
2. **Run pytest tests**: Look for `tests/test_tiltfiles.py` and run with pytest
3. **Validate with Tilt**: Use `tilt alpha tiltfile-result` to validate the Tiltfile
4. **Syntax validation**: Check syntax using Python
5. **Run related tests**: Look for test files in test directories

## Configuration

You can configure Tilt support via `.claude-hooks-config.sh`:

```bash
# Enable/disable Tilt linting
export CLAUDE_HOOKS_TILT_ENABLED=true

# Custom buildifier options
export CLAUDE_HOOKS_BUILDIFIER_OPTS="--lint=warn"

# Skip certain Tiltfiles from linting
export CLAUDE_HOOKS_TILT_EXCLUDE="vendor/,third_party/"
```

## Requirements

For full functionality, install:

### Required
- Python (for syntax checking) - usually pre-installed

### Recommended
- **buildifier**: The official Starlark formatter/linter
  ```bash
  go install github.com/bazelbuild/buildtools/buildifier@latest
  # or on macOS
  brew install buildifier
  ```

- **tilt**: For validation using `tilt alpha tiltfile-result`
  ```bash
  curl -fsSL https://raw.githubusercontent.com/tilt-dev/tilt/master/scripts/install.sh | bash
  ```

### Optional
- **pytest**: For running Python-based Tiltfile tests
  ```bash
  pip install pytest pyyaml
  ```

## Integration with Projects

### Using the Makefile Approach

If your project has a Makefile, add these targets:

```makefile
lint-tilt:
    @./scripts/lint-tiltfiles.sh

fix-tilt:
    @./scripts/fix-tiltfiles.sh

test-tilt:
    @pytest tests/test_tiltfiles.py -v
```

The hooks will automatically use these targets if present.

### Custom Linter Scripts

Create `scripts/lint-tiltfiles.sh` or `scripts/tiltfile-custom-lint.py` for project-specific checks.

### Python-based Testing

Since Starlark is Python-like, you can test Tiltfile functions using pytest. Create `tests/test_tiltfiles.py`:

```python
import pytest

def test_tiltfile_syntax():
    # Test that all Tiltfiles have valid syntax
    pass

def test_no_hardcoded_secrets():
    # Ensure no secrets are hardcoded
    pass
```

## Examples

### Example Output - Linting

```bash
🔍 Style Check - Validating code formatting...
────────────────────────────────────────────
[INFO] Project type: mixed:go,tilt
[INFO] Running Go formatting and linting...
[INFO] Using direct Go tools
[INFO] Running Tiltfile/Starlark linters...
[INFO] Using buildifier for Tiltfile formatting
[INFO] Auto-fixed formatting in 3 Tiltfile(s)
[OK] All Tiltfiles passed buildifier checks

✅ All checks passed!
```

### Example Output - Testing

```bash
🧪 Test Check - Running tests for edited file...
────────────────────────────────────────────
🧪 Running Tiltfile tests via Makefile...
========================= test session starts =========================
collected 5 items

tests/test_tiltfiles.py::test_all_tiltfiles_are_valid PASSED
tests/test_tiltfiles.py::test_no_hardcoded_secrets PASSED

========================= 5 passed in 0.42s =========================
✅ Tiltfile tests passed
🔍 Validating Tiltfile with 'tilt alpha tiltfile-result'...
✅ Tiltfile validation passed

✅ All tests passed!
```

## Troubleshooting

### "buildifier not found"
Install buildifier:
```bash
go install github.com/bazelbuild/buildtools/buildifier@latest
```

### "tilt command not found"
Install Tilt:
```bash
curl -fsSL https://raw.githubusercontent.com/tilt-dev/tilt/master/scripts/install.sh | bash
```

### Tests not running
Ensure pytest is installed and `tests/test_tiltfiles.py` exists:
```bash
pip install pytest
```

### False positives in security checks
Add proper secret loading patterns to avoid detection:
- Use `load_secrets()` function
- Use `k8s_secret()` for Kubernetes secrets
- Load from environment variables or external files

## Future Enhancements

1. **Starlark LSP Integration**: Better integration with starlark-lsp
2. **Performance Profiling**: Check Tiltfile execution time
3. **Dependency Analysis**: Validate extension dependencies
4. **Coverage Reports**: Test coverage for Tiltfile functions
5. **More Security Patterns**: Additional security checks

## Contributing

To add more Tilt/Starlark checks:

1. Edit `lint-tilt.sh` for new linting rules
2. Edit `test-tilt.sh` for new test patterns
3. Update patterns in `check_tiltfile_security()` for security checks
4. Add new file patterns to detection logic