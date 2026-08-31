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
  width: 56,              // column width in px

  // Cyberpunk: Lucy palette (swap these hexes for any theme you like)
  colors: {
    bg:     "#0a0e1a",    // panel ground (deep midnight navy glass)
    accent: "#37e0ff",    // primary — brand, borders, workspace hover (neon cyan)
    active: "#00d4d4",    // clock time, active-hover (teal)
    now:    "#ff45d4",    // active workspace chip ("now" accent, neon magenta)
    fg:     "#c8d6f0",    // date / body text (icy blue-white)
    muted:  "#5a6a8c",    // weekday, seconds
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
  background: linear-gradient(
    ${CONFIG.side === "right" ? "270deg" : "90deg"},
    ${alpha(K.bg, 0.78)} 0%,
    ${alpha(K.bg, 0.62)} 100%
  );
  border-${CONFIG.side === "right" ? "left" : "right"}: 1px solid ${alpha(K.accent, 0.9)};
  box-shadow: ${CONFIG.side === "right" ? "-16px" : "16px"} 0 34px ${alpha(K.accent, 0.12)},
              inset 0 0 34px rgba(0, 0, 0, 0.5);
  backdrop-filter: blur(26px) saturate(1.3);
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
      ${alpha(K.accent, 0.025)} 0px,
      ${alpha(K.accent, 0.025)} 1px,
      transparent 1px,
      transparent 3px
    );
    z-index: 0;
  }

  /* --- brand (top) --- */
  .brand {
    display: flex;
    flex-direction: column;
    align-items: center;
    z-index: 1;
  }
  .brand .tag {
    font-size: 12px;
    font-weight: 700;
    letter-spacing: 4px;
    color: ${K.accent};
    text-shadow: 0 0 14px ${alpha(K.accent, 0.55)};
    writing-mode: vertical-rl;
    text-orientation: upright;
  }
  .brand .rule {
    width: 14px;
    height: 2px;
    margin-top: 12px;
    border-radius: 2px;
    background: ${alpha(K.accent, 0.5)};
    box-shadow: 0 0 8px ${alpha(K.accent, 0.5)};
  }

  /* --- workspaces (pinned to the true vertical center of the bar) --- */
  .spaces {
    position: absolute;
    top: 50%;
    left: 0;
    right: 0;
    transform: translateY(-50%);
    display: flex;
    flex-direction: column;
    justify-content: center;
    gap: 9px;
    align-items: center;
    z-index: 1;
  }
  .ws {
    position: relative;
    width: 34px;
    height: 34px;
    line-height: 34px;
    text-align: center;
    font-size: 14px;
    font-weight: 700;
    letter-spacing: 1px;
    color: ${K.muted};
    background: ${alpha(K.accent, 0.05)};
    border: 1px solid ${alpha(K.accent, 0.08)};
    border-radius: 8px;
    cursor: pointer;
    transition: all 150ms cubic-bezier(0.4, 0, 0.2, 1);
  }
  .ws:hover {
    color: ${K.active};
    border-color: ${alpha(K.accent, 0.4)};
    background: ${alpha(K.accent, 0.1)};
  }
  .ws.active {
    color: ${K.now};
    background: ${alpha(K.now, 0.16)};
    border: 1px solid ${alpha(K.now, 0.5)};
    box-shadow: 0 0 16px ${alpha(K.now, 0.32)},
                inset 0 0 12px ${alpha(K.now, 0.1)};
  }
  /* the "now" tick on the active chip's inner edge */
  .ws.active::before {
    content: "";
    position: absolute;
    top: 50%;
    ${CONFIG.side === "right" ? "left" : "right"}: -9px;
    transform: translateY(-50%);
    width: 3px;
    height: 16px;
    border-radius: 2px;
    background: ${K.now};
    box-shadow: 0 0 8px ${K.now};
  }

  /* --- clock (pinned to the bottom) --- */
  .clock {
    margin-top: auto;
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 2px;
    z-index: 1;
    padding-top: 14px;
    position: relative;
    width: ${CONFIG.width - 16}px;
  }
  /* glowing divider above the clock */
  .clock::before {
    content: "";
    position: absolute;
    top: 0;
    left: 10%;
    right: 10%;
    height: 1px;
    background: linear-gradient(
      90deg,
      transparent,
      ${alpha(K.accent, 0.6)},
      transparent
    );
  }
  .clock .wday {
    font-size: 8px;
    font-weight: 700;
    letter-spacing: 3px;
    color: ${alpha(K.muted, 0.9)};
    margin-bottom: 1px;
  }
  .clock .time {
    font-family: "Tektur", "Hack Nerd Font", monospace;
    color: ${K.active};
    font-size: 17px;
    font-weight: 700;
    letter-spacing: 1px;
    line-height: 1.1;
    text-shadow: 0 0 10px ${alpha(K.active, 0.45)};
  }
  .clock .sec {
    font-family: "Tektur", monospace;
    font-size: 9px;
    font-weight: 600;
    letter-spacing: 3px;
    color: ${alpha(K.active, 0.55)};
    margin-top: 1px;
  }
  .clock .date {
    font-size: 8px;
    font-weight: 700;
    letter-spacing: 2px;
    color: ${alpha(K.fg, 0.9)};
    margin-top: 5px;
  }
`;

export const render = ({ output }) => {
  const [focused = "", all = "", time = "", sec = "", date = "", wday = ""] =
    (output || "").split("\t");
  const workspaces = all.trim().split(/\s+/).filter(Boolean);

  return (
    <div
      style={{
        position: "absolute",
        inset: 0,
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        padding: "20px 0 22px 0",
        boxSizing: "border-box",
      }}
    >
      {CONFIG.brand ? (
        <div className="brand">
          <div className="tag">{CONFIG.brand}</div>
          <div className="rule" />
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
