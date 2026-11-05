#!/usr/bin/env bash
# Paul OS — create .vscode config (IntelliSense -> cross-compiler, recommended extensions)
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .vscode

cat > .vscode/c_cpp_properties.json <<'JSON'
{
  "configurations": [
    {
      "name": "PaulOS (i686-elf)",
      "compilerPath": "${env:HOME}/opt/cross/bin/i686-elf-gcc",
      "includePath": [
        "${workspaceFolder}/src/include",
        "${workspaceFolder}/src/**"
      ],
      "defines": [],
      "cStandard": "gnu11",
      "intelliSenseMode": "linux-gcc-x86",
      "compilerArgs": ["-ffreestanding", "-nostdlib"]
    }
  ],
  "version": 4
}
JSON

cat > .vscode/extensions.json <<'JSON'
{
  "recommendations": [
    "ms-vscode-remote.remote-wsl",
    "ms-vscode.cpptools",
    "13xforever.language-x86-64-assembly",
    "ms-vscode.makefile-tools"
  ]
}
JSON

echo "==> .vscode/ created. Open the project with:  code ."
