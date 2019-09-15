#!/bin/sh
sed -i "s|{{APIURL}}|$APIURL|g" public/apidoc/api_*
node --max-old-space-size=256 --max-semi-space-size=2 command.js