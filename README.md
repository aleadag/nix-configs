# dotfiles - Configuration as Code

My dotfiles to help me setup my machine in minutes using ~~[yadm](https://yadm.io/)~~
[HM](https://github.com/nix-community/home-manager).

There is also an [article](https://sspai.com/post/66894) in Chinese explained why and how to use it.

## Rules

- Automate everything, configuration as code.
- Prefer to `nix` whenever possible.
  - `yay` or `brew` only for OS specific packages.
  - Migrate to home-manager.

## Additional Configs

### `zsh`

Via https://tanguy.ortolo.eu/blog/article25/shrc

Zsh always executes zshenv. Then, depending on the case:

- run as a login shell, it executes zprofile;
- run as an interactive, it executes zshrc;
- run as a login shell, it executes zlogin.

At the end of a login session, it executes zlogout, but in reverse order, the
user-specific file first, then the system-wide one, constituting a chiasmus
with the zlogin files.

https://nix-community.github.io/home-manager/options.html#opt-programs.zsh.loginExtra
https://nix-community.github.io/home-manager/options.html#opt-programs.zsh.logoutExtra

Happy hacking!
