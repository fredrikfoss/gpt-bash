# gpt - OpenAI API client

OpenAI API client in Bash. Based on the baseless assumption that separating queries in the API call can enhance the AI's ability to distinguish inputs, the application allows appending text queries, files, images, screenshots, and stdin as distinct message modules to the payload. Perform a dry run to inspect the payload as demonstrated in the example below.

```
$ gpt -d explain the following shell script -f script.sh
Dry-run mode, no API calls made.

Request URL:
--------------
https://api.openai.com/v1/chat/completions

Authorization:
--------------
Bearer sk-exa****XLJENBTnu

Payload:
--------------
{
  "model": "gpt-4o",
  "stream": true,
  "temperature": 0.0,
  "max_tokens": 4096,
  "messages": [
    {
      "role": "system",
      "content": "Be concise in your answers. Excessive politeness is physically painful to me. Provide code blocks that are complete. Avoid numbered lists, summaries are better. For any technical questions, assume the user has general knowledge in the area."
    },
    {
      "role": "user",
      "content": [
        {
          "type": "text",
          "text": "explain the following shell script"
        },
        {
          "type": "text",
          "text": "#!/bin/bash\nset -e\n\ndeclare user_input\n\necho -n \"Enter something: \"\nIFS= read -r user_input\n\necho \"You entered: $user_input\"\nexit 0"
        }
      ]
    }
  ]
}
```

## Dependencies

* [jq](https://github.com/jqlang/jq)
* [grim](https://git.sr.ht/~emersion/grim) and [slurp](https://github.com/emersion/slurp) for screenshot functionality (Linux Wayland only atm.)
* An [OpenAI API key](https://platform.openai.com/docs/quickstart/account-setup)

## Install

```sh
git clone git@github.com:fredrikfoss/gpt-bash.git
cd gpt-bash
make
```

You can link or copy the program executable to `~/.local/bin/gpt` with `make link` or `make install`. Remember to add directory to path. Example, in `~/.bashrc`:

```sh
export PATH=$HOME/.local/bin:$PATH
```

Then, set the OPENAI_API_KEY environment variable with your API key. Example, in `~/.bashrc`:

```sh
export OPENAI_API_KEY=sk-exa...XLJENBTnu
```

If you don't want to make it an environment variable, you could instead store the key in [pass](https://passwordstore.org). Add the key to pass, then in `~/.bashrc` something like:

```sh
alias gpt='OPENAI_API_KEY=$(pass api-keys/openai) gpt'
```

## Usage

```
usage: gpt [options] [query]

options:
    -q <query> # add additional query
    -f <file>  # add file
    -i <image> # add image file
    -p         # add screenshot
    -d         # dry-run
    -h         # print help
```

### Examples

```
gpt what is the zig language?
gpt -i path/to/img.png give a filename to this image
gpt compare the two screenshots -p -p
gpt -f file.c add code comments to this program
gpt translate to norwegian -q "to be or not to be?" -q "you shall not pass!"
gpt can the project structure be improved? <<<$(tree -aI .git)
```

### Related environment variables

* `OPENAI_API_KEY`
* `OPENAI_API_MODEL`
* `OPENAI_API_TEMP`
* `OPENAI_API_MAX_TOKENS`
* `OPENAI_API_ENDPOINT`

## TODO

* Ignore all options after --
* System prompt option: gpt -s new system prompt
* Temperature option: gpt -t 0.5
* Remember conversation (maybe)
