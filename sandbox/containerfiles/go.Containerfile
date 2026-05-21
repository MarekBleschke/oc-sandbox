FROM localhost/oc-sandbox:base
ARG GO_VERSION=1.26.3
USER root
RUN cd /tmp && wget https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz && \
  rm -rf /usr/local/go && \
  tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz && \
  echo 'PATH="$PATH:/usr/local/go/bin"' >> /home/sandbox/.bashrc && \
  curl -sSfL https://golangci-lint.run/install.sh | sh -s -- -b /usr/local/go/bin v2.12.2

USER sandbox
