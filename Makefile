SOURCE := gpt
TARGET := $(HOME)/.local/bin/gpt

.PHONY: help install link

help:
	@printf "%s\n" \
		"usage:" \
		"    make [option]" \
		"" \
		"options:" \
		"    install # copy to ~/.local/bin" \
		"    link    # link in ~/.local/bin" \
		"    help    # print help"

install:
	@mkdir -p $(dir $(TARGET))
	@rm -f $(TARGET)
	@cp $(SOURCE) $(TARGET)
	@printf "installed to $(TARGET)\n"

link:
	@mkdir -p $(dir $(TARGET))
	@rm -f $(TARGET)
	@ln -sfr $(SOURCE) $(TARGET)
	@printf "linked in $(TARGET)\n"
