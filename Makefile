.PHONY: all build

LPATH = "./?.lua;./?/?.lua;./?/init.lua"

build:
	yue ./weave

release: build
	mkdir -p ./build/weave
	cp weave/*.lua build/weave
	cd build && tar cvfz weave-build.tar.gz weave
	ls -lha build/weave-build.tar.gz
