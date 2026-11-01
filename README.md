# Catppuccin for GRUB — personal fork (mocha, 1920×1200)

A personal fork of [catppuccin/grub](https://github.com/catppuccin/grub) retuning the **Mocha** flavor for a 1920×1200
panel (ThinkPad T14 Gen 7): readable 28px menu items, a higher menu block, a background at the panel's native size.
The theme itself is the work of the [Catppuccin org](https://github.com/catppuccin); palette, ports and docs live in
[catppuccin/catppuccin](https://github.com/catppuccin/catppuccin) — see its [wiki](https://github.com/catppuccin/catppuccin/wiki) and [catppuccin.com/palette](https://catppuccin.com/palette).

## What's different from upstream

Only the theme **assets** change, all inside `src/catppuccin-mocha-grub-theme/`; latte, frappé and macchiato match upstream.
This fork also adds `install.sh` and `MAINTAINING.md`, and rewrites this README — 8 paths against `upstream/main` in total.

| Setting | Upstream | This fork |
| --- | --- | --- |
| `boot_menu` top | `60%` | `550` (px) |
| `boot_menu` width | `480` | `800` |
| `item_height` | `36` | `54` |
| `item_spacing` | `10` | `12` |
| `item_font` | `Unifont Regular 16` | `JetBrainsMono NF Regular 28` |
| `selected_item_color` | `#CDD6F4` | `#B4BEFE` |
| background | 640×480, stretched | 1920×1200 native, solid `#1E1E2E` |
| logo | 100×100 | 160×160, resampled from the official 1544px mark |
| bundled font | `font.pf2` (Unifont) only | `jetbrainsmono-28.pf2` + `OFL.txt` |

## Install

```shell
pkexec ./install.sh
```

The installer copies the whole theme directory to `/boot/grub/themes/catppuccin-mocha`, backs up
`/etc/default/grub` to `grub.bak-<timestamp>`, rewrites `GRUB_THEME=` and runs `grub-mkconfig`.
If it exits 1 on a `grub-mkconfig` error, the theme files and `GRUB_THEME=` may already be written: fix the cause, then rerun or run `grub-mkconfig -o /boot/grub/grub.cfg`.

- `--theme-dir PATH` — install to `PATH` (absolute) instead of `/boot/grub/themes/catppuccin-mocha`
- `--no-mkconfig` — write the files and `GRUB_THEME`, skip `grub-mkconfig`
- `--dry-run` — print every step, write nothing, no root needed
- `--force` — continue if the target directory exists without a `theme.txt`
- `-h`, `--help` — show usage

Needs GRUB 2.16+, EFI boot (the tuned target), a writable `/boot/grub/themes`, and root for the run — `sudo` is disabled here, hence `pkexec`.

## Manual install

1. Clone the repo, then copy the **whole** theme directory — not just `theme.txt`:

   ```shell
   git clone https://github.com/FeiSaMa/grub.git && cd grub
   pkexec cp -a src/catppuccin-mocha-grub-theme /boot/grub/themes/catppuccin-mocha
   ```

2. In `/etc/default/grub`, set `GRUB_THEME="/boot/grub/themes/catppuccin-mocha/theme.txt"` and `GRUB_GFXMODE=1920x1200`.

3. Regenerate: `pkexec grub-mkconfig -o /boot/grub/grub.cfg`.

`theme.txt` names fonts by internal name — `terminal-font: "Unifont Regular 16"`, `item_font: "JetBrainsMono NF Regular 28"` —
which GRUB's theme loader maps to pf2 files in the theme directory; `background.png`, `logo.png`, the `select_*.png` pixmaps
and `icons/` resolve by relative name. Miss any of them and the menu loses its background, highlight bar or font.

## Upstream sync

```shell
git fetch upstream
git merge upstream/main
```

`README.md` and `MAINTAINING.md` are rewritten by this fork on purpose — on conflict, keep the fork's versions.
`theme.txt` conflicts are expected: re-apply the table above or the parameter list in [`MAINTAINING.md`](MAINTAINING.md).

## Regenerating the assets

The `python-pillow` and `grub-mkfont` commands and the `item_font` match rule are documented only in [`MAINTAINING.md`](MAINTAINING.md).

## FAQ

- **The menu is off-centre and the background looks stretched.**

  The menu geometry in `theme.txt` is tuned for a 1920×1200 panel: set `GRUB_GFXMODE=1920x1200` in `/etc/default/grub` and regenerate `grub.cfg`; on another panel, retune rather than rescale.

## 💝 Thanks to

- [Dooez](https://github.com/Dooez/ventoy-catppuccin)
- [vinceliuice](https://github.com/vinceliuice/grub2-themes)
- tuhanayim

## License

[MIT](LICENSE), © 2021-present Catppuccin and contributors; this fork keeps the same license.

`src/catppuccin-mocha-grub-theme/jetbrainsmono-28.pf2` comes from JetBrains Mono (© 2020 The JetBrains Mono Project Authors) under the SIL Open Font License 1.1, not MIT — full text in [`src/catppuccin-mocha-grub-theme/OFL.txt`](src/catppuccin-mocha-grub-theme/OFL.txt).
