# GoDoc Action

## Description
GoDoc Action is a GitHub Action that provides automated GoDoc generating and hosting on GitHub Pages.

## Example
```yaml
on: [pull_request]

jobs:
  main:
    runs-on: ubuntu-latest
    name: Example
    steps:
    - name: Checkout
      uses: actions/checkout@v1
    - name: Generate GoDoc
      uses: 
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    - name: Push changes
      uses: ad-m/github-push-action@master
      with:
        github_token: ${{ secrets.GITHUB_TOKEN }}
        branch: gh-pages
        force: true
```
