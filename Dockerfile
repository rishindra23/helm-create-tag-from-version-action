FROM alpine:3.14

LABEL "com.github.actions.name"="Helm Create Tag from Version Action"
LABEL "com.github.actions.description"="Automates the process of pushing merge commits into a "release" branch from either a source branch (ie `main`) or from Git Tags/Releases."
LABEL "com.github.actions.icon"="arrow-up"
LABEL "com.github.actions.color"="green"

LABEL "repository"="https://github.com/Nextdoor/helm-create-tag-from-version-action"
LABEL "homepage"="https://github.com/Nextdoor/helm-create-tag-from-version-action"
LABEL "maintainer"="diranged"

RUN apk --no-cache add bash curl git yq

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
