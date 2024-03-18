#!/usr/bin/env bash

curl -LO https://ollama.com/download/Ollama-darwin.zip
unzip Ollama-darwin.zip
mv Ollama.app /Applications
open /Applications/Ollama.app

