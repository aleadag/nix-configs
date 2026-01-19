#!/usr/bin/env bash
set -euo pipefail

revset="@"
no_verify=0

for arg in "$@"; do
  if [[ "$arg" == "--no-verify" ]]; then
    no_verify=1
  else
    revset="$arg"
  fi
done

if [[ "$no_verify" -eq 0 ]]; then
  echo "== jj status =="
  jj status
  echo
fi

echo "== jj diff -r ${revset} --git =="
jj diff -r "${revset}" --git
