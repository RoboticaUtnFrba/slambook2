#!/bin/bash
set -e

export PURPLE='\033[0;35m'
export NC='\033[0m'

for exercise in $(ls -d /exercises/ch*); do \
	echo "${PURPLE}Creating directory $exercise${NC}" && \
	mkdir -p $exercise/build && \
	cd $exercise/build && \
	echo "${PURPLE}Compiling $exercise...${NC}" && \
	cmake .. && \
	make -j3; \
done

cd /exercises && /bin/bash
