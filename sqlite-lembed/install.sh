#!/bin/sh
set -e

if [ -n "$NO_COLOR" ]; then
    BOLD=""
    RESET=""
else
    BOLD="\033[1m"
    RESET="\033[0m"
fi


usage() {
    cat <<EOF
sqlite-hello-install 0.0.1-alpha.4

USAGE:
    $0 [static|loadable] [--target=target] [--prefix=path]

OPTIONS:
    --target
            Specify a different target platform to install. Available targets: linux-x86_64, macos-aarch64, macos-x86_64

    --prefix
            Specify a different directory to save the binaries. Defaults to the current working directory.
EOF
}




current_target() {
  if [ "$OS" = "Windows_NT" ]; then
    # TODO disambiguate between x86 and arm windows
    target="windows-x86_64"
    return 0
  fi
  case $(uname -sm) in
  "Darwin x86_64") target=macos-x86_64 ;;
  "Darwin arm64") target=macos-aarch64 ;;
  "Linux x86_64") target=linux-x86_64 ;;
  *) target=$(uname -sm);;
  esac
}



process_arguments() {
  while [[ $# -gt 0 ]]; do
      case "$1" in
          --help)
              usage
              exit 0
              ;;
          --target=*)
              target="\${1#*=}"
              ;;
          --prefix=*)
              prefix="\${1#*=}"
              ;;
          static|loadable)
              type="$1"
              ;;
          *)
              echo "Unrecognized option: $1"
              usage
              exit 1
              ;;
      esac
      shift
  done
  if [ -z "$type" ]; then
    type=loadable
  fi
  if [ "$type" != "static" ] && [ "$type" != "loadable" ]; then
      echo "Invalid type '$type'. It must be either 'static' or 'loadable'."
      usage
      exit 1
  fi
  if [ -z "$prefix" ]; then
    prefix="$PWD"
  fi
  if [ -z "$target" ]; then
    current_target
  fi
}




main() {
    local type=""
    local target=""
    local prefix=""
    local url=""
    local checksum=""

    process_arguments "$@"

    echo "${BOLD}Type${RESET}: $type"
    echo "${BOLD}Target${RESET}: $target"
    echo "${BOLD}Prefix${RESET}: $prefix"

    case "$target-$type" in
    "linux-x86_64-loadable")
      url="https://github.com/asg017/sqlite-lembed/releases/download/v0.0.1-alpha.4/sqlite-lembed-0.0.1-alpha.4-loadable-linux-x86_64.tar.gz"
      checksum="01bf71a6402c1bcd76bce7245ccfd9757203874a3cdd0f7e65fa36ab8dd26d56"
      ;;
    "macos-x86_64-loadable")
      url="https://github.com/asg017/sqlite-lembed/releases/download/v0.0.1-alpha.4/sqlite-lembed-0.0.1-alpha.4-loadable-macos-x86_64.tar.gz"
      checksum="be525a795a6971284b1d3c113cd0dad08f75c273bd37eaaa851010872f6c26dc"
      ;;
    "macos-aarch64-loadable")
      url="https://github.com/asg017/sqlite-lembed/releases/download/v0.0.1-alpha.4/sqlite-lembed-0.0.1-alpha.4-loadable-macos-aarch64.tar.gz"
      checksum="4d12a3ee76920e9f9f626c8b9bc9fbc74f1e265ca16c44fbfd2574bd7a459183"
      ;;
    *)
      echo "Unsupported platform $target" 1>&2
      exit 1
      ;;
    esac

    extension="\${url##*.}"

    if [ "$extension" = "zip" ]; then
      tmpfile="$prefix/tmp.zip"
    else
      tmpfile="$prefix/tmp.tar.gz"
    fi

    curl --fail --location --progress-bar --output "$tmpfile" "$url"

    if ! echo "$checksum $tmpfile" | sha256sum --check --status; then
      echo "Checksum fail!"  1>&2
      rm $tmpfile
      exit 1
    fi

    if [ "$extension" = "zip" ]; then
      unzip "$tmpfile" -d $prefix
      rm $tmpfile
    else
      tar -xzf "$tmpfile" -C $prefix
      rm $tmpfile
    fi

    echo "✅ $target $type binaries installed at $prefix."
}



main "$@"
