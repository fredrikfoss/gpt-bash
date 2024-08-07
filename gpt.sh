#!/bin/bash
set -o pipefail

declare API_KEY="$OPENAI_API_KEY"
declare MODEL="${OPENAI_API_MODEL:-"gpt-4o"}"
declare TEMP="${OPENAI_API_TEMP:-0.0}"
declare MAX_TOKENS="${OPENAI_API_MAX_TOKENS:-4096}"
declare ENDPOINT="${OPENAI_API_ENDPOINT:-"https://api.openai.com/v1/chat/completions"}"

cleanup() {
	if [[ -d $TMPDIR ]]; then
		rm -rf -- "$TMPDIR"
	fi
}

die() {
	echo "$@" >&2
	exit 1
}

init_payload() {
	local system_prompt
	system_prompt=$(
		cat <<-'EOF' | tr '\n' ' ' | sed 's/ $//'
			Be concise in your answers. Excessive politeness is
			physically painful to me. Provide code blocks that are
			complete. Avoid numbered lists, summaries are better.
			For any technical questions, assume the user has general
			knowledge in the area.
		EOF
	)

	jq -Rs -cn \
		--arg model "$MODEL" \
		--argjson temperature "$TEMP" \
		--argjson max_tokens "$MAX_TOKENS" \
		--arg system_prompt "$system_prompt" \
		'{
            "model": $model,
            "stream": true,
            "temperature": $temperature,
            "max_tokens": $max_tokens,
            "messages": [
              {
                "role": "system",
                "content": $system_prompt
              },
              {
                "role": "user",
                "content": []
              }
            ]
          }' >"$TMPDIR/payload"
}

fetch_response() {
	local chunk
	(curl -fsNX POST "$ENDPOINT" \
		-H "Authorization: Bearer $API_KEY" \
		-H "Content-Type: application/json" \
		--data-binary "@$TMPDIR/payload" |
		while IFS= read -r chunk; do
			chunk=$(cut -d: -f2- <<<"$chunk")
			[[ $chunk == ' [DONE]' ]] && echo && break
			jq --raw-output0 '.choices[0].delta.content // empty' <<<"$chunk"
		done) || die "error: curl failed with status $?"
}

cmd_add_query() {
	local content="$*"
	jq -c --arg content "$content" \
		'(.messages[] | select(.role == "user").content) += [{"type": "text", "text": $content}]' \
		"$TMPDIR/payload" >"$TMPDIR/payload_temp" && mv "$TMPDIR/payload_temp" "$TMPDIR/payload"
}

cmd_add_file() {
	local content
	content=$(<"$1") || die "error: failed to read file"
	jq -c --arg content "$content" \
		'(.messages[] | select(.role == "user").content) += [{"type": "text", "text": $content}]' \
		"$TMPDIR/payload" >"$TMPDIR/payload_temp" && mv "$TMPDIR/payload_temp" "$TMPDIR/payload"
}

cmd_add_image() {
	local content_file image_format
	content_file=$(mktemp "$TMPDIR/content.XXXXXX.b64")
	base64 -w 0 "$1" >"$content_file" || die "error: failed to encode image"
	image_format=$(file --mime-type -b "$1")
	if [[ $image_format == image/jpeg ]]; then
		jq -c --rawfile content "$content_file" \
			'(.messages[] | select(.role == "user").content) += [{"type": "image_url", "image_url": {"url": ("data:image/jpeg;base64," + $content)}}]' \
			"$TMPDIR/payload" >"$TMPDIR/payload_temp" && mv "$TMPDIR/payload_temp" "$TMPDIR/payload"
	elif [[ $image_format == image/png ]]; then
		jq -c --rawfile content "$content_file" \
			'(.messages[] | select(.role == "user").content) += [{"type": "image_url", "image_url": {"url": ("data:image/png;base64," + $content)}}]' \
			"$TMPDIR/payload" >"$TMPDIR/payload_temp" && mv "$TMPDIR/payload_temp" "$TMPDIR/payload"
	else
		die "error: image format not supported"
	fi
}

cmd_add_screenshot() {
	local content_file
	content_file=$(mktemp "$TMPDIR/content.XXXXXX.b64")
	grim -t jpeg -g "$(slurp)" - | base64 -w 0 >"$content_file" || die "error: failed to capture screenshot"
	jq -c --rawfile content "$content_file" \
		'(.messages[] | select(.role == "user").content) += [{"type": "image_url", "image_url": {"url": ("data:image/jpeg;base64," + $content)}}]' \
		"$TMPDIR/payload" >"$TMPDIR/payload_temp" && mv "$TMPDIR/payload_temp" "$TMPDIR/payload"
}

cmd_dry_run() {
	local url="$ENDPOINT"
	local auth="Bearer $API_KEY"
	echo "Dry-run mode, no API calls made."
	echo -e "\nRequest URL:\n--------------\n$url"
	echo -en "\nAuthorization:\n--------------\n"
	sed -E 's/(sk-.{3}).{41}/\1****/' <<<"$auth"
	echo -e "\nPayload:\n--------------"
	jq <"$TMPDIR/payload"
}

cmd_usage() {
	cat <<-EOF
		usage:
		    ${0##*/} [options] [query]

		options:
		    -q <query> # add additional query to payload
		    -f <file>  # add file as additional query
		    -i <image> # add PNG or JPEG image file to payload
		    -p         # add screenshot to payload
		    -d         # dry-run mode, don't call API
		    -h         # print help
	EOF
}

[[ -z $OPENAI_API_KEY ]] && die "error: OPENAI_API_KEY not set"
[[ $# -eq 0 && -t 0 ]] && die "$(cmd_usage)"

declare TMPDIR
TMPDIR=$(mktemp -d)
trap 'cleanup' EXIT

init_payload
dry_run=false
text_accum=""

process_accumulated_text() {
	if [[ -n "$text_accum" ]]; then
		cmd_add_query "$text_accum"
		text_accum=""
	fi
}

while [[ $# -gt 0 ]]; do
	case $1 in
		-q) process_accumulated_text && cmd_add_query "$2" && shift 2 ;;
		-f) process_accumulated_text && cmd_add_file "$2" && shift 2 ;;
		-i) process_accumulated_text && cmd_add_image "$2" && shift 2 ;;
		-p) process_accumulated_text && cmd_add_screenshot && shift ;;
		-d) dry_run=true && shift ;;
		-h) cmd_usage && exit 0 ;;
		-*) die "unknown option: $1" ;;
		*) text_accum+="${text_accum:+ }$1" && shift ;;
	esac
done

process_accumulated_text

if [[ ! -t 0 ]]; then
	cmd_add_query "$(</dev/stdin)"
fi

if $dry_run; then
	cmd_dry_run
	exit 0
fi

fetch_response
