# Docker action

This action builds Rust code, builds a thin Docker container with the resulting executable, then saves the image as `app.tar.zip`.

## Inputs

None

The action assumes the presence of `Cargo.toml`, `Cargo.lock` and a `src` folder contains Rust code.

## Outputs

None

## Example usage

```yaml
steps:
  - uses: john-cd/rust_github_action@v1
```

## Testing the Docker image locally

The Dockerfile is a multi-stage build.

To build the "build" Docker image, which contains the Rust tooling, use:

```bash
cd test_app
docker build --tag test_app --build-arg RUST_VERSION=1.75 --build-arg APP_NAME=test_app --target build --platform linux/amd64 .
```

Use `--target final` to build the "final" stage, which only contains the final executable.

Run the Docker image and exec into it to inspect it.

```bash
docker run -d --name test_container test_app
docker exec -it test_container ash

# or simply
docker run -it --name test_container test_app ash
```

## Test the Docker Compose config

`compose.yaml` uses the `build` stage.

To build the Docker image using Compose, use

```bash
docker compose build
```

To test the build stage with the provided `test_app`, use

```bash
docker compose -f compose.yaml -f compose-test.yaml build
```

To build and run the `final` Docker image using Compose, use `compose-final.yaml`:

```bash
docker compose -f compose.yaml -f compose-final.yaml build
docker compose -f compose.yaml -f compose-final.yaml up -d

# or simply
docker compose -f compose.yaml -f compose-final.yaml up -d --build
```

To test the final stage with the provided `test_app`, use

```bash
docker compose -f compose.yaml -f compose-final.yaml -f compose-test.yaml up -d --build
```

## Tag the repo

```bash
git tag -a -m "Description of this release" v1
git push --follow-tags
```

[Git Basics - Tagging]( https://git-scm.com/book/en/v2/Git-Basics-Tagging )

The tag will be used by GitHub Action as the Action version.

See the "test_workflow" folder for an example.

## References

* [Creating a composite action](https://docs.github.com/en/actions/creating-actions/creating-a-composite-action)
* [Creating a Docker container action](https://docs.github.com/en/actions/creating-actions/creating-a-docker-container-action)
* [Docker's Rust guide](https://docs.docker.com/language/rust/)
