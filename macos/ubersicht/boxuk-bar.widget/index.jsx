// Aeroline — a slim vertical status bar for Übersicht + AeroSpace.
// A right-edge (or left-edge) column: brand, AeroSpace workspaces, clock.
// Glass panel, uppercase micro-labels, layered glow + inset shadow, scanline.
// Standalone project: https://github.com/kyuna0312/aeroline
//
// ─── CONFIGURE ME ────────────────────────────────────────────────────────────
// Everything you'd want to tweak lives in CONFIG. Colors are plain hex; the
// translucent variants (glow, fills, borders) are derived automatically.
const CONFIG = {
  brand: "KYUNA",        // vertical label at the top (set "" to hide)
  side: "right",          // "right" or "left"
  width: 46,              // column width in px

  // Box UK Contrast palette (swap these hexes for any theme you like)
  colors: {
    bg:     "#161e22",    // panel ground (rendered as translucent glass)
    accent: "#017c9d",    // primary — brand, borders, workspace hover (cyan)
    active: "#15b8ae",    // clock time, active-hover (teal)
    now:    "#b750ae",    // active workspace chip ("now" accent, purple)
    fg:     "#b8c7cc",    // date / body text (grey-blue)
    muted:  "#60778c",    // weekday, seconds
  },

  aerospacePath: "/opt/homebrew/bin/aerospace", // `which aerospace`
};
// ─────────────────────────────────────────────────────────────────────────────

// hex "#rrggbb" → "r, g, b" so we can build rgba() at any alpha.
const rgb = (hex) => {
  const n = parseInt(hex.replace("#", ""), 16);
  return `${(n >> 16) & 255}, ${(n >> 8) & 255}, ${n & 255}`;
};
const alpha = (hex, a) => `rgba(${rgb(hex)}, ${a})`;

const K = CONFIG.colors;

// One shell call: focused workspace, all workspaces, time, date.
// Tab-separated so the parser stays trivial.
export const command =
  `/bin/sh -c '` +
  `F=$(${CONFIG.aerospacePath} list-workspaces --focused 2>/dev/null); ` +
  `A=$(${CONFIG.aerospacePath} list-workspaces --all 2>/dev/null | tr "\\n" " "); ` +
  `T=$(date "+%H:%M"); ` +
  `S=$(date "+%S"); ` +
  `D=$(date "+%d %b" | tr "[:lower:]" "[:upper:]"); ` +
  `W=$(date "+%a" | tr "[:lower:]" "[:upper:]"); ` +
  `printf "%s\\t%s\\t%s\\t%s\\t%s\\t%s" "$F" "$A" "$T" "$S" "$D" "$W"` +
  `'`;

export const refreshFrequency = 1000; // 1s — aerospace query is instant

export const className = `
  top: 0;
  ${CONFIG.side}: 0;
  width: ${CONFIG.width}px;
  height: 100%;
  box-sizing: border-box;
  background: ${alpha(K.bg, 0.66)};
  border-${CONFIG.side === "right" ? "left" : "right"}: 1px solid ${K.accent};
  box-shadow: ${CONFIG.side === "right" ? "-14px" : "14px"} 0 26px ${alpha(K.accent, 0.1)},
              inset 0 0 28px rgba(0, 0, 0, 0.55);
  backdrop-filter: blur(22px) saturate(1.2);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: space-between;
  padding: 16px 0 18px 0;
  font-family: "Rajdhani", "Hack Nerd Font", "SF Mono", monospace;
  color: ${K.muted};
  z-index: 1;

  /* scanline overlay — subtle CRT texture */
  &::before {
    content: "";
    position: absolute;
    inset: 0;
    pointer-events: none;
    background: repeating-linear-gradient(
      0deg,
      ${alpha(K.accent, 0.03)} 0px,
      ${alpha(K.accent, 0.03)} 1px,
      transparent 1px,
      transparent 3px
    );
    z-index: 0;
  }

  .brand {
    display: flex;
    flex-direction: column;
    align-items: center;
    z-index: 1;
  }
  .brand .tag {
    font-size: 11px;
    font-weight: 700;
    letter-spacing: 3px;
    color: ${K.accent};
    text-shadow: 0 0 12px ${alpha(K.accent, 0.5)};
    writing-mode: vertical-rl;
    text-orientation: upright;
  }

  .spaces {
    display: flex;
    flex-direction: column;
    gap: 8px;
    align-items: center;
    z-index: 1;
  }
  .ws {
    position: relative;
    width: 30px;
    height: 30px;
    line-height: 30px;
    text-align: center;
    font-size: 13px;
    font-weight: 700;
    letter-spacing: 1px;
    color: ${K.muted};
    background: ${alpha(K.accent, 0.04)};
    border: 1px solid transparent;
    border-radius: 2px;
    transition: all 130ms ease;
  }
  .ws:hover {
    color: ${K.active};
    border-color: ${alpha(K.accent, 0.32)};
  }
  .ws.active {
    color: ${K.now};
    background: ${alpha(K.now, 0.14)};
    border: 1px solid ${alpha(K.now, 0.45)};
    border-left: 2px solid ${K.now};
    box-shadow: 0 0 14px ${alpha(K.now, 0.28)},
                inset 0 0 10px ${alpha(K.now, 0.08)};
  }

  .clock {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 3px;
    z-index: 1;
    padding: 8px 0 2px 0;
    border-top: 1px solid ${alpha(K.accent, 0.32)};
    width: ${CONFIG.width - 6}px;
  }
  .clock .wday {
    font-size: 8px;
    font-weight: 700;
    letter-spacing: 2px;
    color: ${alpha(K.muted, 0.85)};
  }
  .clock .time {
    font-family: "Tektur", "Hack Nerd Font", monospace;
    color: ${K.active};
    font-size: 15px;
    font-weight: 700;
    letter-spacing: 1px;
    text-shadow: 0 0 8px ${alpha(K.active, 0.4)};
  }
  .clock .sec {
    font-family: "Tektur", monospace;
    font-size: 9px;
    letter-spacing: 2px;
    color: ${alpha(K.muted, 0.85)};
  }
  .clock .date {
    font-size: 8px;
    font-weight: 700;
    letter-spacing: 1px;
    color: ${alpha(K.fg, 0.85)};
  }
`;

export const render = ({ output }) => {
  const [focused = "", all = "", time = "", sec = "", date = "", wday = ""] =
    (output || "").split("\t");
  const workspaces = all.trim().split(/\s+/).filter(Boolean);

  return (
    <div>
      {CONFIG.brand ? (
        <div className="brand">
          <div className="tag">{CONFIG.brand}</div>
        </div>
      ) : (
        <div />
      )}

      <div className="spaces">
        {workspaces.map((ws) => (
          <div
            key={ws}
            className={ws === focused.trim() ? "ws active" : "ws"}
            onClick={() =>
              window.Ubersicht.run(`${CONFIG.aerospacePath} workspace ${ws}`)
            }
          >
            {ws}
          </div>
        ))}
      </div>

      <div className="clock">
        <div className="wday">{wday}</div>
        <div className="time">{time}</div>
        <div className="sec">:{sec}</div>
        <div className="date">{date}</div>
      </div>
    </div>
  );
};
