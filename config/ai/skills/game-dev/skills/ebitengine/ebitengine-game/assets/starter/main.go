// Starter game for Ebitengine v2.10: title screen, a small platformer level,
// keyboard/gamepad/touch input, text, sound and pause.
//
//	go run .                          play
//	go run . -demo -shot out.png      scripted input, save the screen at tick 240, exit
package main

import (
	"flag"
	"fmt"
	"log"

	"github.com/hajimehoshi/ebiten/v2"
)

// version is stamped by release builds: go build -ldflags "-X main.version=1.2.0".
var version = "dev"

// The logical screen. Everything is drawn in these units; Ebitengine scales the
// result to the window.
const (
	screenW = 640
	screenH = 360
)

func main() {
	shot := flag.String("shot", "", "write a PNG of the screen to this path and exit (headless checks)")
	shotTick := flag.Int("shot-tick", 240, "tick at which -shot is taken")
	demo := flag.Bool("demo", false, "drive the game with a fixed input script instead of devices")
	showVersion := flag.Bool("version", false, "print the version and exit")
	flag.Parse()
	if *shotTick < 1 {
		log.Fatal("-shot-tick must be positive")
	}
	if *showVersion {
		fmt.Println(version)
		return
	}

	g, err := NewGame(Options{ShotPath: *shot, ShotTick: *shotTick, Demo: *demo})
	if err != nil {
		log.Fatal(err)
	}

	ebiten.SetWindowTitle("Starter")
	ebiten.SetWindowSize(screenW*2, screenH*2)
	ebiten.SetWindowResizingMode(ebiten.WindowResizingModeEnabled)
	if *shot != "" {
		// Exactly one Update per Draw makes the requested tick reproducible.
		// This capture mode runs as fast as possible; interactive play uses 60 TPS.
		ebiten.SetTPS(ebiten.SyncWithFPS)
		ebiten.SetVsyncEnabled(false)
		ebiten.SetWindowVisible(false)
		ebiten.SetRunnableOnUnfocused(true)
	}

	if err := ebiten.RunGame(g); err != nil {
		log.Fatal(err)
	}
}
