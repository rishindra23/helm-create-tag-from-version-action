#!/bin/bash

# Exit on any failure.
set -eu

TAG_NAME=""
GITHUB_TOKEN=${GITHUB_TOKEN:-}

if [ "${INPUT_FORCE}" == "true" ]; then
  FORCE_OPT="--force"
else
  FORCE_OPT=""
fi

_set_tag_string() {
  local CHART_YAML=${INPUT_CHART_DIR}/Chart.yaml
  local NAME
  local VERSION

  if [ ! -f "${CHART_YAML}" ]; then
    echo "::error::Can not find ${CHART_YAML}. Failing."
    return 1
  fi

  VERSION=$(yq eval .version "${CHART_YAML}") || return 1
  NAME=$(yq eval .name "${CHART_YAML}") || return 1

  TAG_NAME="${NAME}-${VERSION}"
}

_create_tag() {
  [ "${INPUT_DRY}" == "true" ] && return 0

  echo "Creating tag ${TAG_NAME}..."

  git \
    -c user.name="${INPUT_TAG_USER_NAME}" \
    -c user.email="${INPUT_TAG_USER_EMAIL}}" \
    tag "${TAG_NAME}" \
    ${FORCE_OPT} \
    --annotate \
    --message "${INPUT_TAG_MESSAGE}"

  git push origin "${TAG_NAME}" ${FORCE_OPT}
}

_create_release() {
  [ "${INPUT_CREATE_RELEASE}" == "true" ] || return 0

  echo "Creating release ${TAG_NAME} from ${TAG_NAME}..."

  if [ -z "${GITHUB_TOKEN}" ]; then
    echo "::error::Cannot create Github Release without setting GITHUB_TOKEN"
    return 1
  fi

  local URL=https://api.github.com/repos/${GITHUB_REPOSITORY}/releases
  local DATA="
    {\"tag_name\": \"${TAG_NAME}\",
     \"name\": \"${TAG_NAME}\",
     \"body\": \"${INPUT_RELEASE_MESSAGE}\",
     \"draft\": false,
     \"prerelease\": false}"

  if [ "${INPUT_DRY}" == "true" ]; then
     echo "Would have called ${URL} with DATA: ${DATA}"
     return 0
  fi

  curl \
    --header "authorization: Bearer ${GITHUB_TOKEN}" \
    --fail \
    --show-error \
    --data "${DATA}" \
    https://api.github.com/repos/${GITHUB_REPOSITORY}/releases
}

_update_alias_tag() {
  [ -n "${INPUT_RELEASE_TAG}" ] || return 0

  echo "Creating (or updating) alias tag ${INPUT_RELEASE_TAG}"

  local ORIG_TAG_NAME=$TAG_NAME
  TAG_NAME="${INPUT_RELEASE_TAG}" \
    FORCE_OPT="--force" \
    INPUT_TAG_MESSAGE="Updated release tag to ${ORIG_TAG_NAME}" \
    _create_tag
}

# Be really loud and verbose if we're running in VERBOSE mode
if [ "${INPUT_VERBOSE}" == "true" ]; then
  set -x
  echo "Environment:"
fi

_set_tag_string
_create_tag
_update_alias_tag
_create_release
