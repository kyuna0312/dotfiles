package main

import (
	"bytes"
	"image/color"

	"github.com/hajimehoshi/ebiten/v2"
	"github.com/hajimehoshi/ebiten/v2/text/v2"
	"github.com/hajimehoshi/ebiten/v2/vector"
	"golang.org/x/image/font/gofont/goregular"
)

var (
	colBG     = color.RGBA{0x1b, 0x1e, 0x2b, 0xff}
	colTile   = color.RGBA{0x4a, 0x55, 0x6e, 0xff}
	colEdge   = color.RGBA{0x8a, 0x97, 0xb5, 0xff}
	colPlayer = color.RGBA{0xf2, 0xc1, 0x4e, 0xff}
	colCoin   = color.RGBA{0x7c, 0xe0, 0xc3, 0xff}
	colText   = color.RGBA{0xee, 0xee, 0xf2, 0xff}
)

// Assets are created once, before the game loop, and reused every frame.
// Creating images or font sources inside Update/Draw is a common slowdown.
type Assets struct {
	Title, Body *text.GoTextFace
	Tile        *ebiten.Image
	Player      *ebiten.Image
	Coin        *ebiten.Image
}

func LoadAssets() (*Assets, error) {
	// Real games embed their own font file with //go:embed. goregular is a
	// WGL4 font bundled with golang.org/x/image; use a CJK-capable font
	// for Japanese/Chinese/Korean text.
	src, err := text.NewGoTextFaceSource(bytes.NewReader(goregular.TTF))
	if err != nil {
		return nil, err
	}
	a := &Assets{
		Title: &text.GoTextFace{Source: src, Size: 40},
		Body:  &text.GoTextFace{Source: src, Size: 16},
	}

	// Placeholder art drawn once into small images. Replace with sprites
	// decoded from embedded PNGs (see references/rendering.md).
	a.Tile = ebiten.NewImage(16, 16)
	a.Tile.Fill(colTile)
	vector.FillRect(a.Tile, 0, 0, 16, 2, colEdge, false)

	a.Player = ebiten.NewImage(12, 14)
	vector.FillRect(a.Player, 0, 0, 12, 14, colPlayer, false)
	vector.FillRect(a.Player, 7, 3, 2, 3, colBG, false)

	a.Coin = ebiten.NewImage(8, 8)
	vector.FillCircle(a.Coin, 4, 4, 4, colCoin, true)
	return a, nil
}
