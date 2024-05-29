add_screenshot() {
	local content
	# TODO: possible to pipe to stdout instead of file?
	content=$(spectacle -r -b -o "$TEMP_DIR/screenshot.png" 2>/dev/null && base64 -w 0 "$TEMP_DIR/screenshot.png")
	jq -c --arg content "$content" \
		'(.messages[] | select(.role == "user").content) += [{"type": "image_url", "image_url": {"url": ("data:image/png;base64," + $content)}}]' \
		"$TEMP_DIR/payload" >"$TEMP_DIR/payload.tmp" && mv "$TEMP_DIR/payload.tmp" "$TEMP_DIR/payload"
}
