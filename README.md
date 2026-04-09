# python-unicode-escape.el

Adds autocompletion for Python's `\N{UNICODE NAME}` string escape syntax in Emacs.

Completion is provided via `completion-at-point` (CAPF), making it compatible with `company-mode` (using `company-capf`), `corfu`, and the built-in `M-TAB` / `C-M-i` completion.

## Features

- **Standard CAPF:** Works with any modern Emacs completion UI.
- **Lazy Loading:** The Unicode name database (~140k entries) is populated from Python on the first completion attempt in a session.
- **Fast:** Subsequent completions are instant using an internal cache.
- **Annotations:** Displays the actual character in the completion candidate list.
- **Automatic Closing:** Appends the closing `}` if it's missing.

## Installation

### Manual

1. Download `python-unicode-escape.el` and place it in your `load-path`.
2. Add the following to your init file:

```elisp
(require 'python-unicode-escape)
(add-hook 'python-mode-hook #'python-unicode-escape-mode)
```

## Requirements

- Emacs 27.1+
- `python3` must be available in your `PATH`.

## How it works

When you type `\N{` and trigger completion, the package calls a small Python script to fetch all available Unicode names from the `unicodedata` module. This list is then cached for the duration of the Emacs session.

## License

MIT License. See `LICENSE` for details.
