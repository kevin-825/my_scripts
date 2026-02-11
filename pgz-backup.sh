#!/bin/bash
set -eu
operation_type=""

compress_dir(){
    local src_dir_path="$1"
    local src_dir_name="$2"
    local is_src_dir_git_repo="$3"
    local store_path="$4"

    # 1. Improved error message (typo fix: 'errer' -> 'error')
    if [ ! -d "$src_dir_path/$src_dir_name" ]; then
        echo "Error: Source directory not found at $src_dir_path/$src_dir_name"
        exit 1
    fi

    mkdir -p "$store_path"

    start_time=$(date +%s)
    # 2. Recommendation: Use -C to avoid storing absolute paths in the tarball
    tar --use-compress-program=pigz -cf "$store_path/$src_dir_name.tar.gz" -C "$src_dir_path" "$src_dir_name"
    end_time=$(date +%s)
    echo "Backup created with pigz in $((end_time - start_time)) seconds."

    # 3. Fixed the if-statement and variable assignment
    if [ "$is_src_dir_git_repo" = "true" ]; then
        local tag_file="$src_dir_name.tag"
        # Get the latest commit hash (short version)
        local current_commit=$(git -C "$src_dir_path/$src_dir_name" rev-parse --short HEAD 2>/dev/null)
        
        if [ -n "$current_commit" ]; then
            echo "$current_commit" > "$store_path/$tag_file"
            echo "Git commit $current_commit saved to $tag_file"
        else
            echo "Warning: Directory marked as Git repo, but could not retrieve commit hash."
        fi
    fi
}


extract_archive(){
    local src_file_path="$1"
    local extract_dest_path="$2"

    if [ ! -f "$src_file_path" ]; then
        echo "src file path error, src_file_path:$src_file_path"
        exit 1
    fi

    mkdir -p "$extract_dest_path"

    start_time=$(date +%s)
    tar --use-compress-program=pigz -xf "$src_file_path" -C "$extract_dest_path"
    end_time=$(date +%s)
    echo "Extracted with pigz in $((end_time - start_time)) seconds."

    echo "extract_dest_path: $extract_dest_path"
    echo "Destination content summary:"
    # Use > /dev/null to keep the terminal output clean
    pushd "$extract_dest_path" > /dev/null
    du -h -d 1 .
    popd > /dev/null
}

usage() {
    echo "Usage:"
    echo "  To create a gzip tarball with pigz:"
    echo "    -z|--gzip <src_dir_path> <store_path> <src_dir_name> <is_src_dir_git_repo>"
    echo "  To extract a gzip tarball with pigz:"
    echo "    -x|--extract <src_file_path> <extract_dest_path>"
    echo "  To display this help message:"
    echo "    -h|--help"
}

argparse() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -z|--gzip) operation_type="gzip"; SRC_DIR_PATH="$2"; STORE_PATH="$3"; SRC_DIR_NAME="$4"; IS_SRC_DIR_GIT_REPO="$5"; shift 5 ;;
            -x|--extract) operation_type="extract"; SRC_FILE_PATH="$2"; EXTRACT_DEST_PATH="$3"; shift 3 ;;
            -h|--help) usage; exit 0 ;;
            *) echo "Unknown argument: $1"; exit 1 ;;
        esac
    done
}

main() {
    argparse "$@"

    case "$operation_type" in
        "gzip")    compress_dir "$SRC_DIR_PATH" "$SRC_DIR_NAME" "$IS_SRC_DIR_GIT_REPO" "$STORE_PATH" ;;
        "extract") extract_archive "$SRC_FILE_PATH" "$EXTRACT_DEST_PATH" ;;
        *)         usage; exit 1 ;;
    esac
}

main "$@"
