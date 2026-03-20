#!/bin/bash
# Guard against running tests in production.
# Used as a PreToolUse hook for Bash commands matching pytest/test patterns.

ENV_VALUE="${APP_ENV:-${ENV:-development}}"

if [ "$ENV_VALUE" = "production" ] || [ "$ENV_VALUE" = "prod" ]; then
    echo "BLOCKED: Cannot run tests in a production environment (APP_ENV=$ENV_VALUE)."
    echo "Tests should only run in development or CI environments."
    exit 2
fi