#!/bin/bash

set -e

OS=$(uname -s)
ARCH=$(uname -m)
BOLD="\033[1m"
RESET="\033[0m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"

printf "${BOLD}${YELLOW}Starting environment setup...${RESET}\n"

if [ "$OS" == "Linux" ]; then
  printf "${GREEN}Detected OS: Linux${RESET}\n"
  sudo apt-get update
  sudo apt-get install -y curl wget git m4 build-essential pkg-config libffi-dev libgmp-dev libssl-dev zlib1g-dev
elif [ "$OS" == "Darwin" ]; then
  printf "${GREEN}Detected OS: macOS${RESET}\n"
  brew update
  brew install curl wget git gmp pkg-config openssl
else
  printf "${RED}Unsupported OS: $OS${RESET}\n"
  exit 1
fi

if ! command -v opam &> /dev/null; then
  printf "${YELLOW}OPAM not found. Installing...${RESET}\n"
  case "$OS" in
    Linux)
      sudo apt-get install -y opam
      ;;
    Darwin)
      brew install opam
      ;;
    *)
      printf "${RED}Unsupported OS: $OS${RESET}\n"
      exit 1
      ;;
  esac
else
  printf "${GREEN}OPAM is already installed.${RESET}\n"
fi

printf "${YELLOW}Initializing OPAM...${RESET}\n"
opam init --disable-sandboxing -y
opam switch create 5.2.1 -y
opam switch 5.2.1
eval $(opam env)

printf "${YELLOW}Installing OCaml dependencies...${RESET}\n"
opam install -y dune yojson lwt cohttp-lwt-unix ppx_deriving ocamlfind sqlite3 digestif base-threads
opam install -y mirage mirage-crypto mirage-runtime mirage-clock-unix
opam install -y irmin irmin-mirage irmin-http irmin-unix
opam install -y conduit-lwt tls logs fmt
opam install -y alcotest ounit bisect_ppx merlin ocp-indent utop

printf "${YELLOW}Verifying installation...${RESET}\n"
ocaml --version
opam --version
dune --version

printf "${GREEN}Environment setup complete.${RESET}\n"