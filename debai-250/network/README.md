# Wake-on-LAN

Makes the box wakeable from a fully powered-off state by sending a magic
packet to its MAC address from another device on the LAN (e.g. `wakeonlan
<mac>` on Linux, or most router/NAS admin panels).

Not part of the CU/SMU tuning stack — this is a generic NIC feature, unrelated
to the BC-250-specific pieces in `../tuning/`. Split out into its own
directory since it addresses a different concern (network/power management)
and could in principle be reused on any box, not just a BC-250.

## What this installs

- `enable-wol.sh` → `/usr/local/bin/skillfish-enable-wol` — detects the
  primary NIC (the one used for the default route) and runs `ethtool -s
  <nic> wol g` to turn on magic-packet wake.
- `skillfish-wol.service` — runs that script once at every boot.
- `70-skillfish-wol.rules` (udev) — re-runs it whenever a NIC is (re)added,
  since some drivers reset the WoL flag on link renegotiation, cable replug,
  or module reload; the boot-time service alone isn't always enough.

Plain `ethtool -s wol g` by itself does **not** persist across reboots —
that's the actual gap this closes; without the systemd unit + udev rule,
you'd have to re-run it by hand after every restart.

## Install

```sh
sudo ./install.sh
```

## Important: BIOS/UEFI setting required too

The OS-side setting above only matters if the board is already willing to
power on from a magic packet at the firmware level. On most boards you also
need to enable **Wake-on-LAN** / **PME (Power Management Event)** /
"Power On By PCI-E/PCI" in the BIOS/UEFI setup, and the PSU needs to keep
standby power available (relevant on some smaller/passive builds). Without
that firmware-side setting, `ethtool` will report WoL as enabled and
everything here will look correctly configured, but the board will simply
stay off when a magic packet arrives — check the firmware setting first if
wake doesn't work.

## Verify

```sh
sudo ethtool <nic> | grep Wake-on   # look for "g" in the current setting
```

Then, from another machine on the same LAN, after fully shutting this box
down:

```sh
wakeonlan <mac-address>
```
