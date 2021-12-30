#!/usr/bin/env bash
if [[ -z "$VPN_CLIENT" || "$VPN_CLIENT" == "NONE" ]]; then
  exit 0
fi

source "$(dirname "$0")/ec2gaming.header"

echo -n "Disconnecting VPN... "
osascript "ec2gaming-vpndown.$VPN_CLIENT.scpt"
