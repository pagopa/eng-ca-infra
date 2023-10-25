FROM ghcr.io/actions/actions-runner:2.311.0

RUN useradd github && \
    mkdir -p /home/github && \
    chown -R github:github /home/github && \
    chown -R github:github /actions-runner

WORKDIR /home/github

COPY entrypoint.sh ./entrypoint.sh
RUN chmod +x ./entrypoint.sh

USER github
ENTRYPOINT ["/home/github/entrypoint.sh"]