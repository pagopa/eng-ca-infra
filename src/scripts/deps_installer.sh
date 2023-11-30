#!/bin/bash

set -e

layer_path="$1"
lambda_arch="$2"
python_version="$3"
requirements_path="$4"

#region Check if all the necessary values are present
if ! [[ $(command -v pip) ]] ; then 
    printf "%s\n" "deps_installer.sh: PIP not found"
    exit 1
fi

if [[ -z "$layer_path" ]]; then
    printf "%s\n" "deps_installer.sh: missing layer_path"
    exit 1
fi

if [[ -z "$lambda_arch" ]]; then
    printf "%s\n" "deps_installer.sh: missing lambda_arch"
    exit 1
fi

if [[ -z "$python_version" ]]; then
    printf "%s\n" "deps_installer.sh: missing python_version"
    exit 1
fi

if [[ -z "$requirements_path" ]]; then
    printf "%s\n" "deps_installer.sh: missing requirements_path"
    exit 1
fi
#endregion


# Creates the folders in which the dependencies will be stored
mkdir -p "$layer_path"/python


# Installs the deps for manylinux2014_x86 platform
pip install \
    --python "$python_version" \
    --platform manylinux2014_"$lambda_arch" \
    --target="$layer_path"/python/ \
    --implementation cp \
    --only-binary=:all:\
    -r "$requirements_path"
