#!/bin/sh

export APP_REVISION="$(date +%s | md5sum | head -c 20)"

/app/bin/server
