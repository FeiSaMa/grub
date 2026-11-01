# Maintaining this fork

`FeiSaMa/grub` forks [catppuccin/grub](https://github.com/catppuccin/grub) and only retunes **mocha**
for a 1920x1200 ThinkPad T14 panel: at that size upstream's 16px font is unreadable, the menu sits
too high, and stretching upstream's small solid background bands. Other flavors, `README.md`, `LICENSE`
and `.github/` are untouched, so upstream merges stay cheap.

## What differs

Inside `src/catppuccin-mocha-grub-theme/`:

- `theme.txt` — menu `top=550`, `width=800`, `item_height=54`, `item_spacing=12`,
  `selected_item_color=#B4BEFE`, `item_font="JetBrainsMono NF Regular 28"`, logo
  `top=340 left=50%-80`, countdown `top=870`.
- `background.png` — 1920x1200 solid `#1E1E2E`.
- `logo.png` — 160x160, downsampled from the official 1544px mark.
- `jetbrainsmono-28.pf2` — `grub-mkfont` bitmap; internal name must stay
  `JetBrainsMono NF Regular 28` because `theme.txt` references it.
- `OFL.txt` — verbatim JetBrains Mono licence; no Reserved Font Name declared, family name unchanged.

Plus `install.sh` (repo root): installs into `/boot/grub/themes/catppuccin-mocha`, backs up
`/etc/default/grub`, rewrites `GRUB_THEME`; `--dry-run` writes nothing.

## Syncing with upstream

```shell
git fetch upstream && git merge upstream/main
```

Conflicts are expected only in `theme.txt`; upstream never touches the assets added here. Keep this
fork's values, then run `bash install.sh --dry-run`.

## Changing resolution or font size

Regenerate together: `background.png` (new panel size), `logo.png` (proportional to the new menu),
`jetbrainsmono-28.pf2` (`grub-mkfont -s <size>`, note the internal name) and `theme.txt` (`item_font`,
`top`/`left`/`width`/`height`/`item_height`/`item_spacing`, label `top`).

Font licence: `src/catppuccin-mocha-grub-theme/OFL.txt`.
