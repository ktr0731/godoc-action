#!/bin/bash

set -eo pipefail

cd "$(dirname "$(find . -name 'go.mod' | head -n 1)")" || exit 1

MODULE_ROOT="$(go list -m)"
REPO_NAME="$(basename $(echo $GITHUB_REPOSITORY))"
PR_NUMBER="$(echo $GITHUB_REF | sed 's#refs/pull/\(.*\)/.*#\1#')"

mkdir -p "$GOPATH/src/github.com/$GITHUB_REPOSITORY"
cp -r * "$GOPATH/src/github.com/$GITHUB_REPOSITORY"
(cd /tmp && godoc -http localhost:8080 &)

for (( ; ; )); do
  sleep 0.5
  if [[ $(curl -so /dev/null -w '%{http_code}' "http://localhost:8080/pkg/$MODULE_ROOT/") -eq 200 ]]; then
    break
  fi
done

git checkout gh-pages

wget --quiet --mirror --show-progress --page-requisites --execute robots=off --no-parent "http://localhost:8080/pkg/$MODULE_ROOT/"

rm -rf doc lib "$PR_NUMBER" # Delete previous documents.
mv localhost:8080/* .
rm -rf localhost:8080
find pkg -type f -exec sed -i "s#/lib/godoc#/$REPO_NAME/lib/godoc#g" {} +

git config --local user.email "action@github.com"
git config --local user.name "GitHub Action"
[ -d "$PR_NUMBER" ] || mkdir "$PR_NUMBER"
mv pkg "$PR_NUMBER"
git add "$PR_NUMBER" doc lib
git commit -m "Update documentation"

GODOC_URL="https://$(dirname $(echo $GITHUB_REPOSITORY)).github.io/$REPO_NAME/$PR_NUMBER/pkg/$MODULE_ROOT/index.html"

curl -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/$GITHUB_REPOSITORY/issues/$PR_NUMBER/comments" | grep '## GoDoc' > /dev/null
if [[ $? -ne 0 ]]; then
  curl -H "Authorization: token $GITHUB_TOKEN" \
    -d '{ "body": "## GoDoc\n'"$GODOC_URL"'" }' \
    "https://api.github.com/repos/$GITHUB_REPOSITORY/issues/$PR_NUMBER/comments"
fi
