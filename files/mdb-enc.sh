#!/bin/bash
node=$1

# will exit with failure (which will fail the compile) if not found
/usr/local/bin/mdb endpoint dump --enc "$node" 2>/dev/null

