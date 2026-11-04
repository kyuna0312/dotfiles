package world

import (
	"fmt"
	"slices"
	"testing"
)

const testLevel = `
##########
#........#
#.P...o..#
##########
`

func settle(w *World) {
	for i := 0; i < 30; i++ {
		w.Step(Input{})
	}
}

func TestPlayerLandsOnFloor(t *testing.T) {
	w := Parse(testLevel)
	settle(w)
	if !w.Player.OnGround {
		t.Fatal("player should rest on the floor")
	}
	if got, want := w.Player.Box.Y+w.Player.Box.H, float64(3*TileSize); got != want {
		t.Fatalf("feet at %v, want %v", got, want)
	}
}

func TestJumpLeavesGroundAndReturns(t *testing.T) {
	w := Parse(testLevel)
	settle(w)
	w.Events = nil
	w.Step(Input{JumpPressed: true, JumpHeld: true})
	if w.Player.OnGround || w.Player.VY >= 0 {
		t.Fatal("jump did not start")
	}
	for i := 0; i < 120; i++ {
		w.Step(Input{JumpHeld: true})
	}
	if !w.Player.OnGround {
		t.Fatal("player never landed")
	}
	if len(w.Events) < 2 || w.Events[0] != EventJump {
		t.Fatalf("events %v", w.Events)
	}
}

func TestWallStopsPlayer(t *testing.T) {
	w := Parse(testLevel)
	settle(w)
	for i := 0; i < 200; i++ {
		w.Step(Input{Left: true})
	}
	if w.Player.Box.X != TileSize {
		t.Fatalf("player at x=%v, want flush with the wall at %v", w.Player.Box.X, TileSize)
	}
}

func TestCoinIsCollectedOnce(t *testing.T) {
	w := Parse(testLevel)
	settle(w)
	for i := 0; i < 200; i++ {
		w.Step(Input{Right: true})
	}
	if w.Score != 1 || len(w.Coins) != 0 {
		t.Fatalf("score %d, coins left %d", w.Score, len(w.Coins))
	}
}

func TestStepIsDeterministic(t *testing.T) {
	run := func() Player {
		w := Parse(testLevel)
		for i := 0; i < 300; i++ {
			w.Step(Input{Right: i%40 < 25, JumpPressed: i%50 == 0, JumpHeld: i%50 < 10})
		}
		return w.Player
	}
	if run() != run() {
		t.Fatal("same inputs produced different states")
	}
}

// More headroom than testLevel: the small fixture hits its ceiling immediately
// and cannot distinguish the two jump heights.
const tallLevel = `
##############
#............#
#............#
#............#
#............#
#............#
#............#
#............#
#.P..........#
##############
`

func TestReleaseShortensJump(t *testing.T) {
	peak := func(held bool) float64 {
		w := Parse(tallLevel)
		settle(w)
		w.Step(Input{JumpPressed: true, JumpHeld: true})
		y := w.Player.Box.Y
		for i := 0; i < 90; i++ {
			w.Step(Input{JumpHeld: held})
			y = min(y, w.Player.Box.Y)
		}
		return y
	}
	if high, low := peak(true), peak(false); high >= low-10 {
		t.Fatalf("held jump peak %v, released jump peak %v: expected a taller held jump", high, low)
	}
}

func TestBufferedJumpStartsAfterLanding(t *testing.T) {
	w := Parse(tallLevel)
	w.Player.Box.Y = 9*TileSize - w.Player.Box.H - 1
	w.Player.VY = 2
	w.Step(Input{JumpPressed: true, JumpHeld: true})
	if !w.Player.OnGround {
		t.Fatal("test setup should land on the press tick")
	}
	w.Step(Input{JumpHeld: true})
	if w.Player.OnGround || w.Player.VY >= 0 {
		t.Fatal("jump pressed before landing was not buffered")
	}
}

func TestCoyoteJumpHasLimitedWindow(t *testing.T) {
	for _, delay := range []int{2, 10} {
		t.Run(fmt.Sprint(delay), func(t *testing.T) {
			w := Parse(tallLevel)
			settle(w)
			// Remove the floor after establishing ground contact.
			for x := 1; x < w.cols-1; x++ {
				w.solid[(w.rows-1)*w.cols+x] = false
			}
			// Leave room to fall: outside the level is solid and would
			// otherwise provide a second floor one tile below this ledge.
			w.rows += 20
			w.solid = append(w.solid, make([]bool, w.cols*20)...)
			for i := 0; i < delay; i++ {
				w.Step(Input{})
			}
			w.Events = nil
			w.Step(Input{JumpPressed: true, JumpHeld: true})
			jumped := slices.Contains(w.Events, EventJump)
			if jumped != (delay < coyoteTicks) {
				t.Fatalf("jump after %d ticks off ground: %v", delay, jumped)
			}
		})
	}
}
