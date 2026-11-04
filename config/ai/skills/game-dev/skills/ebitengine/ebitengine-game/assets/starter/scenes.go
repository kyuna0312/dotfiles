package main

import (
	"fmt"
	"image/color"
	"math"

	"github.com/hajimehoshi/ebiten/v2"
	"github.com/hajimehoshi/ebiten/v2/text/v2"
	"github.com/hajimehoshi/ebiten/v2/vector"

	"starter/world"
)

// ---------------------------------------------------------------- title

type titleScene struct{ g *Game }

func newTitleScene(g *Game) *titleScene { return &titleScene{g: g} }

func (s *titleScene) Update(g *Game) error {
	if g.input.Now.Confirm {
		g.SetScene(newPlayScene(g))
	}
	return nil
}

func (s *titleScene) Draw(screen *ebiten.Image) {
	screen.Fill(colBG)
	drawCentered(screen, "STARTER", s.g.assets.Title, screenW/2, screenH/2-40, colText)
	// Blink from the tick counter: Draw reads state, it never advances it.
	if s.g.tick/30%2 == 0 {
		drawCentered(screen, "Enter / Start / tap to play", s.g.assets.Body, screenW/2, screenH/2+30, colText)
	}
	drawCentered(screen, "v"+version, s.g.assets.Body, screenW/2, screenH-24, colText)
}

// ---------------------------------------------------------------- play

const level = `
################################################################################
#..............................................................................#
#..............................................................................#
#..............................................................................#
#..............................................................................#
#.........................................o.o.o................................#
#........................................#######...............................#
#..............................................................................#
#..........................o.o.....................................o.o.o.......#
#.........................#####...................................#######......#
#..............................................................................#
#.................o.....................o.o...............o.o..................#
#................###...................#####.............#####.................#
#..............................................................................#
#.........o.........................o..........................................#
#........###......................#####..............................####......#
#..............................................................................#
#.P.......o.o.o.o.......o.o.o.o..........o.o.o.o..........o.o.o.o..............#
#..............................................................................#
#.................................####.................................####....#
######################......############################.....###################
######################......############################.....###################
################################################################################
`

type playScene struct {
	g          *Game
	w          *world.World
	camX, camY float64
	paused     bool
}

func newPlayScene(g *Game) *playScene {
	s := &playScene{g: g, w: world.Parse(level)}
	s.camX, s.camY = s.cameraTarget()
	return s
}

func (s *playScene) Update(g *Game) error {
	in := g.input.Now
	if in.Pause {
		s.paused = !s.paused
	}
	if s.paused {
		return nil // freeze the world, keep reading input
	}
	s.w.Step(world.Input{Left: in.Left, Right: in.Right, JumpPressed: in.JumpPressed, JumpHeld: in.Jump})
	for _, e := range s.w.Events {
		switch e {
		case world.EventJump:
			g.sound.Play(g.sound.jump)
		case world.EventLand:
			g.sound.Play(g.sound.land)
		case world.EventCoin:
			g.sound.Play(g.sound.coin)
		}
	}
	s.w.Events = s.w.Events[:0]

	// Ease the camera toward its target a fixed fraction per tick.
	tx, ty := s.cameraTarget()
	s.camX += (tx - s.camX) * 0.15
	s.camY += (ty - s.camY) * 0.15
	return nil
}

// cameraTarget centres the player and clamps to the level.
func (s *playScene) cameraTarget() (float64, float64) {
	p := s.w.Player.Box
	lw, lh := s.w.Size()
	x := min(max(p.X+p.W/2-screenW/2, 0), max(lw-screenW, 0))
	y := min(max(p.Y+p.H/2-screenH/2, 0), max(lh-screenH, 0))
	return x, y
}

func (s *playScene) Draw(screen *ebiten.Image) {
	screen.Fill(colBG)
	a := s.g.assets
	// Round the camera once so every sprite moves by whole pixels together.
	cx, cy := math.Round(s.camX), math.Round(s.camY)

	// Draw only the tiles on screen. Successive DrawImage calls with the same
	// source atlas, filter and blend can be batched by Ebitengine.
	ts := float64(world.TileSize)
	x0, y0 := int(cx/ts), int(cy/ts)
	x1, y1 := int((cx+screenW)/ts), int((cy+screenH)/ts)
	op := &ebiten.DrawImageOptions{}
	cols, rows := s.w.Cells()
	for ty := max(y0, 0); ty <= min(y1, rows-1); ty++ {
		for tx := max(x0, 0); tx <= min(x1, cols-1); tx++ {
			if !s.w.Solid(tx, ty) {
				continue
			}
			op.GeoM.Reset()
			op.GeoM.Translate(float64(tx)*ts-cx, float64(ty)*ts-cy)
			screen.DrawImage(a.Tile, op)
		}
	}

	for i, c := range s.w.Coins {
		bob := math.Round(2 * math.Sin(float64(s.g.tick+i*7)/10))
		op.GeoM.Reset()
		op.GeoM.Translate(c.X-cx, c.Y-cy+bob)
		screen.DrawImage(a.Coin, op)
	}

	p := s.w.Player.Box
	op.GeoM.Reset()
	op.GeoM.Translate(math.Round(p.X-cx), math.Round(p.Y-cy))
	screen.DrawImage(a.Player, op)

	hud := &text.DrawOptions{}
	hud.GeoM.Translate(12, 8)
	hud.ColorScale.ScaleWithColor(colText)
	text.Draw(screen, fmt.Sprintf("Coins %d   [Esc] pause  [F11] fullscreen", s.w.Score), a.Body, hud)

	if s.paused {
		vector.FillRect(screen, 0, 0, screenW, screenH, color.RGBA{0, 0, 0, 0xa0}, false)
		drawCentered(screen, "PAUSED", a.Title, screenW/2, screenH/2, colText)
	}
}

// drawCentered draws one line of text centred on (x, y).
func drawCentered(dst *ebiten.Image, str string, face *text.GoTextFace, x, y float64, clr color.Color) {
	op := &text.DrawOptions{}
	op.GeoM.Translate(x, y)
	op.PrimaryAlign = text.AlignCenter
	op.SecondaryAlign = text.AlignCenter
	op.ColorScale.ScaleWithColor(clr)
	text.Draw(dst, str, face, op)
}
