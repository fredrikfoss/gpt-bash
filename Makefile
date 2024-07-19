SOURCE := gpt.sh
TARGET := $(HOME)/.local/bin/gpt

.PHONY: help install link

help:
	@printf "%s\n" \
		"usage:" \
		"    make [option]" \
		"" \
		"options:" \
		"    install   # copy to ~/.local/bin/" \
		"    link      # link to ~/.local/bin/" \
		"    help      # print help"

install:
	@mkdir -p $(dir $(TARGET))
	@rm -f $(TARGET)
	@cp $(SOURCE) $(TARGET)
	@printf "installed to $(TARGET)\n"

link:
	@mkdir -p $(dir $(TARGET))
	@ln -sfr $(SOURCE) $(TARGET)
	@printf "linked to $(TARGET)\n"
