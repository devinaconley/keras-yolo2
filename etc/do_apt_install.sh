#!/bin/bash
while IFS='' read -r line || [[ -n "$line" ]]; do
    pkgName=$(basename "$line")
    dpkg -i apt/$pkgName
done < "$1"
