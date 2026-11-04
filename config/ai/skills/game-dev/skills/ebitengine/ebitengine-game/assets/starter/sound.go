package main

import (
	"encoding/binary"
	"math"

	"github.com/hajimehoshi/ebiten/v2/audio"
)

// One audio context per process, at one sample rate. Author or convert all
// sound files to this rate (see references/audio.md).
const sampleRate = 48000

type Sound struct {
	ctx        *audio.Context
	jump, coin []byte // decoded once: 32-bit float, little endian, stereo
	land       []byte
	Volume     float64
}

func NewSound() *Sound {
	return &Sound{
		ctx:    audio.NewContext(sampleRate),
		jump:   synth(0.09, 330, 660, 0.4, 1),
		land:   synth(0.05, 140, 90, 0.9, 2),
		coin:   synth(0.14, 988, 1319, 0.15, 3),
		Volume: 0.6,
	}
}

// Play starts a short effect. A new Player per effect is cheap and lets the
// same sound overlap itself; never reuse one Player for rapid repeats.
func (s *Sound) Play(pcm []byte) {
	p := s.ctx.NewPlayerF32FromBytes(pcm)
	p.SetVolume(s.Volume)
	p.Play()
}

// synth makes a placeholder effect: a pitch sweep with a noise click at the
// start so the onset is audible. Replace with designed sounds or files.
func synth(seconds, f0, f1, noise float64, seed uint32) []byte {
	n := int(seconds * sampleRate)
	out := make([]byte, n*8)
	phase := 0.0
	r := seed*2654435761 + 1
	for i := 0; i < n; i++ {
		t := float64(i) / sampleRate
		u := t / seconds
		f := f0 + (f1-f0)*u
		phase += 2 * math.Pi * f / sampleRate
		r = r*1664525 + 1013904223
		white := float64(r>>8)/float64(1<<24)*2 - 1
		env := math.Exp(-t * 30)
		click := noise * white * math.Exp(-t*900)
		v := float32((0.5*math.Sin(phase)+0.2*math.Sin(3*phase))*env + click)
		binary.LittleEndian.PutUint32(out[i*8:], math.Float32bits(v*0.5))
		binary.LittleEndian.PutUint32(out[i*8+4:], math.Float32bits(v*0.5))
	}
	return out
}
