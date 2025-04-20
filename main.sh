#!/bin/bash

function cg(){
  usage() {
    echo -e "\e[1;32mUsage:\e[0m $0 [\e[1;36m-l limit\e[0m] [\e[1;35m-c\e[0m] [\e[1;33m-s\e[0m] query"
    echo -e "  \e[1;36m-l, --limit\e[0m     Set maximum output tokens (Max: 65536)"
    echo -e "  \e[1;35m-c, --clear\e[0m     Clear context history"
    echo -e "  \e[1;33m-s, --search\e[0m    Enable Google search"	
    echo -e "  \e[1;33m-ns, --nosearch\e[0m Disable Google search"
    echo -e "  \e[1;32m-p, --pro\e[0m      Use the Pro model"
    echo -e "  \e[1;35m-f, --flash\e[0m    Use the flash model"
    echo -e "  \e[1;32m-tb, --thinkingBudget\e[0m Set thinking budget (Value: 0-24576)"
    echo -e "  \e[1;34m-cf, --config\e[0m Show the config file"
    echo -e "  \e[1;31m-h, --help\e[0m     Show this help message"
    echo -e "  \e[1;31m-rs, --reset\e[0m   Reset the config file"
    exit 1
  }
  config(){
    echo -e "\e[1;32mConfiguration file:\e[0m"
    echo -e "\e[1;36mlimit = $limit\e[0m"
    echo -e "\e[1;35mmodel = $model\e[0m"
    echo -e "\e[1;33msearch = $search\e[0m"
    echo -e "\e[1;32mPro = $thinking\e[0m"
    echo -e "\e[1;37mthinkingBudget = $thinkingBudget\e[0m"
    echo -e "\e[1;31mcurrent context size = $(wc -c /tmp/gemini-context.txt | awk '{print $1}')/1,048,576\e[0m"
    exit 1
  }

  local context=""
  local limit=65536
  local thinkingBudget=24576
  local search=false
  local context_file="/tmp/gemini-context.txt"
  local config_file="/tmp/gemini-config.conf"
  local apikey="" # Add your API key here
  local query=""
  local clearing=false
  local thinking=false
  local model="gemini-2.5-flash-preview-04-17"
  # local system_instruction="You are a helpful and informative assistant designed for use in a terminal environment. Your responses must be in plain text only. Do not use Markdown formatting, backticks, asterisks, or any special characters. Code should be presented as simple indented text."
  local system_instruction

  read -r -d '' system_instruction << 'EOF'
You are an AI assistant providing responses directly within a command-line terminal environment. Your output will be displayed as plain text without any special rendering capabilities.

Key Constraints & Formatting Rules:

1.  Plain Text Only: Absolutely NO Markdown formatting. Do not use asterisks for bold (*bold*), underscores for italic (_italic_), hash symbols for headers (# Heading), backticks for code blocks (```code``` or `code`), or square brackets/parentheses for links ([text](url)). Do not use any other special formatting characters that rely on a renderer.
2.  Readability: Use line breaks (newlines) effectively to structure information and separate paragraphs or logical blocks.
3.  Lists: For lists, use simple numbered formats (e.g., 1., 2., 3.) or hyphens/asterisks at the start of a line followed by a space (e.g., - Item 1, * Item 2), but understand these are purely visual cues in plain text. Avoid complex indentation.
4.  Code: If including code snippets, present them directly. Use simple, consistent indentation (e.g., spaces) if necessary for readability, but do NOT wrap them in Markdown code fences (```) and do NOT include Comments.
5.  Thorough: Avoid unnecessary conversational filler, greetings, or sign-offs unless the prompt specifically asks for a conversational style. Focus on delivering the requested information clearly.
6.  Clarity: Ensure the language is clear and easy to understand even without visual formatting cues.
Examples
Listing Items:
1. This is a simple list item.
2. Another Item

Coding
- Strictly no Comments. do not use #, /, //, or any forms of commenting.
- Use simple indentation for code blocks.
python
def hello_world():
    print('Hello, World!')

No Greeting & sign-off
This is the information you requested:

No markdown formatting, no special characters, just plain text.
EOF

  if [[ -f "$context_file" ]]; then
  	context=$(cat "$context_file")
  else
  	touch "$context_file"
  	context=""
  fi

  if [[ -f "$config_file" ]]; then
    source "$config_file"
  else 
    touch "$config_file"
  fi

  if [[ $(wc -c < "$context_file") -gt 500000 ]]; then
    echo -e "\e[1;31mContext file exceeds the token limit, clearing...\e[0m"
    truncate -s 0 "$context_file"
  fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -l|--limit)
        if [[ -n "$2" && "$2" =~ ^[0-9]+$ ]]; then
          limit="$2"
          echo -e "\e[1:36mToken Output: $limit\e[0m"
          shift 2
        else
          echo "Error: Limit value must be a number."
          usage
        fi
        ;;
      -f|--flash)
        echo -e "\e[1;35mFlash Model.\e[0m"
        model="gemini-2.5-flash-preview-04-17"
        thinking=false
        thinkingBudget=0
        shift
        ;;
      -p|--pro)
        echo -e "\e[1;32mThinking Model.\e[0m"
        thinking=true
        shift
        ;;
      -tb|--thinkingBudget)
        if [[ -n "$2" && "$2" =~ ^[0-9]+$ ]]; then
          thinkingBudget="$2"
          echo -e "\e[1;32mThinking Budget: $thinkingBudget\e[0m"
          shift 2
        else
          echo "Error: Thinking budget value must be a number."
          usage
        fi
        ;;
      -c|--clear)
        echo -e "\e[1;35mContext history cleared.\e[0m"
        context=""
        clearing=true
        truncate -s 0 "$context_file"
        shift
        ;;
      -s|--search)
        echo -e "\e[1;33mSearch enabled.\e[0m"
        search=true
        shift
        ;;
      -ns|--nosearch)
        echo -e "\e[1;33mSearch disabled.\e[0m"
        search=false
        shift
        ;;
      -rs|--reset)
        echo -e "\e[1;35mResetting config.\e[0m"
        truncate -s 0 "$config_file"
        exit 1
        break
        ;;
      -cf |--config)
        config
        break
        ;;
      -h|--help)
        usage
  	  break
        ;;
      *)
        if [[ -z "$query" ]]; then
          query="$1"
        else
          query="$query $1"
        fi
        shift
        ;;
    esac
  done

  if [[ "$thinking" == "true" ]]; then
      model="gemini-2.5-pro-exp-03-25"
      search=false
      limit=100000
      thinkingBudget=24576
  fi

  cat <<EOF > "$config_file"
limit=$limit
model=$model
search=$search
thinking=$thinking
thinkingBudget=$thinkingBudget
EOF

  if [[ -z "$query" && -t 0 && "$clearing" == "true" ]]; then
    exit 0
  fi

  if [[ -z "$query" && ! -t 0 ]]; then
    query=$(cat)
  fi

  if [[ -z "$query" ]]; then
    usage
  fi

  local user_prompt="$context\nUser:$query"
  local escaped_user_prompt=$(echo "$user_prompt" | jq -sR .)
  local json_data="{
    "contents": [
      {
        "parts": [
          {"text": $escaped_user_prompt}
        ]
      }
    ],
    "generationConfig": {
      "maxOutputTokens": $limit,
      "response_mime_type": 'text/plain',
      "thinkingConfig": {
          "thinkingBudget": $thinkingBudget
      }
    },
    "system_instruction":{
      "parts":{
        "text":\"$system_instruction\"
      }
    }
  "
  case "$search" in
  	(true)
  	json_data="$json_data,
  	"tools": [{"google_search": {}}]";;
  esac

  json_data="$json_data}"
  tempfile=$(mktemp)
  printf '%s' "$json_data" > "$tempfile"
  local full_output_text=""
  local search_results_array=()

  # echo "$json_data"
  echo -e "\e[4;31m<!-- Start of Response -->\e[0m"; 
  if [[ "$thinking" == "true" ]]; then
    echo -e "\e[1;32mThinking...\e[0m"
  fi
  echo;
  
  while IFS= read -r line; do
    if [[ $line == data:* ]]; then
      local json_chunk="${line#data: }"
      # echo "$json_chunk" | jq

      local output_text
      output_text=$(echo -n "$json_chunk" | jq -r '.candidates[].content.parts[].text' 2>/dev/null)
      if [[ $? -ne 0 ]]; then
        output_text="" # Set to empty string on error
      fi
      full_output_text+="$output_text"

      if [[ "$search" == "true" ]]; then
        local search_results=$(echo "$json_chunk" | jq -r '
          .candidates[] 
          | select(.groundingMetadata? != null) 
          | .groundingMetadata.groundingChunks[]? 
          | "\(.web.title) \(.web.uri)"' 2>/dev/null
        )
    
        if [[ -n "$search_results" ]]; then
          search_results_array+=("$search_results")
        fi
      fi
      # Format **bold** text as blue bold
      local formatted_output=$(echo -n "$output_text" | sed -E 's/\*\*(.*?)\*\*/\\e[1;34m\1\\e[0m/g')
      # Format *italic* text as yellow (adjust color code if needed, e.g., \e[3m for italic)
      formatted_output=$(echo -n "$formatted_output" | sed -E 's/\*(.*?)\*/\\e[1;33m\1\\e[0m/g')
      # Remove backticks
      formatted_output=$(echo -n "$formatted_output" | sed -E 's/`//g')
      
      echo -e -n "$(printf "%s" "$formatted_output")";

    fi 
  done < <(curl -s \
      -H 'Content-Type: application/json' \
      --data-binary @"$tempfile" \
      --no-buffer \
      -X POST "https://generativelanguage.googleapis.com/v1beta/models/$model:streamGenerateContent?alt=sse&key=$apikey")
  echo;
  
  if [[ "$search" == "true" ]]; then
    echo -e "\n\e[1;33mSearch Results:\e[0m"
    readarray -t search_results_array < <(echo "${search_results_array[@]}")

    for result in "${search_results_array[@]}"; do
        local title=$(echo "$result" | awk '{print $1}')  
        local url=$(echo "$result" | awk '{$1=""; print $0}' | sed 's/^ *//') 
        echo -e "\e]8;;$url\a$title\e]8;;\a"; 
    done
  fi
  echo; echo -e "\e[4;31m<!-- End of Response -->\e[0m"
  rm -f "$tempfile"
  echo -e "$user_prompt\nAssistant: $full_output_text" > "$context_file"
}


cg "$@"



