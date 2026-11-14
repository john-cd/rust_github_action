# TODO Reviewed ??-??-2026.

# syntax=docker/dockerfile:1
# Dockerfile build inputs are required and supplied by Compose from tracked .devcontainer/.env.
# From the repo root pass --env-file .devcontainer/.env and add --env-file .devcontainer/.env.local when present.
# Dockerfile build inputs for rust-github-action.

# Comments are provided throughout this file to help you get started.
# If you need more help, visit the Dockerfile reference guide at
# https://docs.docker.com/go/dockerfile-reference/

ARG RUST_VERSION
ARG RUST_ALPINE_VERSION
ARG ALPINE_VERSION
ARG XX_VERSION
ARG APP_NAME

################################################################################
# xx is a helper for cross-compilation.
# See https://github.com/tonistiigi/xx/ for more information.
FROM --platform=$BUILDPLATFORM tonistiigi/xx:${XX_VERSION} AS xx

################################################################################
# Create a stage for building the application.
FROM --platform=$BUILDPLATFORM rust:${RUST_VERSION}-alpine${RUST_ALPINE_VERSION} AS build
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
if ! printf '%s\n' "$APP_NAME" | grep -Eq '^[A-Za-z0-9_][A-Za-z0-9_-]*$'; then
    echo "APP_NAME must contain only ASCII letters, digits, underscores, and hyphens." >&2
    exit 1
fi
xx-cargo build --locked --release --target-dir /code/target
mkdir -p /code/dist/
cp "/code/target/$(xx-cargo --print-target-triple)/release/$APP_NAME" /code/dist/app
xx-verify /code/dist/app
EOF
## Note: using bind mounts for the folders-to-cache (target, cargo/*...) won't work even if marked `rw`. Writes are discarded.

################################################################################
# Create a new stage for running the application that contains the minimal
# runtime dependencies for the application. This often uses a different base
# image from the build stage where the necessary files are copied from the build
# stage.
#
# Pin the runtime image to the Alpine patch release selected in .devcontainer/.env.
FROM alpine:${ALPINE_VERSION} AS final

# Create the fixed non-privileged account that the app will run under.
# See https://docs.docker.com/go/dockerfile-user-best-practices/
RUN addgroup -g 10001 appuser \
    && adduser -D -H -u 10001 -G appuser -s /sbin/nologin appuser
USER appuser

# Copy the executable from the "build" stage.
COPY --from=build /code/dist/app /code/dist/

# COPY entrypoint.sh /entrypoint.sh

# ENTRYPOINT ["/entrypoint.sh"]

# What the container should run when it is started.
CMD ["/code/dist/app"]
