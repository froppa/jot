.DEFAULT_GOAL := help

.PHONY: help setup test build run

help:
	@printf "make setup  Verify the required Xcode toolchain\\n"
	@printf "make test   Run tests\\n"
	@printf "make build  Build .build/Jot.app\\n"
	@printf "make run    Build and open Jot\\n"

setup:
	mise trust mise.toml
	mise run setup

test:
	mise run test

build:
	mise run build

run:
	mise run run
