# Maintaining this fork

`FeiSaMa/grub` forks [catppuccin/grub](https://github.com/catppuccin/grub) and only retunes **mocha** for a 1920x1200
ThinkPad T14 panel: upstream's 16px font is unreadable there, the menu sits too high and its narrow background bands
stretch. Other flavors and `LICENSE` stay untouched, so merges stay cheap.

## What differs

8 paths against `upstream/main`:

- `src/catppuccin-mocha-grub-theme/theme.txt` — menu `top=550`, `width=800`, `item_height=54`, `item_spacing=12`,
  `selected_item_color=#B4BEFE`, `item_font="JetBrainsMono NF Regular 28"`, logo `top=340`, countdown `top=870`.
- `src/catppuccin-mocha-grub-theme/background.png` — 1920x1200 solid `#1E1E2E`.
- `src/catppuccin-mocha-grub-theme/logo.png` — 160x160, downsampled from the official 1544px mark.
- `src/catppuccin-mocha-grub-theme/jetbrainsmono-28.pf2` + `OFL.txt` — `grub-mkfont` bitmap (internal name
  `JetBrainsMono NF Regular 28`) and the verbatim JetBrains Mono licence, no Reserved Font Name declared.
- `install.sh` — whole-dir install to `/boot/grub/themes/catppuccin-mocha` (so `OFL.txt` arrives; a hand-copied
  `/boot` tree may lack it), `/etc/default/grub` backup, `GRUB_THEME` rewrite; `--dry-run` writes nothing.
- `README.md` + `MAINTAINING.md` — both rewritten for fork usage on purpose: on conflict keep this fork's versions.
  Upstream's `<details>` flavor previews and its Ventoy section are intentionally dropped; see the upstream repo.

## Syncing with upstream

```shell
git fetch upstream && git merge upstream/main
```

Conflicts are expected only in `theme.txt`; keep this fork's values, then run `bash install.sh --dry-run`.

## Regenerating background, logo and font

PNGs need `python-pillow` (`pacman -S python-pillow`), the font `grub` + `ttf-jetbrains-mono-nerd`; at the repo root:

```shell
cd src/catppuccin-mocha-grub-theme
curl -fsSLO https://raw.githubusercontent.com/catppuccin/catppuccin/main/assets/logos/exports/1544x1544_circle.png
python -c "from PIL import Image as I; I.new('RGB',(1920,1200),'#1E1E2E').save('background.png')"
python -c "from PIL import Image as I; I.open('1544x1544_circle.png').convert('RGBA').resize((160,160),I.LANCZOS).save('logo.png')"
grub-mkfont -s 28 -n 'JetBrainsMono NF' \
  -o jetbrainsmono-28.pf2 /usr/share/fonts/TTF/JetBrainsMonoNerdFont-Regular.ttf
file jetbrainsmono-28.pf2   # must print: GRUB2 font "JetBrainsMono NF Regular 28"
```

The internal NAME is `-n` (family only) + style `Regular` + size `28` — repeating style/size in `-n` double-counts it.
Any mismatch with `item_font` silently falls back to the default font; a new panel size also means retuning the geometry.
