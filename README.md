# Docker action

This action builds Rust code, builds a thin Docker container with the resulting executable, then saves the image as `<output-file-name>.tar.zip`.

## Inputs

- app-name: App name (from Cargo.toml)
- output-file-name: Name of the output file (without extension)

Refer to `action.yaml` for details.

The action assumes the presence of `Cargo.toml`, `Cargo.lock` and a `src` folder contains Rust code.

## Outputs

- output_file_path: output file path

Refer to `action.yaml` for details.

## Example usage

```yaml
steps:
  - uses: john-cd/rust_github_action@v1
```

An example workflow is found in `./test_workflow/`.

## Testing the Docker image locally

The Dockerfile is a multi-stage build.

To build the "build" Docker image, which contains the Rust tooling, use the following from the root directory:

```bash
docker build --tag test_app --target build \
  --build-arg RUST_VERSION=1.75 --build-arg APP_NAME=test_app \
  --platform linux/amd64 --file ./Dockerfile   ./test_app
```

Substitute `--target final` to build the "final" stage, which only contains the final executable.

Run the Docker image and exec into it to inspect it.

```bash
docker run -d --name test_container test_app
docker exec -it test_container ash

# or simply
docker run -it --name test_container test_app ash
```

## Create a new version of the GitHub Action

Create a tag, push it to the remote origin. The tag will be used by GitHub Action as the Action version.
Then update the version in your workflows e.g. `john-cd/rust_github_action@v2`

```bash
# List existing tags
git tag
# Create local tag
git tag -a -m "Description of this release" v2
git tag
# Show details about the tag
git show v2
# Push tag to remote
git push origin v2
# git push --follow-tags
```

[Git Basics - Tagging]( https://git-scm.com/book/en/v2/Git-Basics-Tagging )

## Docker Compose config

`Docker Compose` configuration is also provided, but it is not used by the GitHub Action itself.

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

## References

* [Creating a composite action](https://docs.github.com/en/actions/creating-actions/creating-a-composite-action)
* [Creating a Docker container action](https://docs.github.com/en/actions/creating-actions/creating-a-docker-container-action)
* [Docker's Rust guide](https://docs.docker.com/language/rust/)
