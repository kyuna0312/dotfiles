// ARASAKA vertical bar — Übersicht widget (Cyberpunk 2077)
// Right-edge vertical HUD: brand, AeroSpace workspaces, clock.
// Design language lifted from arcangel0/cyberarch (cyber.scss): red glass
// panels, uppercase micro-labels with wide tracking, layered glow + inset
// shadow, cyan glowing readouts. sketchybar is horizontal-only, so the
// right-side bar lives here instead.

// One shell call: focused workspace, all workspaces, time, date.
// Tab-separated so the parser stays trivial.
export const command =
  `/bin/sh -c '` +
  `F=$(/opt/homebrew/bin/aerospace list-workspaces --focused 2>/dev/null); ` +
  `A=$(/opt/homebrew/bin/aerospace list-workspaces --all 2>/dev/null | tr "\\n" " "); ` +
  `T=$(date "+%H:%M"); ` +
  `S=$(date "+%S"); ` +
  `D=$(date "+%d %b" | tr "[:lower:]" "[:upper:]"); ` +
  `W=$(date "+%a" | tr "[:lower:]" "[:upper:]"); ` +
  `printf "%s\\t%s\\t%s\\t%s\\t%s\\t%s" "$F" "$A" "$T" "$S" "$D" "$W"` +
  `'`;

export const refreshFrequency = 1000; // 1s — aerospace query is instant

// --- ARASAKA palette (same hex as the terminal/tmux/nvim stack) ---
const C = {
  panel: "rgba(4, 3, 6, 0.55)", // cyberarch glass ground
  red: "#ff1e3c",
  redDim: "rgba(255, 30, 60, 0.45)",
  redFill: "rgba(255, 30, 60, 0.12)",
  redLine: "rgba(255, 30, 60, 0.28)",
  yellow: "#fce300",
  cyan: "#00ffc8",
  ice: "rgba(228, 240, 255, 0.58)", // cyberarch faint text
  muted: "#c25c6e",
};

// Fixed to the right edge, full height, narrow vertical column.
export const className = `
  top: 0;
  right: 0;
  width: 46px;
  height: 100%;
  box-sizing: border-box;
  background: ${C.panel};
  border-left: 1px solid ${C.red};
  box-shadow: -14px 0 26px rgba(255, 30, 60, 0.10),
              inset 0 0 28px rgba(0, 0, 0, 0.55);
  backdrop-filter: blur(22px) saturate(1.2);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: space-between;
  padding: 16px 0 18px 0;
  font-family: "Rajdhani", "Hack Nerd Font", "SF Mono", monospace;
  color: ${C.muted};
  z-index: 1;

  /* scanline overlay — subtle CRT texture */
  &::before {
    content: "";
    position: absolute;
    inset: 0;
    pointer-events: none;
    background: repeating-linear-gradient(
      0deg,
      rgba(255, 30, 60, 0.03) 0px,
      rgba(255, 30, 60, 0.03) 1px,
      transparent 1px,
      transparent 3px
    );
    z-index: 0;
  }

  /* --- brand --- */
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
    color: ${C.red};
    text-shadow: 0 0 12px ${C.redDim};
    writing-mode: vertical-rl;
    text-orientation: upright;
  }

  /* --- workspaces --- */
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
    color: ${C.muted};
    background: rgba(255, 30, 60, 0.04);
    border: 1px solid transparent;
    border-radius: 2px;
    transition: all 130ms ease;
  }
  .ws:hover {
    color: ${C.red};
    border-color: ${C.redLine};
  }
  .ws.active {
    color: ${C.red};
    background: ${C.redFill};
    border: 1px solid ${C.redDim};
    border-left: 2px solid ${C.red};
    box-shadow: 0 0 14px rgba(255, 30, 60, 0.28),
                inset 0 0 10px rgba(255, 30, 60, 0.08);
  }

  /* --- clock --- */
  .clock {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 3px;
    z-index: 1;
    padding: 8px 0 2px 0;
    border-top: 1px solid ${C.redLine};
    width: 40px;
  }
  .clock .wday {
    font-size: 8px;
    font-weight: 700;
    letter-spacing: 2px;
    color: ${C.red};
  }
  .clock .time {
    font-family: "Tektur", "Hack Nerd Font", monospace;
    color: ${C.cyan};
    font-size: 15px;
    font-weight: 700;
    letter-spacing: 1px;
    text-shadow: 0 0 8px rgba(0, 255, 200, 0.45);
  }
  .clock .sec {
    font-family: "Tektur", monospace;
    font-size: 9px;
    letter-spacing: 2px;
    color: rgba(0, 255, 200, 0.55);
  }
  .clock .date {
    font-size: 8px;
    font-weight: 700;
    letter-spacing: 1px;
    color: ${C.ice};
  }
`;

export const render = ({ output }) => {
  const [focused = "", all = "", time = "", sec = "", date = "", wday = ""] =
    (output || "").split("\t");
  const workspaces = all.trim().split(/\s+/).filter(Boolean);

  return (
    <div>
      <div className="brand">
        <div className="tag">KYUNA</div>
      </div>

      <div className="spaces">
        {workspaces.map((ws) => (
          <div
            key={ws}
            className={ws === focused.trim() ? "ws active" : "ws"}
            onClick={() =>
              window.Ubersicht.run(`/opt/homebrew/bin/aerospace workspace ${ws}`)
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
