#!/bin/bash

podman run --rm -v "$PWD:/app" ground $1
./linkandrun.sh
