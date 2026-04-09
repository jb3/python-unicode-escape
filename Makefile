EMACS ?= emacs
RM ?= rm -f

.PHONY: compile clean

compile:
	$(EMACS) -Q -batch -f batch-byte-compile python-unicode-escape.el

clean:
	$(RM) python-unicode-escape.elc
