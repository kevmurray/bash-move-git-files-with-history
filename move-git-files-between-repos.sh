#!/bin/bash 

gitHost=https://github.com
defaultBranch=master

sourceRepo=
sourceBranch=$defaultBranch
sourceDir=

targetRepo=
targetBranch=$defaultBranch
targetDir=

while [ "$1" ]; do
  case "$1" in
    --help|-h)
        echo "See: https://github.com/kevmurray/bash-move-git-files-with-history for documentation"
        open "https://github.com/kevmurray/bash-move-git-files-with-history"
        exit 0
        ;;
    --host=*) gitHost=${1#*=};;
    --branch=*) sourceBranch=${1#*=}; targetBranch=${1#*=};;
    --source-repo=*|--from-repo=*) sourceRepo=${1#*=};;
    --source-dir=*|--from-dir=*) sourceDir=${1#*=};;
    --whole-repo) sourceDir=;;
    --source-branch=*|--from-branch=*) sourceBranch=${1#*=};;
    --target-repo=*|--to-repo=*) targetRepo=${1#*=};;
    --target-dir=*|--to-dir=*) targetDir=${1#*=};;
    --target-branch=*|--to-branch=*) targetBranch=${1#*=};;
    *) echo "ERROR: Unknown parameter '$1'" >>/dev/stderr; exit 9;;
  esac
  shift
done
[ "$sourceRepo" ] || { echo "ERROR: required parameter --source-repo missing. Use --help for help." >>/dev/stderr; exit 9; }
[ "$targetRepo" ] || { echo "ERROR: required parameter --target-repo missing. Use --help for help." >>/dev/stderr; exit 9; }
[ "$targetDir" ] || { echo "ERROR: required parameter --target-dir missing. Use --help for help." >>/dev/stderr; exit 9; }



localSourceDir="$(pwd)/${sourceRepo##*/}"
localTargetDir="$(pwd)/${targetRepo##*/}"


# Make a copy of the source repo and remove upstream link to prevent corruption
echo "=== Getting source repo: $gitHost/$sourceRepo (branch $sourceBranch)"
rm -rf $localSourceDir
git clone --branch $sourceBranch --origin origin --progress -v $gitHost/$sourceRepo || exit 1
cd $localSourceDir
git remote rm origin || exit 1


# Filter for what we want to copy and clean everything else out
# If there is a sourceDir defined, then we are only going to be keeping the _contents_
# of that directory and deleting everything else. If no sourceDir is defined, then
# we're going to be moving the entire repo into a sub-directory
[ "$sourceDir" ] && {
  echo "=== Preparing directory $sourceDir for move"
  export FILTER_BRANCH_SQUELCH_WARNING=1
  git filter-branch --subdirectory-filter $sourceDir -- --all || exit 1

  # INVARIANT: At this point, the _contents_ of the sourceDir are at the root of the project
} || {
  echo "=== Preparing whole repo for move"
}

# Clean out any junk associated with stuff we aren't moving
echo "=== Pruning source repo of unnecessary artifacts"
git reset --hard
git gc --aggressive
git prune
git clean -fd

# Move what we've decided to keep into a temp directory.
# Temp directory to prevent conflicts if one of the files we are moving happens to have the same name as the targetDir.
# And the files we're going to keep is everything in the current directory except .git (and the temp dir)
mkdir tmp-$$
find . -mindepth 1 -maxdepth 1 -not -name .git -not -name tmp-$$ -exec mv '{}' tmp-$$ \; || exit 1


# Now move the temporary directory to the target directory
mkdir -p $(dirname $targetDir) || exit 1
mv tmp-$$ $targetDir || exit 1


# Commit the changes (local only, cannot push since we broke the link to the upstream repo)
echo "=== Packaging source files for move"
git add . || exit 1
git commit -m "Migrate $sourceDir to $targetDir" || exit 1

cd - >/dev/null

# Prepare the target repo
echo "=== Preparing target repo: $gitHost/$targetRepo (branch $targetBranch)"
[ -d $targetRepo ] || {
  git clone --origin origin --progress -v $gitHost/$targetRepo || exit 1
}
cd $localTargetDir
git branch --list $targetBranch && git checkout $targetBranch || git checkout -b $targetBranch 

# Connect target repo to the source repo (local copy), pull the files, then disconnect
echo "=== Moving files from $sourceRepo to $targetRepo"
git remote add source-repo $localSourceDir || exit 1
git pull source-repo $sourceBranch --allow-unrelated-histories --no-edit || exit 1
git remote rm source-repo || exit 1
cd - >/dev/null


# At this point the files and their history have been merged into the target repo and we
# can `git push` whenever we want.
# Not doing this automatically so we can inspect the result

echo "+----------------------------------------------------------------------------------"
echo "| All the files from ${gitHost#*://}/$sourceRepo/$sourceDir and their histories "
echo "| have been copied to ${gitHost#*://}/$targetRepo/$targetDir. "
echo "| "
echo "| Please verify you are happy with the result, then run "
echo "|     cd $localTargetDir && git push"
echo "| "
echo "| If you are not happy with the result, then run "
echo "|     rm -rf $localTargetDir"
echo "| and try again."
echo "+----------------------------------------------------------------------------------"

# clean up the mangled source repo
rm -rf $localSourceDir

