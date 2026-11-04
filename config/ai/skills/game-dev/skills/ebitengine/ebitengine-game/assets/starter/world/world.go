// Package world holds the game rules. It does not import Ebitengine, so it can
// be unit-tested with plain `go test` and stepped deterministically.
package world

import "strings"

// TileSize is the size of one level cell in world units (pixels).
const TileSize = 16

// Fixed-step tuning, expressed per tick (Update runs 60 times per second).
const (
	gravity   = 0.35
	maxFall   = 6.0
	runSpeed  = 2.2
	jumpSpeed = 6.2
	// coyoteTicks lets a jump register shortly after walking off a ledge.
	coyoteTicks = 6
	// bufferTicks remembers a jump pressed shortly before landing.
	bufferTicks = 6
)

// Rect is an axis-aligned box in world units.
type Rect struct{ X, Y, W, H float64 }

func (r Rect) Overlaps(o Rect) bool {
	return r.X < o.X+o.W && o.X < r.X+r.W && r.Y < o.Y+o.H && o.Y < r.Y+r.H
}

// Input is the per-tick intent, already translated from devices to actions.
type Input struct {
	Left, Right bool
	JumpPressed bool // pressed this tick
	JumpHeld    bool
}

// Player is the controllable body.
type Player struct {
	Box      Rect
	VX, VY   float64
	OnGround bool
	coyote   int
	buffer   int
}

// World is one level's state.
type World struct {
	cols, rows int
	solid      []bool
	Coins      []Rect
	Player     Player
	Score      int
	Events     []Event // filled during Step; read and cleared by the caller
}

// Event tells the presentation layer what happened (for sound, particles...).
type Event int

const (
	EventJump Event = iota
	EventLand
	EventCoin
)

// Parse builds a world from rows of text: '#' solid, 'o' coin, 'P' player start.
func Parse(level string) *World {
	lines := strings.Split(strings.Trim(level, "\n"), "\n")
	w := &World{rows: len(lines)}
	for _, l := range lines {
		w.cols = max(w.cols, len(l))
	}
	w.solid = make([]bool, w.cols*w.rows)
	for y, l := range lines {
		for x, c := range l {
			px, py := float64(x*TileSize), float64(y*TileSize)
			switch c {
			case '#':
				w.solid[y*w.cols+x] = true
			case 'o':
				w.Coins = append(w.Coins, Rect{px + 4, py + 4, 8, 8})
			case 'P':
				w.Player.Box = Rect{px + 2, py + 2, 12, 14}
			}
		}
	}
	return w
}

// Size returns the level size in world units.
func (w *World) Size() (float64, float64) {
	return float64(w.cols * TileSize), float64(w.rows * TileSize)
}

// Cells returns the level size in cells.
func (w *World) Cells() (cols, rows int) { return w.cols, w.rows }

// Solid reports whether the cell (cx, cy) blocks movement. Outside is solid.
func (w *World) Solid(cx, cy int) bool {
	if cx < 0 || cy < 0 || cx >= w.cols || cy >= w.rows {
		return true
	}
	return w.solid[cy*w.cols+cx]
}

// Step advances the world by exactly one tick.
func (w *World) Step(in Input) {
	p := &w.Player
	p.VX = 0
	if in.Left {
		p.VX -= runSpeed
	}
	if in.Right {
		p.VX += runSpeed
	}

	if in.JumpPressed {
		p.buffer = bufferTicks
	} else if p.buffer > 0 {
		p.buffer--
	}
	if p.OnGround {
		p.coyote = coyoteTicks
	} else if p.coyote > 0 {
		p.coyote--
	}
	if p.buffer > 0 && p.coyote > 0 {
		p.VY = -jumpSpeed
		p.buffer, p.coyote = 0, 0
		w.Events = append(w.Events, EventJump)
	}
	// Releasing jump early cuts the rise: variable jump height.
	if !in.JumpHeld && p.VY < -jumpSpeed/2 {
		p.VY = -jumpSpeed / 2
	}
	p.VY = min(p.VY+gravity, maxFall)

	wasOnGround := p.OnGround
	w.moveX(p.VX)
	p.OnGround = false
	w.moveY(p.VY)
	if p.OnGround && !wasOnGround {
		w.Events = append(w.Events, EventLand)
	}

	kept := w.Coins[:0]
	for _, c := range w.Coins {
		if p.Box.Overlaps(c) {
			w.Score++
			w.Events = append(w.Events, EventCoin)
			continue
		}
		kept = append(kept, c)
	}
	w.Coins = kept
}

// moveX and moveY resolve one axis at a time so corners never snag.
func (w *World) moveX(dx float64) {
	p := &w.Player
	p.Box.X += dx
	if c, ok := w.hit(p.Box); ok {
		if dx > 0 {
			p.Box.X = float64(c.X*TileSize) - p.Box.W
		} else if dx < 0 {
			p.Box.X = float64((c.X + 1) * TileSize)
		}
	}
}

func (w *World) moveY(dy float64) {
	p := &w.Player
	p.Box.Y += dy
	if c, ok := w.hit(p.Box); ok {
		if dy > 0 {
			p.Box.Y = float64(c.Y*TileSize) - p.Box.H
			p.OnGround = true
		} else if dy < 0 {
			p.Box.Y = float64((c.Y + 1) * TileSize)
		}
		p.VY = 0
	}
}

type cell struct{ X, Y int }

// hit returns the first solid cell overlapping r. The tiny epsilon keeps a box
// that exactly touches a wall from counting as overlapping it.
func (w *World) hit(r Rect) (cell, bool) {
	const eps = 1e-6
	x0, y0 := int(r.X/TileSize), int(r.Y/TileSize)
	x1, y1 := int((r.X+r.W-eps)/TileSize), int((r.Y+r.H-eps)/TileSize)
	if r.X < 0 {
		x0 = -1
	}
	if r.Y < 0 {
		y0 = -1
	}
	for cy := y0; cy <= y1; cy++ {
		for cx := x0; cx <= x1; cx++ {
			if w.Solid(cx, cy) {
				return cell{cx, cy}, true
			}
		}
	}
	return cell{}, false
}
