# LCARS for VS Code

A colour theme matching the sway, kitty and foot targets. It runs anywhere
VS Code does, but isn't installed by `install.sh`, because VS Code extensions
are packaged and installed separately.

## Install

From this directory (needs Node.js):

```sh
npx @vscode/vsce@3.2.2 package --allow-missing-repository --skip-license -o lcars.vsix
code --install-extension lcars.vsix
```

Then choose **LCARS** under Preferences → Theme → Color Theme.

After changing the theme, raise `version` in `package.json` and repeat these
steps.
