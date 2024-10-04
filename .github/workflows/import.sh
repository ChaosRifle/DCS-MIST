#!/bin/bash

apt-get -y update
apt-get -y install git
apt-get -y install git-lfs
apt-get -y install openssh-client

git --version


echo ===========================================================================
echo 'configuring script..'

GIT_SERVER="github.com"
USER_NAME="ChaosRifle"
USER_EMAIL="ChaosBuildScript@CBS.ca"

THIS_REPO="ChaosTheory"
IMPORT_REPO_OWNER="mrSkortch"
IMPORT_REPO="MissionScriptingTools"
FILE="mist.lua"

UPLOAD_BRANCH_TARGET="import"

OUTPUT_DIR="output_temp"


echo 'script configured'
echo ===========================================================================
echo 'configuring github install..'
#get github up and running
mkdir --parents "$HOME/.ssh"
DEPLOY_KEY_FILE="$HOME/.ssh/deploy_key"
echo "${SSH_IMPORT_KEY}" > "$DEPLOY_KEY_FILE"
chmod 600 "$DEPLOY_KEY_FILE"
SSH_KNOWN_HOSTS_FILE="$HOME/.ssh/known_hosts"
ssh-keyscan -H "$GIT_SERVER" > "$SSH_KNOWN_HOSTS_FILE"
export GIT_SSH_COMMAND="ssh -i "$DEPLOY_KEY_FILE" -o UserKnownHostsFile=$SSH_KNOWN_HOSTS_FILE"



git config --global user.email $USER_EMAIL
git config --global user.name $USER_NAME
# workaround for https://github.com/cpina/github-action-push-to-another-repository/issues/103
git config --global http.version HTTP/1.1

echo 'github configured.'
echo ===========================================================================
echo 'main script begins..'


GIT_IMPORT_REPOSITORY="git@$GIT_SERVER:$IMPORT_REPO_OWNER/$IMPORT_REPO.git"
git clone --branch "master" "$GIT_IMPORT_REPOSITORY" "$HOME/git/import"

GIT_THIS_REPOSITORY="git@$GIT_SERVER:$USER_NAME/$THIS_REPO.git"
git clone --branch "dev" "$GIT_THIS_REPOSITORY" "$HOME/git/staging"

rm -rf "$HOME/git/staging/$FILE"   #check if file from import repo matches $FILE before we remove it?

cp "$HOME/git/import/$FILE" "$HOME/git/staging/$FILE"


#mv "$HOME/git/staging" "$OUTPUT_DIR"
cp -r "$HOME/git/staging" "$OUTPUT_DIR"



echo ===========================================================================
echo 'stamping time..'
# timestamp the work, script ends, pushes contents to repo via cpina's script
echo "generated_at: $(date)" > variables.yml
date > "$OUTPUT_DIR"/.build_date.txt





cd "$OUTPUT_DIR"

echo "Files that will be pushed:"
ls -la

ORIGIN_COMMIT="https://$GIT_SERVER/$GITHUB_REPOSITORY/commit/$GITHUB_SHA"
COMMIT_MESSAGE="${COMMIT_MESSAGE/ORIGIN_COMMIT/$ORIGIN_COMMIT}"
COMMIT_MESSAGE="${COMMIT_MESSAGE/\$GITHUB_REF/$GITHUB_REF}"

echo "Set directory is safe ($OUTPUT_DIR)"
# Related to https://github.com/cpina/github-action-push-to-another-repository/issues/64
git config --global --add safe.directory "$OUTPUT_DIR"

echo "Switch to the $UPLOAD_BRANCH_TARGET"
# || true: if the $UPLOAD_BRANCH_TARGET already existed in the destination repo:
# it is already the current branch and it cannot be switched to
# (it's not needed)
# If the branch did not exist: it switches (creating) the branch
git switch -c "$UPLOAD_BRANCH_TARGET" || true


echo "Adding git commit"
git add .

echo "git status:"
git status

echo "git diff-index:"
# git diff-index : to avoid doing the git commit failing if there are no changes to be commit
git diff-index --quiet HEAD || git commit --message "$COMMIT_MESSAGE"

echo "Pushing git commit"
# --set-upstream: sets de branch when pushing to a branch that does not exist
git push "$GIT_THIS_REPOSITORY" --set-upstream "$UPLOAD_BRANCH_TARGET"

