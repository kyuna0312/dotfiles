// ARASAKA vertical bar — Übersicht widget (Cyberpunk 2077)
// A right-edge vertical bar: AeroSpace workspaces + clock, ARASAKA palette.
// sketchybar is horizontal-only, so the right-side bar lives here instead.

// One shell call: focused workspace, all workspaces, and the time.
// Tab-separated so the parser stays trivial.
export const command =
  `/bin/sh -c '` +
  `F=$(/opt/homebrew/bin/aerospace list-workspaces --focused 2>/dev/null); ` +
  `A=$(/opt/homebrew/bin/aerospace list-workspaces --all 2>/dev/null | tr "\\n" " "); ` +
  `T=$(date "+%H:%M"); ` +
  `D=$(date "+%d %b"); ` +
  `printf "%s\\t%s\\t%s\\t%s" "$F" "$A" "$T" "$D"` +
  `'`;

export const refreshFrequency = 1000; // 1s — cheap, aerospace query is instant

// --- ARASAKA palette (same hex as the terminal/tmux/nvim stack) ---
const C = {
  bg: "rgba(8, 0, 2, 0.95)",   // #080002 translucent black-red
  surface: "#1a060a",
  overlay: "#3a0f16",
  red: "#ff1e3c",
  yellow: "#fce300",
  cyan: "#00ffc8",
  fg: "#ff4d5e",
  muted: "#c25c6e",
};

// Fixed to the right edge, full height, narrow vertical column.
export const className = `
  top: 0;
  right: 0;
  width: 56px;
  height: 100%;
  box-sizing: border-box;
  background: ${C.bg};
  border-left: 2px solid ${C.red};
  backdrop-filter: blur(20px);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: space-between;
  padding: 18px 0;
  font-family: "Hack Nerd Font", "SF Mono", monospace;
  color: ${C.fg};
  z-index: 1;

  .brand {
    color: ${C.red};
    font-size: 20px;
    font-weight: bold;
  }
  .spaces {
    display: flex;
    flex-direction: column;
    gap: 10px;
    align-items: center;
  }
  .ws {
    width: 30px;
    height: 30px;
    line-height: 30px;
    text-align: center;
    font-size: 14px;
    border-radius: 8px;
    color: ${C.muted};
    background: ${C.surface};
    transition: all 120ms ease;
  }
  .ws.active {
    color: #080002;
    background: ${C.red};
    font-weight: bold;
    box-shadow: 0 0 10px ${C.red};
  }
  .clock {
    text-align: center;
    line-height: 1.3;
  }
  .clock .time {
    color: ${C.yellow};
    font-size: 15px;
    font-weight: bold;
  }
  .clock .date {
    color: ${C.cyan};
    font-size: 10px;
  }
`;

export const render = ({ output }) => {
  const [focused = "", all = "", time = "", date = ""] = (output || "").split("\t");
  const workspaces = all.trim().split(/\s+/).filter(Boolean);

  return (
    <div>
      <div className="brand">⌁</div>

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
        <div className="time">{time}</div>
        <div className="date">{date}</div>
      </div>
    </div>
  );
};
