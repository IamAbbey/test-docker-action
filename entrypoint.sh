#!/bin/sh

set -e
set -x

DESTINATION_REPO=$1
DEPENDENCY_NAME=$2
MERGE_COMMIT_SHA=$GITHUB_SHA
DESTINATION_BASE_BRANCH="master"
API_TOKEN_GITHUB=$3
NEW_BRANCH_NAME="dependency-update-$MERGE_COMMIT_SHA"
SSH_KEY=$4

if [ -z "$MERGE_COMMIT_SHA" ]
then
  echo "The merge commit sha is needed"
  return 1
fi

# CLONE_DIR=$(mktemp -d)
CLONE_DIR=$(echo "$DESTINATION_REPO" | rev | cut -d "/" -f1 | rev)

echo "Cloning destination git repository"
export GITHUB_TOKEN=$API_TOKEN_GITHUB
git clone "https://$API_TOKEN_GITHUB@github.com/$GITHUB_REPOSITORY_OWNER/$DESTINATION_REPO.git" "$CLONE_DIR" > /dev/null

cd "$CLONE_DIR"
git checkout -b "$NEW_BRANCH_NAME"

git config user.email "dependency-update@bot.com"
git config user.name "Dependency Update"
git config commit.gpgsign false

echo "Updating pyproject.toml"
sed -i -e "s/\($DEPENDENCY_NAME.*, rev =\).*\(}\)/\1 \"$MERGE_COMMIT_SHA\" \2/" pyproject.toml

echo "Running poetry update"
if [ ! -z "$SSH_KEY" ]
then
    eval "$(ssh-agent -s)"
    ssh-add - <<< "${SSH_KEY}"
fi
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
