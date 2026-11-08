# LCARS for Doom Emacs

A `doom-themes` theme matching the other targets. `install.sh doom` symlinks
`themes/doom-lcars-theme.el` into `~/.config/doom/themes/`, which Doom adds to
`custom-theme-load-path`. If your Doom config lives elsewhere (`$DOOMDIR`),
copy or link the file into its `themes/` directory instead.

## Use

In `config.el`:

```elisp
(setq doom-theme 'doom-lcars)
```

Then restart Emacs, or run `M-x doom/reload-theme`. The theme needs the
`doom-themes` package, which Doom's `:ui doom` module installs.

## Options

`doom-lcars-padded-modeline` adds padding to the mode-line, like the other Doom
themes. Set it to `t` for 4px, or to an integer.

## Writing in Org

`writing/.dir-locals.el` sets up Org buffers for writing prose, such as blog
posts for a Hugo site. It is not installed by `install.sh`. Link or copy it
into the root of the project:

```sh
ln -s ~/workspace/waltervargas/lcars/targets/doom/writing/.dir-locals.el \
      ~/workspace/walterbio/walterdotbio/.dir-locals.el
```

In Org buffers under that directory it gives:

- Serif body text in variable pitch, using ET Book if installed, else
  Liberation Serif. Code blocks, tables, keywords and line numbers stay in the
  fixed-pitch font.
- Headings in bold Liberation Sans Narrow, the LCARS font, in stepped sizes.
- Hidden emphasis markers, pretty entities, soft-wrapped lines, extra line
  spacing, and flyspell with the `en_US` dictionary.
- Hugo shortcodes such as `{{< sidenote >}}` highlighted with the
  `doom-lcars-hugo-shortcode` face.

Emacs asks once before it runs the `eval` form. Answer `!` to trust the file
permanently. If `mixed-pitch` or `visual-fill-column` are installed, the file
uses them: `mixed-pitch` for the font switch, and `visual-fill-column` to
center the text column at 88 characters.
