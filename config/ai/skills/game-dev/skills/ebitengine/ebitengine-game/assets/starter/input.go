package main

import (
	"github.com/hajimehoshi/ebiten/v2"
	"github.com/hajimehoshi/ebiten/v2/inpututil"
)

// Actions is what the game reacts to. Devices are mapped onto actions in one
// place, so scenes never test raw keys.
type Actions struct {
	Left, Right bool
	Jump        bool // held
	JumpPressed bool // pressed this tick
	Confirm     bool // pressed this tick
	Pause       bool // pressed this tick
}

type Input struct {
	Now     Actions
	demo    bool
	pads    []ebiten.GamepadID // reused buffers: no allocation per tick
	touches []ebiten.TouchID
}

func NewInput(demo bool) *Input { return &Input{demo: demo} }

// Update must be called from Game.Update: "just pressed" state is per tick.
func (in *Input) Update(tick int) {
	if in.demo {
		in.Now = demoActions(tick)
		return
	}
	var a Actions
	key := ebiten.IsKeyPressed
	just := inpututil.IsKeyJustPressed

	a.Left = key(ebiten.KeyArrowLeft) || key(ebiten.KeyA)
	a.Right = key(ebiten.KeyArrowRight) || key(ebiten.KeyD)
	a.Jump = key(ebiten.KeySpace) || key(ebiten.KeyZ) || key(ebiten.KeyArrowUp) || key(ebiten.KeyW)
	a.JumpPressed = just(ebiten.KeySpace) || just(ebiten.KeyZ) || just(ebiten.KeyArrowUp) || just(ebiten.KeyW)
	a.Confirm = just(ebiten.KeyEnter) || just(ebiten.KeySpace)
	a.Pause = just(ebiten.KeyEscape) || just(ebiten.KeyP)

	in.pads = ebiten.AppendGamepadIDs(in.pads[:0])
	for _, id := range in.pads {
		if !ebiten.IsStandardGamepadLayoutAvailable(id) {
			continue // unknown mapping: offer rebinding instead of guessing
		}
		btn := func(b ebiten.StandardGamepadButton) bool { return ebiten.IsStandardGamepadButtonPressed(id, b) }
		jbtn := func(b ebiten.StandardGamepadButton) bool { return inpututil.IsStandardGamepadButtonJustPressed(id, b) }
		stick := ebiten.StandardGamepadAxisValue(id, ebiten.StandardGamepadAxisLeftStickHorizontal)
		a.Left = a.Left || btn(ebiten.StandardGamepadButtonLeftLeft) || stick < -0.4
		a.Right = a.Right || btn(ebiten.StandardGamepadButtonLeftRight) || stick > 0.4
		a.Jump = a.Jump || btn(ebiten.StandardGamepadButtonRightBottom)
		a.JumpPressed = a.JumpPressed || jbtn(ebiten.StandardGamepadButtonRightBottom)
		a.Confirm = a.Confirm || jbtn(ebiten.StandardGamepadButtonRightBottom) || jbtn(ebiten.StandardGamepadButtonCenterRight)
		a.Pause = a.Pause || jbtn(ebiten.StandardGamepadButtonCenterRight)
	}

	// Touch: left third = left, right third = right, middle = jump/confirm.
	in.touches = ebiten.AppendTouchIDs(in.touches[:0])
	for _, id := range in.touches {
		x, _ := ebiten.TouchPosition(id)
		switch {
		case x < screenW/3:
			a.Left = true
		case x > screenW*2/3:
			a.Right = true
		default:
			a.Jump = true
		}
	}
	in.touches = inpututil.AppendJustPressedTouchIDs(in.touches[:0])
	for _, id := range in.touches {
		a.Confirm = true // any new touch can start the title screen
		if x, _ := ebiten.TouchPosition(id); x >= screenW/3 && x <= screenW*2/3 {
			a.JumpPressed, a.Confirm = true, true
		}
	}
	in.Now = a
}

// demoActions is a fixed script so headless runs are reproducible.
func demoActions(tick int) Actions {
	return Actions{
		Confirm:     tick == 30,
		Right:       tick > 60 && tick%160 < 120,
		Jump:        tick%90 < 18,
		JumpPressed: tick%90 == 0,
	}
}
