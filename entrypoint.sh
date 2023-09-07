#!/bin/sh

set -e
set -x

export DESTINATION_REPO=$1
export DEPENDENCY_NAME=$2
export MERGE_COMMIT_SHA=$3
export DESTINATION_BASE_BRANCH="master"
export API_TOKEN_GITHUB="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"
export NEW_BRANCH_NAME="dependency-update-$MERGE_COMMIT_SHA"

if [ -z "$MERGE_COMMIT_SHA" ]
then
  echo "The merge commit sha is needed"
  return 1
fi

# CLONE_DIR=$(mktemp -d)
CLONE_DIR=$(echo "$DESTINATION_REPO" | rev | cut -d "/" -f1 | rev)

echo "Setting git variables"
export GITHUB_TOKEN=$API_TOKEN_GITHUB


echo "Cloning destination git repository"
git clone "https://$API_TOKEN_GITHUB@github.com/$GITHUB_REPOSITORY_OWNER/$DESTINATION_REPO.git" "$CLONE_DIR" > /dev/null

cd "$CLONE_DIR"
git checkout -b "$NEW_BRANCH_NAME"

git config user.email "dependency-update@bot.com"
git config user.name "Dependency Update"
git config commit.gpgsign false

echo "Updating pyproject.toml"
sed -i '' -e "s/\($DEPENDENCY_NAME.*, rev =\).*\(}\)/\1 \"$MERGE_COMMIT_SHA\" \2/" pyproject.toml > /dev/null

echo "Running poetry update"
poetry update > /dev/null

echo "Logging changes"
git status -s -uno

CHANGED_FILE_COUNT=$(git status -s -uno | wc -l | tr -d ' ')

if [ "$CHANGED_FILE_COUNT" -eq 2 ]; then
  echo "Two files changes detected";

  echo "Adding git commit"
  git commit -a -m "chore(poetry): bot bump dependencies"
  echo "Pushing git commit"
  git push -u origin "$NEW_BRANCH_NAME"
  echo "Creating a pull request"
  gh pr create --title "Dependency update for $DEPENDENCY_NAME" \
              --body "Dependency update for $DEPENDENCY_NAME" \
              --base $DESTINATION_BASE_BRANCH \

else
  echo "Two file changes expected, something seems wrong"
fi
