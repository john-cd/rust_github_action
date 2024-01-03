# syntax=docker/dockerfile:1

# Comments are provided throughout this file to help you get started.
# If you need more help, visit the Dockerfile reference guide at
# https://docs.docker.com/go/dockerfile-reference/

ARG RUST_VERSION
ARG APP_NAME

################################################################################
# xx is a helper for cross-compilation.
# See https://github.com/tonistiigi/xx/ for more information.
FROM --platform=$BUILDPLATFORM tonistiigi/xx:1.3.0 AS xx

################################################################################
# Create a stage for building the application.
FROM --platform=$BUILDPLATFORM rust:${RUST_VERSION}-alpine AS build
ARG APP_NAME
WORKDIR /code

# Copy cross compilation utilities from the xx stage.
COPY --from=xx / /

# Install host build dependencies.
RUN apk add --no-cache clang lld musl-dev git file

# This is the architecture you’re building for, which is passed in by the builder.
# Placing it here allows the previous steps to be cached across architectures.
ARG TARGETPLATFORM

# Install cross compilation build dependencies.
RUN xx-apk add --no-cache musl-dev gcc

COPY . /code/

# Build the application.
# Leverage a bind mount to the src directory to avoid having to copy the
# source code into the container. Once built, copy the executable to an
# output directory.
# Note: xx-cargo does not store the compiled executable under /code/target/release/
RUN --mount=type=bind,source=src,target=/code/src \
    --mount=type=bind,source=Cargo.toml,target=/code/Cargo.toml \
    --mount=type=bind,source=Cargo.lock,target=/code/Cargo.lock \
    <<EOF
set -e
xx-cargo build --locked --release --target-dir /code/target
mkdir -p /code/dist/
cp /code/target/$(xx-cargo --print-target-triple)/release/$APP_NAME /code/dist/app
xx-verify /code/dist/app
EOF
## Note: using bind mounts for the folders-to-cache (target, cargo/*...) won't work even if marked `rw`

################################################################################
# Create a new stage for running the application that contains the minimal
# runtime dependencies for the application. This often uses a different base
# image from the build stage where the necessary files are copied from the build
# stage.
#
# The example below uses the alpine image as the foundation for running the app.
# By specifying the "3.18" tag, it will use version 3.18 of alpine. If
# reproducability is important, consider using a digest
# (e.g., alpine@sha256:664888ac9cfd28068e062c991ebcff4b4c7307dc8dd4df9e728bedde5c449d91).
FROM alpine:3.19 AS final

# Create a non-privileged user that the app will run under.
# See https://docs.docker.com/go/dockerfile-user-best-practices/
ARG UID=10001
RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/nonexistent" \
    --shell "/sbin/nologin" \
    --no-create-home \
    --uid "${UID}" \
    appuser
USER appuser

# Copy the executable from the "build" stage.
COPY --from=build /code/dist/app /code/dist/

# COPY entrypoint.sh /entrypoint.sh

# ENTRYPOINT ["/entrypoint.sh"]

# What the container should run when it is started.
CMD ["/code/dist/app"]
