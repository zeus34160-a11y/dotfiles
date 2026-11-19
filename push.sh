#!/usr/bin/env bash

set -e

cd "$(dirname "$(realpath "$0")")"

BRANCH=$(git branch --show-current)

echo "📦 Staging changes..."
git add -A

if git diff --cached --quiet; then
    echo "No new changes to commit."
else
    MESSAGE="${*:-Update dotfiles}"
    echo "📝 Creating commit..."
    git commit -m "$MESSAGE"
fi

echo "⬇️ Pulling GitHub changes..."
git pull --rebase origin "$BRANCH"

echo "⬆️ Pushing to GitHub..."
git push origin "$BRANCH"

echo "✅ Dotfiles successfully pushed!"
