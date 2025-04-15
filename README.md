# Gemini CLI

Gemini CLI is a command-line tool that interacts with the Gemini API to generate content based on user queries. It supports various options such as setting a limit on output tokens, clearing context history, and enabling Google search.

## Usage

```bash
./main.sh [options] query
```
or add the function to your `.bashrc` file for easier access:

```bash
function gemini() {
    /home/<user_name>/gemini-cli/main.sh "$@"
}
```

restart bash

```bash
source ~/.bashrc
```

After adding the above function, you can use the `gemini` command from anywhere in your terminal:

```bash
gemini -l 1000 -s "What is the capital of France?"
```


### Options

- `-l, --limit`: Set maximum output tokens (default: 8196)
- `-c, --clear`: Clear context history
- `-s, --search`: Enable Google search
- `-h, --help`: Display usage information
- `-t, --thinking` : Use Google Thinking model


### Examples

```bash
./main.sh -l 1000 -s "What is the capital of France?"
```
```bash
gemini "Who is Bill Gates?" -s
```
```bash
cat << EOF | gemini
> Summarize:
> Long text....
> EOF
```

Note: `curl` and gemini API has a size and context size limitation.

## Script Details

- **Context Management**: The script maintains a context history in `/tmp/gemini-context.txt`.
- **API Key**: The script uses an API key to authenticate requests to the Gemini API.
- **JSON Data**: The script constructs a JSON payload to send to the API, including user prompts and configuration options.
- **Response Handling**: The script processes the API response to extract and display the generated content and search results (if enabled).

## Dependencies

- `jq`: A lightweight and flexible command-line JSON processor.
- `curl`: A command-line tool for transferring data with URLs.

## License

This project is licensed under the MIT License.

## Author

Earlll