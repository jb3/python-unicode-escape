;;; python-unicode-escape.el --- Completion for Python \N{NAME} escapes -*- lexical-binding: t -*-

;; Author: Joe Banks <joe@jb3.dev>
;; Version: 0.1
;; Package-Requires: ((emacs "27.1"))
;; Keywords: python, unicode, completion, abbrev
;; Homepage: https://github.com/jb3/python-unicode-escape
;; URL: https://github.com/jb3/python-unicode-escape

;;; Commentary:
;;
;; Adds completion-at-point (CAPF) support for Python's \N{UNICODE NAME}
;; string escape syntax.  Works with company-mode (via company-capf),
;; corfu, and built-in M-TAB / C-M-i completion.
;;
;; Usage:
;;   (require 'python-unicode-escape)
;;   (add-hook 'python-mode-hook #'python-unicode-escape-mode)
;;
;; The first completion triggers a one-time Python call to populate the
;; cache (~140k names, takes ~1-2s).  All subsequent completions are instant.

;;; Code:

(require 'cl-lib)

;;;; Internal state

(defvar python-unicode-escape--names nil
  "Sorted list of all Unicode character names (strings).")

(defvar python-unicode-escape--char-table (make-hash-table :test #'equal :size 150000)
  "Hash table mapping Unicode name -> the actual character (string).")

(defvar python-unicode-escape--loaded nil
  "Non-nil once the cache has been populated.")

;;;; Cache loading

(defconst python-unicode-escape--python-script
  "import unicodedata, sys
for i in range(0x110000):
    try:
        n = unicodedata.name(chr(i))
        sys.stdout.write(n + '\\t' + chr(i) + '\\n')
    except ValueError:
        pass"
  "Python snippet that prints NAME<TAB>CHAR lines for every named codepoint.")

(defun python-unicode-escape--load ()
  "Populate the name cache by calling Python.  Ran at most once per session."
  (unless python-unicode-escape--loaded
    (message "python-unicode-escape: loading Unicode names (one-time)…")
    (with-temp-buffer
      (let ((exit (call-process "python3" nil t nil "-c" python-unicode-escape--python-script)))
        (unless (zerop exit)
          (error "python-unicode-escape: Python exited with %s" exit)))
      (goto-char (point-min))
      (while (not (eobp))
        (let* ((line-end (line-end-position))
               (line     (buffer-substring-no-properties (point) line-end))
               (tab      (cl-position ?\t line)))
          (when tab
            (let ((name (substring line 0 tab))
                  (char (substring line (1+ tab))))
              (push name python-unicode-escape--names)
              (puthash name char python-unicode-escape--char-table))))
        (forward-line 1)))
    (setq python-unicode-escape--names   (sort (nreverse python-unicode-escape--names) #'string<)
          python-unicode-escape--loaded  t)
    (message "python-unicode-escape: loaded %d names." (length python-unicode-escape--names))))

;;;; Annotation and exit helpers

(defun python-unicode-escape--annotation (name)
  "Return the actual character for NAME to show in the completion margin."
  (when-let ((ch (gethash name python-unicode-escape--char-table)))
    (concat "  " ch)))

(defun python-unicode-escape--exit-function (_str status)
  "After completing (when STATUS is finished) _STR, insert closing `}` if not already present."
  (when (eq status 'finished)
    (unless (looking-at-p "}")
      (insert "}"))))

;;;; Completion-at-point function

(defun python-unicode-escape-completion-at-point ()
  "CAPF for Python \\N{UNICODE NAME} escapes.

Activates when point is inside \\N{...} in a Python buffer."
  (when (derived-mode-p 'python-mode 'python-ts-mode)
    (let* ((end    (point))
           (bol    (line-beginning-position))
           (before (buffer-substring-no-properties bol end)))
      ;; Match \N{ followed by zero-or-more non-} chars ending at point
      (when (string-match "\\\\N{\\([^}\n]*\\)\\'" before)
        (let ((name-start (+ bol (match-beginning 1)))
              (prefix     (match-string 1 before)))
          (python-unicode-escape--load)
          (list name-start
                end
                ;; Return a completion-table function so Emacs does the
                ;; prefix filtering lazily rather than us building a sublist.
                (completion-table-dynamic
                 (lambda (_)
                   (let ((up (upcase prefix)) result)
                     (dolist (n python-unicode-escape--names)
                       (when (string-prefix-p up n)
                         (push n result)))
                     (nreverse result))))
                :annotation-function #'python-unicode-escape--annotation
                :exit-function       #'python-unicode-escape--exit-function
                ;; Let other CAPFs run if we produce no candidates.
                :exclusive 'no))))))

;;;; Minor mode

;;;###autoload
(define-minor-mode python-unicode-escape-mode
  "Complete Python \\N{UNICODE NAME} escapes at point."
  :lighter " \\N{}"
  (if python-unicode-escape-mode
      (add-hook  'completion-at-point-functions #'python-unicode-escape-completion-at-point nil t)
    (remove-hook 'completion-at-point-functions #'python-unicode-escape-completion-at-point t)))

;;;; Cache management

(defun python-unicode-escape-reset-cache ()
  "Clear the name cache; it will be rebuilt on next completion."
  (interactive)
  (setq python-unicode-escape--names  nil
        python-unicode-escape--loaded nil)
  (clrhash python-unicode-escape--char-table)
  (message "python-unicode-escape: cache cleared."))

(provide 'python-unicode-escape)
;;; python-unicode-escape.el ends here
