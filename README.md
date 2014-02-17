Autoproject is a simple bash script that acts as your "prompt command", and
allows you execute custom actions when you enter or leave a project directory.
For example, if you're working on a python project, you could automatically
activate your virtualenv when you enter your source directory. You could also
change your command prompt to indicate the project you're working on

To use Autoproject, place this file somewhere in your ``$PATH``

add the following lines to your .bashrc:

    source "autoproject" # this filename
    PROMPT_COMMAND="autoproject"

You can override any of the environment variables show at the top of this
script. You'll most likely want to set your own ``PROJECT_PATTERN``. This is a
regex that tells the script whether or not you're inside a project directory.
You'll need two capturing groups in the regex as well. One for the absolute path
to the project, and one for the project name (the unique identifier for the
project). See the default ``PROJECT_PATTERN`` below for an example.

If you want to change which capturing groups deterimine the project path and
project name, you can change ``PROJECT_DIR_MATCH`` and ``PROJECT_NAME_MATCH``.
If you want to get even more custom, you can set ``PROJECT_DIR_CMD`` and
``PROJECT_NAME_CMD``.

When you enter a project directory, whether it's the root project dir or any
subdir of that project, the ``$PROJECT_DIR`` and ``$PROJECT`` environment
variables will be available to you.

In order to add custom actions, define a file with an enter() function and an
exit() function. For actions that you'd like to execute for any project
directory, you can define it globally in ``~/.project``. For actions that you'd
like to define for a specific project, place the file named ``.project`` in the
``$PROJECT_DIR``.

 For example, to customize your PS1 when you enter a project, add this to your
 .project file:

    #!/bin/bash

    enter() {
        export OLD_PS1=$PS1
        export PS1="\u@\h [$PROJECT] \W \$"
    }

    leave() {
        export PS1=$OLD_PS1
        unset OLD_PS1
    }

You may also define a global directory in which you keep a set of project
scripts that are automatically loaded each time. This can help keep your
customizations more modular so that you can disable/enable features as you like.
To do this, simply define ``AUTOPROJECT_SCRIPTS_DIR`` and point it to that
directory. By default, this is set to ``~/.autoproject/autoload/``. But you may
keep them wherever you like. To easily enable/disable scripts, you can keep your
scripts in ``~/.autoproject/scripts/``, and symlink them to
``~/.autoproject/autoload/``. 

When you enter a project dir, each script in the autoload directory is executed
in order. When leave a project dir, they are executed in reverse order. So if
once script has a dependency on the other, you'll need make sure you name the
files such that they'll be in the right order (eg, prefix with
``0_firstscript``, ``1_secondsecript``, etc...).

