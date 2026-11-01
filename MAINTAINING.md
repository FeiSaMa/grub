# Maintaining this fork

`FeiSaMa/grub` forks [catppuccin/grub](https://github.com/catppuccin/grub) and only retunes **mocha** for a
1920x1200 ThinkPad T14 panel: upstream's 16px font is unreadable there, the menu sits too high and its narrow
background bands stretch. Other flavors, `README.md`, `LICENSE` and `.github/` stay untouched, so merges stay cheap.

## What differs

Inside `src/catppuccin-mocha-grub-theme/`:

- `theme.txt` — menu `top=550`, `width=800`, `item_height=54`, `item_spacing=12`, `selected_item_color=#B4BEFE`,
  `item_font="JetBrainsMono NF Regular 28"`, logo `top=340 left=50%-80`, countdown `top=870`.
- `background.png` — 1920x1200 solid `#1E1E2E`.
- `logo.png` — 160x160, downsampled from the official 1544px mark.
- `jetbrainsmono-28.pf2` — `grub-mkfont` bitmap; internal name `JetBrainsMono NF Regular 28` (see below).
- `OFL.txt` — verbatim JetBrains Mono licence; no Reserved Font Name declared, family name unchanged.

Plus `install.sh`: copies the whole theme dir into `/boot/grub/themes/catppuccin-mocha` (hence `OFL.txt` arrives;
a hand-copied `/boot` tree may lack it and keep stray `theme.txt.orig`), backs up `/etc/default/grub`, rewrites
`GRUB_THEME`; `--dry-run` writes nothing.

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
