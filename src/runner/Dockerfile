FROM ghcr.io/actions/actions-runner:2.311.0

RUN apt-get update && apt-get install -y curl \
    wget

COPY --chmod=0755 entrypoint.sh ./entrypoint.sh

ENTRYPOINT ["./entrypoint.sh"]