#!/bin/bash

# Directory containing project-specific Docker Compose files
COMPOSE_DIR="$HOME/Prosjekter/docker-compose"

# Directory to store service aliases
ALIAS_DIR="$COMPOSE_DIR/.aliases"

# Function to set service aliases
set_alias() {
    local project_name="$1"
    local alias_name="$2"
    shift 2
    echo "$@" > "$ALIAS_DIR/$project_name-$alias_name"
    echo "Alias '$alias_name' for project '$project_name' set to: $*"
}

# Function to get expanded service names from aliases
get_expanded_names() {
    local project_name="$1"
    local alias_name="$2"
    if [ -f "$ALIAS_DIR/$project_name-$alias_name" ]; then
        cat "$ALIAS_DIR/$project_name-$alias_name"
    else
        echo "$alias_name"
    fi
}

# Function to execute arbitrary docker-compose commands
docker_compose() {
    local project_name="$1"
    shift
    docker compose -f "$COMPOSE_DIR/docker-compose-$project_name.yml" "${@:1}"
}

# Function to list aliases with their services
list_aliases() {
    local project_name="$1"
    echo "Aliases for project '$project_name':"
    for alias_file in "$ALIAS_DIR/$project_name"*; do
        local alias_name=$(basename "$alias_file")
        local services=$(cat "$alias_file")
        echo "$alias_name : $services"
    done
}

# Check if Docker Compose is installed
if ! command -v docker compose &> /dev/null; then
    echo "Error: Docker Compose is not installed or not in PATH."
    exit 1
fi

# Check if the ALIAS_DIR exists, if not create it
if [ ! -d "$ALIAS_DIR" ]; then
    mkdir -p "$ALIAS_DIR"
fi

# Parse the command
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <projectname> <command> [additional arguments...]"
    exit 1
fi

project_name="$1"
shift

case "$1" in
    setalias)
        if [ "$#" -lt 3 ]; then
            echo "Usage: $0 <projectname> setalias <aliasname> <service1 service2 ...>"
            exit 1
        fi
        set_alias "$project_name" "$2" "${@:3}"
        ;;
    listaliases)
        list_aliases "$project_name"
        ;;
    *)
        case "$1" in
            start)
                if [ "$#" -eq 1 ]; then
                    docker_compose "$project_name" up -d
                else
                    services=""
                    for arg in "${@:2}"; do
                        if [ -f "$ALIAS_DIR/$project_name-$arg" ]; then
                            services+=" $(cat "$ALIAS_DIR/$project_name-$arg")"
                        else
                            services+=" $arg"
                        fi
                    done
                    docker_compose "$project_name" up -d $services
                fi
                ;;
            stop)
                if [ "$#" -eq 1 ]; then
                    docker_compose "$project_name" down
                else
                    services=""
                    for arg in "${@:2}"; do
                        if [ -f "$ALIAS_DIR/$project_name-$arg" ]; then
                            services+=" $(cat "$ALIAS_DIR/$project_name-$arg")"
                        else
                            services+=" $arg"
                        fi
                    done
                    docker_compose "$project_name" down $services
                fi
                ;;
            *)
                # Pass through arbitrary docker-compose commands
                docker_compose "$project_name" "$@"
                ;;
        esac
        ;;
esac
