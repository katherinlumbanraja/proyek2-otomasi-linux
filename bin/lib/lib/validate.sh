#!/bin/bash

validate_not_empty() {
    [[ -n "$1" ]]
}

validate_integer() {
    [[ "$1" =~ ^[0-9]+$ ]]
}

validate_range() {
    validate_integer "$1" && (( $1 >= $2 && $1 <= $3 ))
}

validate_file_exists() {
    [[ -f "$1" ]]
}
