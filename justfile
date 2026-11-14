# TODO Reviewed ??-??-2026
# Route Cargo through this checkout's stable central build slot.
set shell := ["bash", "-uc"]
set windows-shell := ["C:/Program Files/Git/bin/bash.exe", "-uc"]
set quiet

export CARGO_TERM_QUIET := env("CARGO_TERM_QUIET", "true")
rustfmt_toolchain := env("RUSTFMT_TOOLCHAIN", "nightly-2026-11-11")
export RUSTFMT_TOOLCHAIN := rustfmt_toolchain

root := replace(source_directory(), "\\", "/")
checkout_name := file_name(root)
worktree_name := if file_name(parent_directory(root)) == ".worktrees" { checkout_name } else { "main" }
repo_root := if file_name(parent_directory(root)) == ".worktrees" { parent_directory(parent_directory(root)) } else { root }
repo_name := file_name(repo_root)
tooling_slot := if worktree_name =~ '^(main|[a-z])$' { worktree_name } else { error("Invalid worktree slot: " + worktree_name) }
cache_home := if os() == "windows" { env("LOCALAPPDATA", join(home_directory(), ".cache")) } else { env("XDG_CACHE_HOME", join(home_directory(), ".cache")) }
code_target_root := env("CODE_TARGET_ROOT", if os_family() == "windows" { "D:/target" } else { join(cache_home, "cargo-target") })
code_build_root := env("CODE_BUILD_ROOT", if os_family() == "windows" { "D:/code_build" } else { join(cache_home, "cargo-build") })
code_sccache_root := env("CODE_SCCACHE_ROOT", env("SCCACHE_DIR", if os_family() == "windows" { "D:/sccache" } else { join(cache_home, "sccache") }))
target_dir := join(code_target_root, repo_name, tooling_slot)
cargo_build_target_dir := target_dir
build_dir := join(code_build_root, repo_name, tooling_slot)
tooling_main := if file_name(parent_directory(root)) == ".worktrees" { parent_directory(parent_directory(root)) } else { root }
path_separator := if os() == "windows" { ";" } else { ":" }
sccache_basedirs := trim(shell('''
set -euo pipefail
root=$1
printf '%s' "$root"
git -C "$root" -c core.fsmonitor=false worktree list --porcelain | while IFS= read -r line; do
    case "$line" in
        "worktree $root/.worktrees/"*)
            slot=${line#"worktree $root/.worktrees/"}
            if [[ $slot =~ ^[a-z]$ ]]; then
                printf '%s%s/.worktrees/%s' "$2" "$root" "$slot"
            fi
            ;;
    esac
done
''', replace(tooling_main, "\\", "/"), path_separator))

export CODE_TARGET_ROOT := code_target_root
export CODE_BUILD_ROOT := code_build_root
export CODE_SCCACHE_ROOT := code_sccache_root
export CARGO_TARGET_DIR := target_dir
export CARGO_BUILD_TARGET_DIR := cargo_build_target_dir
export CARGO_BUILD_BUILD_DIR := build_dir
export RUSTC_WRAPPER := "sccache"
export CARGO_BUILD_RUSTC_WRAPPER := "sccache"
export CARGO_INCREMENTAL := "0"
export SCCACHE_DIR := code_sccache_root
export SCCACHE_CACHE_SIZE := "45G"
export SCCACHE_BASEDIRS := sccache_basedirs

[positional-arguments]
cargo *args:
    @printf '[cargo] start: %s\n' "$*"
    cargo "$@"
    @printf '[cargo] done: %s\n' "$*"

# Print the selected checkout slot and effective compiler-cache paths.
build-env:
    @printf 'REPO_ROOT=%s\n' {{quote(repo_root)}}
    @printf 'WORKTREE_DIR=%s\n' {{quote(root)}}
    @printf 'WORKTREE_SLOT=%s\n' {{quote(tooling_slot)}}
    @printf 'CODE_TARGET_ROOT=%s\n' {{quote(code_target_root)}}
    @printf 'CODE_BUILD_ROOT=%s\n' {{quote(code_build_root)}}
    @printf 'CARGO_TARGET_DIR=%s\n' {{quote(target_dir)}}
    @printf 'CARGO_BUILD_TARGET_DIR=%s\n' {{quote(cargo_build_target_dir)}}
    @printf 'CARGO_BUILD_BUILD_DIR=%s\n' {{quote(build_dir)}}
    @printf 'CARGO_TERM_QUIET=%s\n' {{quote(CARGO_TERM_QUIET)}}
    @printf 'RUSTFMT_TOOLCHAIN=%s\n' {{quote(RUSTFMT_TOOLCHAIN)}}
    @printf 'RUSTC_WRAPPER=%s\n' {{quote(RUSTC_WRAPPER)}}
    @printf 'CARGO_BUILD_RUSTC_WRAPPER=%s\n' {{quote(CARGO_BUILD_RUSTC_WRAPPER)}}
    @printf 'CARGO_INCREMENTAL=%s\n' {{quote(CARGO_INCREMENTAL)}}
    @printf 'SCCACHE_DIR=%s\n' {{quote(SCCACHE_DIR)}}
    @printf 'SCCACHE_CACHE_SIZE=%s\n' {{quote(SCCACHE_CACHE_SIZE)}}
    @printf 'SCCACHE_BASEDIRS=%s\n' {{quote(SCCACHE_BASEDIRS)}}

[windows]
build-setup:
    pwsh.exe -NoLogo -NoProfile -File "{{root}}/scripts/setup-build.ps1"
