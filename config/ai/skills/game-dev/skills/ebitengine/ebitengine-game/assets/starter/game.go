package main

import (
	"fmt"
	"image"
	"image/png"
	"os"

	"github.com/hajimehoshi/ebiten/v2"
	"github.com/hajimehoshi/ebiten/v2/inpututil"
)

// Scene is one screen of the game. Update changes state; Draw only reads it.
type Scene interface {
	Update(g *Game) error
	Draw(screen *ebiten.Image)
}

type Options struct {
	ShotPath string
	ShotTick int
	Demo     bool
}

// Game implements ebiten.Game and owns what every scene shares.
type Game struct {
	opts   Options
	assets *Assets
	sound  *Sound
	input  *Input

	scene, next Scene
	tick        int // number of Update calls so far: the game's clock
	shotDone    bool
	shotErr     error
}

func NewGame(opts Options) (*Game, error) {
	a, err := LoadAssets()
	if err != nil {
		return nil, err
	}
	g := &Game{opts: opts, assets: a, sound: NewSound(), input: NewInput(opts.Demo)}
	g.scene = newTitleScene(g)
	return g, nil
}

// SetScene switches scenes at the start of the next tick, never mid-frame.
func (g *Game) SetScene(s Scene) { g.next = s }

func (g *Game) Update() error {
	if g.shotDone {
		if g.shotErr != nil {
			return g.shotErr
		}
		return ebiten.Termination // ends RunGame without an error
	}
	if g.next != nil {
		g.scene, g.next = g.next, nil
	}
	g.tick++
	g.input.Update(g.tick)

	alt := ebiten.IsKeyPressed(ebiten.KeyAltLeft) || ebiten.IsKeyPressed(ebiten.KeyAltRight)
	if inpututil.IsKeyJustPressed(ebiten.KeyF11) || (alt && inpututil.IsKeyJustPressed(ebiten.KeyEnter)) {
		ebiten.SetFullscreen(!ebiten.IsFullscreen())
	}
	return g.scene.Update(g)
}

func (g *Game) Draw(screen *ebiten.Image) {
	g.scene.Draw(screen)
	if g.opts.ShotPath != "" && !g.shotDone && g.tick >= g.opts.ShotTick {
		if err := savePNG(screen, g.opts.ShotPath); err != nil {
			g.shotErr = fmt.Errorf("save screenshot: %w", err)
		}
		g.shotDone = true // Update returns Termination on the next tick
	}
}

// Layout returns a fixed logical size, so game code never deals with window
// size; Ebitengine letterboxes and scales the screen.
func (g *Game) Layout(outsideWidth, outsideHeight int) (int, int) {
	return screenW, screenH
}

// savePNG reads the screen back from the GPU. It is slow; use it for checks,
// not every frame.
func savePNG(screen *ebiten.Image, path string) error {
	b := screen.Bounds()
	img := image.NewRGBA(b)
	screen.ReadPixels(img.Pix) // premultiplied RGBA; the screen is opaque here
	f, err := os.Create(path)
	if err != nil {
		return err
	}
	if err := png.Encode(f, img); err != nil {
		f.Close()
		return err
	}
	return f.Close()
}
