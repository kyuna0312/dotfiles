# Roblox client/server model & communication (current engine)

Depth behind the Luau skill: how code is split across machines, the messaging
primitives, replication timing, and tags/attributes.

## Where code runs

| Container | Runs on | Use for |
|-----------|---------|---------|
| `ServerScriptService` | server | authoritative game logic (`Script`) |
| `ServerStorage` | server | assets/data the client must never see |
| `ReplicatedStorage` | both | remotes, `ModuleScript`s, shared assets |
| `StarterPlayerScripts` | client | persistent client logic (`LocalScript`) |
| `StarterCharacterScripts` | client | per-character client logic |
| `StarterGui` | client | UI scripts |

The server simulates the authoritative world; each client renders its own view and
sends input. Roblox always filters client→server replication, so a client cannot
directly change server-owned state — it can only ask via a remote.

## RemoteEvent vs RemoteFunction

Both live in `ReplicatedStorage` so both sides can find them.

- **RemoteEvent** — fire-and-forget, one-way, asynchronous.
  - Client→server: `remote:FireServer(args)` → server handles `remote.OnServerEvent:Connect(function(player, args) ... end)`. The `player` is injected by the engine and is trustworthy; everything after it is not.
  - Server→client: `remote:FireClient(player, args)` or `remote:FireAllClients(args)` → client handles `remote.OnClientEvent:Connect(function(args) ... end)`.

- **RemoteFunction** — request/response, the caller **yields** for a return value.
  - Client→server: `local result = remote:InvokeServer(args)`; server defines `remote.OnServerInvoke = function(player, args) return ... end`.
  - Prefer `RemoteEvent` for most things. A `RemoteFunction` invoked **on a client by the server** is dangerous: a malicious client can never return or can error, hanging the server. Only invoke client→server, validate, and consider timeouts.

### Security checklist for every server handler

1. Validate argument **types** (`type(x) ~= "number"` → reject).
2. Validate argument **ranges/identity** (does this item exist? can this player afford it? do they own the thing they're acting on?).
3. Rate-limit if the action is expensive (track last-call time per player).
4. Never send secret data (prices, loot tables, other players' private data) to the
   client "to be returned"; decide it on the server.

## BindableEvent / BindableFunction

For messaging **within the same machine** (server-to-server scripts, or client-to-
client), use `BindableEvent`/`BindableFunction`. They do not cross the network and
carry no security boundary — don't use them to replace remotes.

## Replication timing & WaitForChild

When a client starts, the data model streams in over time, so a child you expect
may not exist yet. On the client, use:

```lua
local remote = ReplicatedStorage:WaitForChild("BuyItem")        -- yields until it exists
local gui = player:WaitForChild("PlayerGui"):WaitForChild("HUD")
```

`WaitForChild` accepts an optional timeout; without one it warns after ~5 seconds.
On the server, instances you created exist immediately, so direct indexing is fine.

## Connections & cleanup

`:Connect` returns an `RBXScriptConnection`. Long-lived connections that are never
disconnected leak and can fire on destroyed instances:

```lua
local conn = part.Touched:Connect(onTouch)
-- when done:
conn:Disconnect()

-- One-shot: auto-disconnects after the first fire.
part.Touched:Once(onTouchOnce)

-- Clean up everything tied to a player on leave:
Players.PlayerRemoving:Connect(function(player) cleanupFor(player) end)
```

## Attributes & CollectionService tags

- **Attributes** store typed metadata directly on an instance and replicate to
  clients: `part:SetAttribute("Damage", 25)`, `part:GetAttribute("Damage")`, and
  `part:GetAttributeChangedSignal("Damage"):Connect(...)`. Good for designer-tweakable
  values without extra `Value` objects.
- **CollectionService tags** group instances by string tag for data-driven systems:

```lua
local CollectionService = game:GetService("CollectionService")
for _, door in CollectionService:GetTagged("Door") do
    setupDoor(door)
end
CollectionService:GetInstanceAddedSignal("Door"):Connect(setupDoor)
```

Tags + attributes together let you build behavior systems that pick up any tagged
instance (placed by designers in Studio) without hard-coding references.

## Studio testing

- **Test** (F5) / **Test Here** — your avatar in a single session; toggle between
  the Client and Server views while it runs.
- **Run** (F8) — simulation with no avatar.
- **Server & Clients** — separate server + up to 8 client windows; the only way to
  properly test replication and remotes. Use the Server/Client view toggle and the
  Output window to confirm which side a message came from.
