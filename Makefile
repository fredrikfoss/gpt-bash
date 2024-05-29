# Only temporary, to be improved

PREFIX := $(HOME)/.local
BINDIR := $(PREFIX)/bin

.PHONY: help install link
.DEFAULT_GOAL := help

help:
	@echo "usage:"
	@echo "    make [option]"
	@echo
	@echo "options:"
	@echo "    install - copy to ~/.local/bin/"
	@echo "    link    - link to ~/.local/bin/"
	@echo "    help    - print help"

install:
	@mkdir -p $(BINDIR)
	@cp gpt $(BINDIR)/gpt
	@echo "Installed to $(BINDIR)/gpt"

link:
	@mkdir -p $(BINDIR)
	@ln -sfr gpt $(BINDIR)/gpt
	@echo "Linked to $(BINDIR)/gpt"
