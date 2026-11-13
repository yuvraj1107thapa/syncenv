package main

import (
	"os"

	"syncenv/internal/cli"
)

func main() {
	os.Exit(cli.Run(os.Args))
}
