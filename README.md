# polylith-mode

An Emacs minor mode for navigating and interacting with Polylith architecture projects.

## Overview

Polylith is a component-based architecture for Clojure projects that separates functionality into reusable components and bases. This package provides tools to make working with Polylith projects in Emacs more efficient.

## Features

- Navigate quickly to components and bases within a Polylith workspace
- Switch seamlessly between source and test files
- Run build commands (like uberjar) on selected projects
- Fully customizable directory structure to fit your Polylith workspace setup

## Installation

### Manual Installation

1. Download `polylith-mode.el` to your local machine
2. Add the following to your Emacs init file:

```elisp
(add-to-list 'load-path "/path/to/directory/containing/polylith-mode")
(require 'polylith-mode)
(polylith-mode 1)  ; Enable the mode globally
```

### Using use-package

```elisp
(use-package polylith-mode
  :load-path "/path/to/directory/containing/polylith-mode"
  :config
  (polylith-mode 1))
```

## Configuration

The mode is designed to work with Polylith workspaces. You'll need to set the path to your workspace:

```elisp
;; Set workspace directory
(setq polylith-mode-workspace-directory "/path/to/your/workspace/")

;; Optionally customize directory names if your structure differs
(setq polylith-mode-components-directory-name "components")
(setq polylith-mode-bases-directory-name "bases")
(setq polylith-mode-projects-directory-name "projects")
```

## Usage

### Key Bindings

| Shortcut | Description |
|----------|-------------|
| `C-c p c` | Find and open a component |
| `C-c p b` | Find and open a base |
| `C-c p C` | Jump to components directory |
| `C-c p u` | Run clojure uberjar command |
| `C-c t` | Toggle between source and test files |

### Commands

- `polylith-mode-find-component`: Interactively select and open a component
- `polylith-mode-find-base`: Interactively select and open a base
- `polylith-mode-jump-to-components-dir`: Open the components directory
- `polylith-mode-run-clojure-uberjar`: Build an uberjar for a selected project
- `toggle-between-src-and-test`: Switch between a source file and its corresponding test file

## Requirements

- helm 3.0 or higher
- projectile 2.0 or higher

## Contributing

Contributions, suggestions, and bug reports are welcome. Please feel free to open an issue or submit a pull request.

## License

This project is distributed under the [GNU General Public License v3.0](https://www.gnu.org/licenses/gpl-3.0.en.html).
