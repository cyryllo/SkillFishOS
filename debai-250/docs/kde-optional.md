# Optional: adding bare KDE Plasma on top

The default `debai-250` install is headless — no display server, no
compositor, panel reachable only via a browser from another device on the
LAN. If you later want a local desktop on the box itself (e.g. to plug in a
monitor directly), here's the minimal path — **not** the SkillFishOS desktop
experience, just bare upstream KDE Plasma from Debian's own repos.

```sh
sudo apt-get install -y plasma-desktop sddm
sudo systemctl enable sddm
```

That's it — no SkillFishOS theming, panels, wallpapers, or bundled apps get
pulled in; this is stock Debian's `plasma-desktop` package plus a login
manager. `plasma-desktop` is deliberately used instead of the full
`kde-plasma-desktop`/`kde-full` metapackages, which drag in a much larger set
of KDE applications (mail client, PIM suite, games, etc.) you almost
certainly don't want on a single-purpose tuning box.

If you only want to *use* the browser panel locally without a full desktop
session, an even lighter option is a kiosk-style setup: a minimal Wayland/X
session that launches nothing but a browser pointed at
`https://localhost:8443/` — worth considering before committing to a full
Plasma install if all you need is the panel on the box's own screen.

Reminder: none of this is required for the kernel or tuning stack — both are
fully headless-compatible on their own. This is purely a convenience layer,
add it only if you find you actually want it.
