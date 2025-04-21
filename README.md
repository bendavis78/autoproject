# Autoproject

Autoproject is a simple zsh script that runs during the [precmd hook][1], and allows
you to execute custom actions when you enter or leave a project directory. For
example, if you're working on a python project, you could automatically activate
your virtualenv when you enter your source directory. You could also change your
command prompt to indicate the project you're working on. Any changes to your
environment are dropped once you exit the project directory.

## Installation

To use Autoproject, place the following in your `.zshrc`:

```sh
source "$XDG_CONFIG_HOME/zsh/autoproject.zsh"
precmd() {
    autoproject::init;
}
```

Note: XDG environment variables are used for various path names. If your system
does not define these, you will need to add the following to your .zshrc (use
whatever ptaths you wish):

```sh
XDG_CONFIG_HOME=$HOME/.config
XDG_DATA_HOME=$HOME/.local/share
XDG_STATE_HOME=$HOME/.local/state
```

## Basic Usage

To use in a project, put a file called `.projectrc` in your project directory.
The contents are a .zsh file that is sourced when you enter your project, so you
may export variables, define functions, call commands, etc in that file.

When you enter that directory, your .projectrc will be sourced, along with any
`use` configs you have defined (see "Helper Functions" below).

For example:

```sh
use virtualenv;

export MY_ENV_VAR="foo"

runtests() {
    ./.venv/bin/python -m pytest
}
```

This will source the `virtualenv` script in your autoproject configs dir, export
the environment variable `MY_ENV_VAR` and the function `runtests`.

This occurs within a subshell in zsh. Once you exit the directory, the subshell
is automatically exited.

## Features

### Environment Variables

When you enter a project directory, Autoproject sets these environment variables:

- `PROJECT_DIR`: The full path to the project directory (where `.projectrc` is located)
- `PROJECT`: The name of the project (basename of the project directory)
- `PROJECTRC`: The full path to the `.projectrc` file

### Helper Functions

- `use`: Load a configuration from `$AUTOPROJECT_CONFIGS_DIR`. For example,
  `use virtualenv` will source the `virtualenv` script from the configs dir.
- `autoproject::reload`: Reload the current project environment.

This allows you to define reusable functions to use across different project.
See `examples` for more.

### Exit Hooks

You can register functions to be executed when leaving a project by adding them
to the `autoproject_on_exit` array:

```sh
autoproject_on_exit+=(my_cleanup_function)
```

## Configuration

Autoproject uses XDG directories for configuration:

- `$XDG_CONFIG_HOME/autoproject`: Configuration files
- `$XDG_DATA_HOME/autoproject`: Data files
- `$XDG_STATE_HOME/autoproject`: State files

### Default Configurations

You can set up default configurations to be loaded for all projects by setting
the `AUTOPROJECT_DEFAULTS` array in your `.zshrc` before sourcing
autoproject.zsh:

```sh
AUTOPROJECT_DEFAULTS=(base.zsh git.zsh)
source "$XDG_CONFIG_HOME/zsh/autoproject.zsh"
```

## Examples

### Node.js Project

Create a "use config" in `$XDG_CONFIG_HOME/autoproject/node`:

```sh
export PATH="$PROJECT_DIR/node_modules/.bin:$PATH"
export NODE_ENV="development"
```

In your project's `.projectrc`:

```sh
use node
export startserver() {
    npx run dev
}
```

## Security

When you enter a directory with a `.projectrc` file for the first time, or when
the contents of `.projectrc` changes, you will be prompted before sourcing that
file. However, changes to configs that are auto-sourced using `use()` or
`AUTOPROJECT_DEFAULTS` are currently not tracked. Be extra careful when
referencing these scripts.


[1]: https://zsh.sourceforge.io/Doc/Release/Functions.html#Hook-Functions
