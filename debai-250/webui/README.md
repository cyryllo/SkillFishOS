# debai-250 browser tuner panel

`skillfish-tunerd` is a trimmed fork of SkillFishOS's `skillfish-dashboardd`
(Python stdlib-only HTTPS daemon, PAM login, signed session cookies) that
keeps **only** the tuner module — CPU/GPU clock+voltage, fan curve, Compute
Unit rows/profiles, benchmarks, plus a small Wake-on-LAN status/toggle.
Everything else (app store, AI chat, remote desktop/terminal, ZeroTier,
auto-rules) was cut since none of it is needed or referenced by the tuner
code path.

## A real gap this fixes

The original `tuner.html` has **no login form at all** — in the full
dashboard it's opened in an iframe by `index.html`/`app.js` only *after*
that SPA shell has already handled login. Serve `tuner.html` on its own
without that shell and there is no way to ever authenticate — every
`/api/tuner*` call just 401s forever. This fork adds a small inline login
overlay directly into `tuner.html` (styled to match, no external dependency)
that calls `/api/login`/`/api/me` before showing the tuner UI, and a logout
button. This wasn't tested in a real browser as part of this change — do a
quick smoke test after installing.

## Install

```sh
sudo ../tuning/install.sh   # must come first — this panel only shells out to it
sudo ./install.sh
```

Then browse to `https://<box>:8443/` from another machine on the LAN (the
box itself has no desktop/browser in the headless setup) and log in with a
real local Linux username/password.

## Disabling login temporarily

For testing on a fully trusted LAN, you can skip PAM login entirely: set
`"auth": false` in `/etc/skillfish/tunerd.json`, then restart the service:

```sh
sudo systemctl restart skillfish-tunerd
```

With `auth: false`, every request is treated as already logged in — the
panel goes straight to the tuner UI, no login screen shown. This is a
config-only toggle, not a code change: set `"auth": true` (or remove the key
— it defaults to `true`) and restart the service to require login again.
Don't leave this off on anything but a network you fully trust.
