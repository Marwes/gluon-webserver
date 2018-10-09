FROM rust:1.28.0

WORKDIR /usr/src/try_gluon

RUN curl -sL https://deb.nodesource.com/setup_8.x | bash -
RUN apt-get install -y nodejs

RUN apt-get update && apt-get install -y curl apt-transport-https && \
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt-get update && apt-get install -y yarn

RUN cargo install mdbook --vers "0.1.2"

RUN yarn global add webpack-cli
RUN yarn global add webpack
RUN yarn global add elm@0.19.0

COPY package.json yarn.lock ./
RUN yarn install

# Cache the built dependencies
COPY gluon_master/Cargo.toml gluon_master/
COPY Cargo.toml Cargo.lock ./
RUN mkdir -p gluon_master/src && touch gluon_master/src/lib.rs \
    && mkdir -p src/app && echo "fn main() { }" > src/app/main.rs
RUN cargo build --release
RUN cargo build

COPY . .

RUN webpack-cli --mode=production
RUN touch gluon_master/src/lib.rs

RUN cargo update -p https://github.com/gluon-lang/gluon

RUN cargo build --release

EXPOSE 8080

CMD ["target/release/try_gluon"]
