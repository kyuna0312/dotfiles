// LUCY vertical bar — Übersicht widget (Cyberpunk: Edgerunners)
// Right-edge vertical HUD: brand, AeroSpace workspaces, clock.
// Palette: solarized-osaka (craftzdog/solarized-osaka.nvim) — a cool
// teal/cyan cyberpunk that's calm on the eyes. Layout language from
// arcangel0/cyberarch: glass panels, uppercase micro-labels with wide
// tracking, layered glow + inset shadow, glowing readouts.
// sketchybar is horizontal-only, so the right-side bar lives here instead.

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

// --- solarized-osaka palette (LUCY / Edgerunners), exact hex ---
// bg #00141a · fg #839495 · cyan #2aa298 · magenta #d33682
// green #859900 · yellow #b28600 · orange #ca4c16 · red #dc312e
const C = {
  panel: "rgba(0, 20, 26, 0.62)", // #00141a teal-black glass
  cyan: "#2aa298", // primary accent (calm teal)
  cyanBright: "#4fd1c5",
  cyanDim: "rgba(42, 162, 152, 0.45)",
  cyanFill: "rgba(42, 162, 152, 0.12)",
  cyanLine: "rgba(42, 162, 152, 0.28)",
  magenta: "#d33682", // workspace-active secondary
  magentaDim: "rgba(211, 54, 130, 0.45)",
  magentaFill: "rgba(211, 54, 130, 0.14)",
  yellow: "#b28600",
  fg: "rgba(131, 148, 149, 0.62)", // #839495 muted grey-blue
  muted: "#5a7375",
};

// Fixed to the right edge, full height, narrow vertical column.
export const className = `
  top: 0;
  right: 0;
  width: 46px;
  height: 100%;
  box-sizing: border-box;
  background: ${C.panel};
  border-left: 1px solid ${C.cyan};
  box-shadow: -14px 0 26px rgba(42, 162, 152, 0.10),
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
      rgba(42, 162, 152, 0.03) 0px,
      rgba(42, 162, 152, 0.03) 1px,
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
    color: ${C.cyan};
    text-shadow: 0 0 12px ${C.cyanDim};
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
    background: rgba(42, 162, 152, 0.04);
    border: 1px solid transparent;
    border-radius: 2px;
    transition: all 130ms ease;
  }
  .ws:hover {
    color: ${C.cyanBright};
    border-color: ${C.cyanLine};
  }
  .ws.active {
    color: ${C.magenta};
    background: ${C.magentaFill};
    border: 1px solid ${C.magentaDim};
    border-left: 2px solid ${C.magenta};
    box-shadow: 0 0 14px rgba(211, 54, 130, 0.28),
                inset 0 0 10px rgba(211, 54, 130, 0.08);
  }

  /* --- clock --- */
  .clock {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 3px;
    z-index: 1;
    padding: 8px 0 2px 0;
    border-top: 1px solid ${C.cyanLine};
    width: 40px;
  }
  .clock .wday {
    font-size: 8px;
    font-weight: 700;
    letter-spacing: 2px;
    color: ${C.magenta};
  }
  .clock .time {
    font-family: "Tektur", "Hack Nerd Font", monospace;
    color: ${C.cyanBright};
    font-size: 15px;
    font-weight: 700;
    letter-spacing: 1px;
    text-shadow: 0 0 8px rgba(79, 209, 197, 0.40);
  }
  .clock .sec {
    font-family: "Tektur", monospace;
    font-size: 9px;
    letter-spacing: 2px;
    color: rgba(42, 162, 152, 0.60);
  }
  .clock .date {
    font-size: 8px;
    font-weight: 700;
    letter-spacing: 1px;
    color: ${C.fg};
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
