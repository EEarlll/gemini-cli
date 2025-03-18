#!/bin/bash

function cg(){
  usage() {
    echo -e "\e[1;32mUsage:\e[0m $0 [\e[1;36m-l limit\e[0m] [\e[1;35m-c\e[0m] [\e[1;33m-s\e[0m] query"
    echo -e "  \e[1;36m-l, --limit\e[0m     Set maximum output tokens (default: 2048)"
    echo -e "  \e[1;35m-c, --clear\e[0m     Clear context history"
    echo -e "  \e[1;33m-s, --search\e[0m    Enable Google search"	
    echo -e "  \e[1;32m-t, --thinking\e[0m  Use the thinking model"
    exit 1
  }

  local context=""
  local limit=2048
  local search=false
  local context_file="/tmp/gemini-context.txt"
  local apikey="" # Add your API key here
  local query=""
  local clearing=false
  local thinking=false
  local model="gemini-2.0-flash"

  if [[ -f "$context_file" ]]; then
  	context=$(cat "$context_file")
  else
  	touch "$context_file"
  	context=""
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
      -t|--thinking)
        echo -e "\e[1;32mThinking Model.\e[0m"
        thinking=true
        shift
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
      model="gemini-2.0-flash-thinking-exp"
      search=false
  fi

  if [[ -z "$query" && -t 0 && "$clearing" == "true" ]]; then
    exit 0
  fi

  if [[ -z "$query" && ! -t 0 ]]; then
    query=$(cat)
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
      "maxOutputTokens": $limit
    }
  "
  case "$search" in
  	(true)
  	json_data="$json_data,
  	"tools": [{"google_search": {}}]";;
  esac

  json_data="$json_data}"
  local response=$(curl -s \
      -H 'Content-Type: application/json' \
      -d "$json_data" \
      -X POST "https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apikey")

  # echo "$response "| jq .
  # echo "$json_data"

  local output_text=$(echo "$response" | jq -r '.candidates[].content.parts[].text')

  echo -e "$user_prompt\nAssistant: $output_text" > "$context_file"

  local formatted_output=$(echo "$output_text" | sed -E 's/\*\*(.*?)\*\*/\\e[1;34m\1\\e[0m/g')
  local formatted_output=$(echo "$formatted_output" | sed -E 's/\*/'"$(printf '\e[1;33m*\e[0m')"'/g')
  
  echo -e "\e[4;31m<!-- Start of Response -->\e[0m"; echo
  echo -e "$(printf "$formatted_output")"; echo

  if [[ "$search" == "true" ]]; then
    local search_results=$(echo "$response" | jq -r '
      .candidates[] 
      | select(.groundingMetadata? != null) 
      | .groundingMetadata.groundingChunks[]? 
      | "\(.web.title) \(.web.uri)"' 2>/dev/null
    )

    if [[ -n "$search_results" ]]; then
      echo -e "\n\e[1;33mSearch Results:\e[0m"
      while IFS= read -r line; do
        local title=$(echo "$line" | awk '{print $1}')  
        local url=$(echo "$line" | awk '{$1=""; print $0}' | sed 's/^ *//') 
        echo -e "\e]8;;$url\a$title\e]8;;\a"; 
      done <<< "$search_results"
    else
      echo "No search results used.";
    fi
  fi
  echo; echo -e "\e[4;31m<!-- End of Response -->\e[0m"
}


cg "$@"



