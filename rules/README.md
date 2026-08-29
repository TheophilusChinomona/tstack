# tstack — Rule Packs

tstack rule packs provide always-loaded standards for your projects. Choose the rules that match your stack.

## Available Rule Packs

### `common/`
Shared rules for all projects:
- Code quality standards
- Git workflow conventions
- Documentation requirements
- Testing best practices

### `typescript/`
TypeScript-specific rules:
- Type safety requirements
- Interface design patterns
- Module organization
- Build configuration

### `python/`
Python-specific rules:
- PEP 8 compliance
- Type hint requirements
- Virtual environment management
- Package structure

### `security/`
Security-focused rules:
- Input validation requirements
- Authentication patterns
- Secrets management
- OWASP compliance

## Install

```bash
# Copy rule packs to your project
cp -R rules/common ~/.claude/rules/tstack/
cp -R rules/typescript ~/.claude/rules/tstack/  # if using TypeScript
cp -R rules/python ~/.claude/rules/tstack/       # if using Python
cp -R rules/security ~/.claude/rules/tstack/     # always recommended
```

## Custom Rules

To add custom rules:
1. Create a new directory in `rules/your-rules-name/`
2. Add Markdown files with your rules
3. Copy to `~/.claude/rules/tstack/your-rules-name/`
