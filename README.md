# Gemini CLI

Gemini CLI is a command-line tool that interacts with the Gemini API to generate content based on user queries. It supports various options such as setting a limit on output tokens, clearing context history, and enabling Google search.

## Usage

```bash
./main.sh [options] query
```

### Options

- `-l, --limit`: Set maximum output tokens (default: 2048)
- `-c, --clear`: Clear context history
- `-s, --search`: Enable Google search
- `-h, --help`: Display usage information

### Example

```bash
./main.sh -l 1000 -s "What is the capital of France?"
```

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