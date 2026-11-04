# Ads, purchases and store services

Read when the user requests these integrations. Ebitengine has no built-in ad or
billing SDK. Native mobile hosts and browser pages connect their platform SDKs
to Go. A game should not acquire ads, purchases or an online backend merely
because this reference exists.

## Pick the integration actually needed

| Distribution | Common integration |
| --- | --- |
| Desktop paid download | storefront handles checkout; game-side SDK only for selected features such as DLC or achievements |
| Browser portal | portal JavaScript adapter for required lifecycle/ad APIs |
| Android/iOS | native host with billing/ad SDK, bridged to the Go game |
| Offline/test build | explicit unavailable/fake service, preserving the intended base game |

Verify current rules for the target store, region and program, including billing,
restoration, privacy and child-directed games. Do not hardcode universal policy
claims: the [Google Play payments policy](https://support.google.com/googleplay/android-developer/answer/9858738)
and [Apple review guidelines](https://developer.apple.com/app-store/review/guidelines/)
have conditions and change over time. Keep policy/legal choices outside generic
engine code.

## Game-side contract

Use an asynchronous service boundary. Give operations request IDs and purchases
transaction IDs; queue results for `Update` and apply each grant at most once.
A useful result distinguishes reward earned, ad dismissed, unavailable, cancelled,
pending, purchased and failed. Do not treat dismissal as reward or a submitted
purchase as an entitlement.

For ads:

- Rewarded and interstitial are different operations. Give the adapter separate
  methods; never implement interstitial by calling a rewarded-ad method.
- Pause gameplay and audio while covered, but keep the service/event pump alive.
  Aggregate pause reasons so closing an ad does not undo a user's pause or
  app-background state.
- Correlate callbacks with the active request. Deduplicate reward notifications,
  ignore stale results and support reward/close callbacks in either documented
  order. A timeout must recover UI without inventing a reward; define how late
  valid rewards are reconciled.
- Handle no-fill, load failure, cancellation and scene exit. The unavailable
  build must return a result, not leave a permanent loading overlay.
- Place interstitials at appropriate breaks and show rewarded ads only after a
  player action that explains the reward. Follow the portal/network's actual
  lifecycle requirements.

For purchases:

- Validate and reconcile entitlements using the platform's documented flow.
  Deduplicate transactions, persist grants and handle pending/deferred states,
  refunds/revocation and restore/reinstall as applicable.
- Finish/acknowledge transactions only according to the SDK's delivery rules.
  Separate a durable entitlement from a consumable grant.
- Test repeated callbacks and restart between payment and grant. A fake
  `Purchased` callback test does not establish a working store purchase.

## Native mobile bridge

Put a small bindable API in the package passed to `ebitenmobile bind` (the package
that calls `mobile.SetGame`). Native methods dispatch SDK/UI work to the host's
UI thread and return promptly; native callbacks post results to a synchronized
Go inbox. `Update` drains the inbox. Avoid accessing game state from callbacks.

`gomobile` supports a restricted API subset; keep the boundary to simple strings,
booleans, supported numeric/byte values and bindable interfaces. Keep game-only
structs, channels and service implementations outside the exported surface.
Generate bindings with the pinned Ebitengine/gomobile toolchain and inspect the
actual generated Java/Objective-C API rather than assuming names or that a Go
build proves bindability. Follow [Ebitengine mobile setup](https://ebitengine.org/en/documents/mobile.html).

Install native services before use or synchronize access explicitly. The host
must also forward lifecycle/pause and persist progress before background
termination; normal game shutdown is not guaranteed on mobile.

## Browser adapter

Keep a platform-specific `//go:build js && wasm` file for `syscall/js` calls and
a JavaScript adapter tied to the selected portal's current SDK. The adapter
normalizes its actual callbacks/promises into the game-side results above.

- Check both adapter existence and method type. Validate callback arguments.
- `js.FuncOf` callbacks must return promptly; do not block them on a promise.
  Track callback ownership and release functions only after JS will no longer
  call them. Handle exceptions, missing callbacks and cancellation explicitly.
- Match separate rewarded/interstitial methods and lifecycle hooks. Test with
  the real portal's sandbox as well as an unavailable/fake adapter.
- After ads, restore audio according to gesture/browser policy and the player's
  mute setting, and restore input focus. Do not assume autoplay permission alone
  unlocks audio.

## Acceptance tests

Use a fake service with delayed results to test: no fill; close without reward;
reward before/after close; duplicate reward; stale result for a prior request;
scene exit; background plus ad pause; timeout and late result; repeated purchase;
pending purchase; restore; restart after durable grant. Then run actual sandbox
ads/purchases on each promised platform. Record which of these were executed;
Go compilation or generated bindings alone do not verify an SDK integration.
