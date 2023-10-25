FROM ubuntu:22.04@sha256:a8fe6fd30333dc60fc5306982a7c51385c2091af1e0ee887166b40a905691fd0

RUN apt-get update && apt-get install -y zip unzip jq ca-certificates curl apt-transport-https git

# Create a folder
RUN mkdir actions-runner
WORKDIR /actions-runner

RUN GITHUB_RUNNER_VERSION="2.311.0" && \
    GITHUB_RUNNER_VERSION_SHA="2d5d2046f77e7e90e1dac421b6a45583b6a82cfb6fbe3c37bb1d142ea38d6d03" && \
    curl -o actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz -L https://github.com/actions/runner/releases/download/v${GITHUB_RUNNER_VERSION}/actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz && \
    echo "${GITHUB_RUNNER_VERSION_SHA}  actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz" | sha256sum -c && \
    tar xzf ./actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz && \
    rm actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz


WORKDIR /home/github

COPY entrypoint.sh ./entrypoint.sh
RUN chmod +x ./entrypoint.sh

USER github
ENTRYPOINT ["/home/github/entrypoint.sh"]