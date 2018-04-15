FROM node:8.11

RUN apt-get update && apt-get install -y \
    git \
    libboost-dev \
    unzip

# Add non-privileged user
RUN adduser --disabled-password --gecos '' bc

# Drop privileges
USER bc

WORKDIR /home/bc

ENV YARN_VERSION=1.5.1
ENV PROTOBUF_VERSION=3.5.1

# Install yarn
RUN curl -o- -L https://yarnpkg.com/install.sh | bash -s -- --version ${YARN_VERSION} \
    && export PATH=/home/bc/.yarn/bin:$PATH
ENV PATH "/home/bc/.yarn/bin:$PATH"

# Install protobuf
RUN curl -OL https://github.com/google/protobuf/releases/download/v${PROTOBUF_VERSION}/protoc-${PROTOBUF_VERSION}-linux-x86_64.zip \
    && unzip protoc-${PROTOBUF_VERSION}-linux-x86_64.zip -d /home/bc/protoc \
    && export PATH=/home/bc/protoc/bin:$PATH
ENV PATH "/home/bc/protoc/bin:$PATH"

# Install nightly rust
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain nightly \
    && export PATH=/home/bc/.cargo/bin:$PATH \
    && rustup update \
    && rustc -Vv \
    && cargo -V \
    && rustup component add rust-src
ENV PATH "/home/bc/.cargo/bin:$PATH"

# Install neon-bindings
RUN npm install -g neon-cli --prefix /home/bc/.npm
ENV PATH "/home/bc/.npm/bin:$PATH"

ENV BCNODE_VERSION=0.1.0

# Create src/log folder, copy sources from host and set permissions
RUN git clone https://github.com/blockcollider/bcnode /home/bc/src && \
    cd /home/bc/src && \
    git checkout tags/v${BCNODE_VERSION} && \
    mkdir logs

WORKDIR /home/bc/src

# And build everything
RUN yarn run dist

EXPOSE 3000 9090

ENTRYPOINT [ "node", "./bin/cli" ]
