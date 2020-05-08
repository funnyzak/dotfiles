# Potato’s dotfiles

My macOS environment: zsh, Git etc.

## Installation

(Fork this repository if you want to use my dotfiles.)

Prerequisites:

1. [Install Xcode Command Line Tools](http://railsapps.github.io/xcode-command-line-tools.html).
2. [Generate SSH key](https://help.github.com/articles/generating-ssh-keys/).
3. [Install Homebrew](http://brew.sh/).

Then run these commands in the terminal:

```
brew install git
brew install n
n lts
git clone git@github.com:funnyzak/dotfiles.git ~/dotfiles
cd ~/dotfiles
./sync.py
npm install
```

Now you can run scripts like `setup/zsh.sh` or `setup/osx.sh` to install other stuff.

## Updating

```bash
dotfiles
```

## Notes

You can use any file extensions in `tilde/` to invoke proper syntax highlighting in code editor.

## Resources

- [GitHub ❤ ~/](http://dotfiles.github.io/)
- [Mathias’s dotfiles](https://github.com/mathiasbynens/dotfiles)
- [Jan Moesen’s dotfiles](https://github.com/janmoesen/tilde)
- [Nicolas Gallagher’s dotfiles](https://github.com/necolas/dotfiles)
- [Zach Holman’s dotfiles](https://github.com/holman/dotfiles)
- [Yet Another Dotfile Repo](https://github.com/skwp/dotfiles)
- [Jacob Gillespie’s dotfiles](https://github.com/jacobwgillespie/dotfiles)