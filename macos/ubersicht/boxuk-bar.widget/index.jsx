// BOX UK vertical bar — Übersicht widget (Box UK Contrast / rainglow)
// Right-edge vertical HUD: brand, AeroSpace workspaces, clock.
// Palette: Box UK Contrast (Material-Ocean family) — a calm deep blue-grey
// + teal theme that's easy on the eyes. Layout language from
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

// --- Box UK Contrast palette (rainglow), exact hex ---
// bg #161e22 · fg #b8c7cc · cyan #017c9d · teal #15b8ae
// green #019d76 · yellow #ffcb6e · coral #f77669 · purple #b750ae
const C = {
  panel: "rgba(22, 30, 34, 0.66)", // #161e22 blue-grey glass
  cyan: "#017c9d", // primary accent (Box UK cyan)
  cyanBright: "#15b8ae", // teal
  cyanDim: "rgba(1, 124, 157, 0.50)",
  cyanFill: "rgba(1, 124, 157, 0.14)",
  cyanLine: "rgba(1, 124, 157, 0.32)",
  magenta: "#b750ae", // workspace-active secondary (purple)
  magentaDim: "rgba(183, 80, 174, 0.45)",
  magentaFill: "rgba(183, 80, 174, 0.14)",
  yellow: "#ffcb6e",
  fg: "rgba(184, 199, 204, 0.62)", // #b8c7cc soft grey-blue
  muted: "#4f6269",
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
  box-shadow: -14px 0 26px rgba(1, 124, 157, 0.10),
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
      rgba(1, 124, 157, 0.03) 0px,
      rgba(1, 124, 157, 0.03) 1px,
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
    background: rgba(1, 124, 157, 0.04);
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
    box-shadow: 0 0 14px rgba(183, 80, 174, 0.28),
                inset 0 0 10px rgba(183, 80, 174, 0.08);
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
    text-shadow: 0 0 8px rgba(21, 184, 174, 0.40);
  }
  .clock .sec {
    font-family: "Tektur", monospace;
    font-size: 9px;
    letter-spacing: 2px;
    color: rgba(1, 124, 157, 0.60);
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
