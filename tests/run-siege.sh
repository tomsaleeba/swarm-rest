#!/bin/bash
# uses siege (http://download.joedog.org/siege/siege-4.0.4.tar.gz), make sure v4.x is installed
cd `dirname "$0"`
siege \
  --verbose \
  --concurrent=20 \
  --time=60S \
  --internet \
  --file=siege-urls.txt

