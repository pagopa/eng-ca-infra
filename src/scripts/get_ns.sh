#!/bin/bash
NAMESERVERS=$(dig +short NS "$1" | paste -s -d, -)
jq -n --arg nameservers "$NAMESERVERS" '{"nameservers":$nameservers}'