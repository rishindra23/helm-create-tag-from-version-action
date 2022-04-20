# `helm-create-tag-from-version-action`

[docker-image-retag-action]: https://github.com/Nextdoor/docker-image-retag-action
[helm-set-image-tag-action]: https://github.com/Nextdoor/helm-set-image-tag-action

This simple Github Action is designed to help you automatically create tags
from your Helm Chart. You would run this action after you have updated your
Helm Chart version (and committed the change) - and this chart would then
create a tag named `{{ .Chart.Name }}-{{ .Chart.Version }}` for you.

## Basic Flow

The idea behind the workflow below is that there is both "application code" and
"chart code" in your repository - and these are fundamentally separate but
related. A developer will usually iterate rapidly on the application code,
while iterating less frequently on the chart code.

Because your Helm Chart is supposed to point at a specific (and already
existing) Docker Image tag, it is not easy to coordinate one git tag that
has both the updated chart values AND has already built/published the
Docker image. Instead, we treat these two different sets of artifacts as
independent releases from within the same repository.

The developer is responsible for iterating on their application code, and
creating the tag that triggers the build/publishing of their release artifact
(the application Docker image). From there, the CI system automatically updates
the Helm chart values, revs its version, and then publishes a new tag and
Github Release.

1. Developer pushes their application code continually to `HEAD`
2. Developer tags an application release `v1.2.3`
3. CI system builds Docker artifact `myapp:v1.2.3`
   (hint: see [Nextdoor/docker-image-retag-action][docker-image-retag-action])
4. CI system updates `chart/values.yaml` and `chart/Chart.yaml` setting the
   Chart version to `0.1.52`.
   (hint: see [Nextdoor/helm-set-image-tag-action][helm-set-image-tag-action])
5. This action then generates a new Github Tag pointing to `myapp-chart-0.1.52`
   and also moves the `production` tag to the same commit.

## Features

### Release Cutting

By default, this action will also create a matching Github Release for your
tag. This requires that you set the `GITHUB_TOKEN` environment variable and
provide that token with the right privileges.

### Tag Moving

In addition to creating a new git tag, this action can also _move_ an existing
tag to point to the current tag that was just created. This is useful if you
have a regular tag that you point developers or applications at (say `stable`
or `production`) and you want to move that tag along with your releases.

## Usage

```yaml
# .github/workflows/release.yml
name: Release
on:
  push:
    branches:
      - '!*'
    tags:
      - v*
jobs:
  release:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@master
      with:
        fetch-depth: '0'

    # ... insert your code here that handles automatically updating your Helm
    # Chart version and values... or use something like our
    # helm-set-image-tag-action.
    - name: Update Helm Chart Values
      uses: Nextdoor/helm-set-image-tag-action@main
      with:
        verbose: true
        tag: ${{ github.ref }}
        values: charts/app/values.yaml
        keys: .image.tag
        bump_level: patch
        commit_branch: main

    - name: Create Chart Release Tag
      uses: Nextdoor/helm-create-tag-from-version-action@main
      env:
        GITHUB_TOKEN: ${{ github.token }}
      with:
        verbose: true
        chart_dir: charts/app
        create_release: true
```
