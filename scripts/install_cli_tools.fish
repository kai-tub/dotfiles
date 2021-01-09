#!/usr/bin/env fish

# Register tmp_dir variable to be deleted on exit
# Used for the temporarily created directory
function delete_on_exit --on-event "fish_exit"
    if test -n "$tmp_dir"
        echo "Automatically deleting tmp dir"
        rm -rf $tmp_dir
    end
end

function check_fzf --description "If `fzf` not installed, install if possible"
    # Get file location, install fzf if not already installed
    if ! command -q fzf
        set script_loc (dirname (readlink -m (status --current-filename)))
        set main_loc (dirname script_loc)
        bash "$main_loc/fzf/install"
        echo "Tried to install `fzf`"
        echo "Run script again"
        exit 0
    end
end

function get_release_url --description "Get the latest GitHub Relase Url" -a repo
    echo "https://api.github.com/repos/$repo/releases/latest"
end

function download_latest_release --description "Download the latest GitHub Release. Returns name of downloaded file." -a url
    set url (curl -s "$url" | grep "browser_download_url" | cut -d '"' -f 4 | fzf)
    curl -OL "$url"
    set -l url_elements (string split / "$url")
    echo $url_elements[-1]
end

function find_and_move_binary -a "binary_name" "target_dir"
    find . -name "$binary_name" -type f -exec chmod +x {} \; -exec mv {} "$target_dir" \;
end


function download_repo --description "Downlaod repo. Returns the name." -a "repo"
    set -l url (get_release_url "$repo")
    set -l fname (download_latest_release $url)
    echo "$fname"
end

function simplify_name --description "Recurse into directory and rename input" -a inp simple_name
    find . -name "*$inp*" -type f -exec mv {} "$simple_name" \;
end

function install_notes_cli --description "Install notes_cli" -a "target_dir" "force"
    if command -q notes; and test -z "$force"
        echo "Skipping `notes` installation, as it is already installed."
        return
    end
    set -l fname (download_repo "rhysd/notes-cli")
    mv notes*.zip notes.zip
    unzip notes.zip
    find_and_move_binary "notes" "$target_dir"
end

function install_act --description "Install act for running local github actions" -a "target_dir" "force"
    if command -q act; and test -z "$force"
        echo "Skipping `act` installation, as it is already installed."
        return
    end
    set -l fname (download_repo "nektos/act")
    mv act*.tar.gz act.tar.gz
    tar -xf act.tar.gz
    find_and_move_binary "act" "$target_dir"
end

function install_powerline_go --description "Install powerline-go" -a "target_dir" "force"
    if command -q powerline-go; and test -z "$force"
        echo "Skipping `powerline-go` installation, as it is already installed."
        return
    end
    set -l fname (download_repo "justjanne/powerline-go")
    mv $fname powerline-go
    find_and_move_binary "powerline-go" "$target_dir"
end

function install_starship --description "Install starship" -a "target_dir" "force"
    if command -q starship; and test -z "$force"
        echo "Skipping `starship` installation, as it is already installed."
        return
    end
    set -l fname (download_repo "starship/starship")
    mv $fname starship.tar.xz
    tar -xf starship.tar.xz
    find_and_move_binary "starship" "$target_dir"
end


function install_pdfcpu --description "Install pdfcpu" -a "target_dir" "force"
    if command -q pdfcpu; and test -z "$force"
        echo "Skipping `pdfcpu` installation, as it is already installed."
        return
    end
    set -l fname (download_repo "pdfcpu/pdfcpu")
    mv $fname pdfcpu.tar.xz
    tar -xf pdfcpu.tar.xz
    find_and_move_binary "pdfcpu" "$target_dir"
end

function install_exa --description "Install exa" -a "target_dir" "force"
    if command -q exa; and test -z "$force"
        echo "Skipping `exa` installation, as it is already installed."
        return
    end
    set -l fname (download_repo "ogham/exa")
    mv $fname exa.zip
    unzip exa.zip
    simplify_name "exa" "./exa"
    find_and_move_binary "exa" "$target_dir"
end

function install_cascadia --description "Install cascadia" -a "force"
    set -l font (fc-list | grep -i "Cascadia")
    if test -n "$font"; and test -z "$force"
        echo "Skipping `cascadia` installation, as the font is already installed."
        return
    end
    set -l fname (download_repo "microsoft/cascadia-code")
    mv $fname cascadia-code.zip
    mkdir cascadia-code
    unzip cascadia-code.zip -d cascadia-code
    set font_folder "$HOME/.local/share/fonts/opentype"
    mkdir -p "$font_folder"
    cp -r cascadia-code/otf/* "$font_folder"
    fc-cache -f -v
end

function install_bat --description "Install `bat`" -a "target_dir" "force"
    if command -q bat; and test -z "$force"
        echo "Skipping `bat` installation, as it is already installed."
        return
    end
    set -l fname (download_repo "sharkdp/bat")
    mv $fname bat.tar.gz
    tar -xf bat.tar.gz
    find_and_move_binary "bat" "$target_dir"
end

function install_fd --description "Install `fd`" -a "target_dir" "force"
    if command -q fd; and test -z "$force"
        echo "Skipping `fd` installation, as it is already installed."
        return
    end
    set -l fname (download_repo "sharkdp/fd")
    mv $fname fd.tar.gz
    tar -xf fd.tar.gz
    find_and_move_binary "fd" "$target_dir"
end

function help
    set scriptname (status -f)
    echo "$scriptname [OPTION]
This script should be used to install all the
important GitHub released binaries.

Options:
  -f/--force        Reinstall all packages, same as --update
  -u/--update       Update all packages by re-downloading binaries
  -t/--target-dir   Choose installation folder. (Default '~/bin')
  -h/--help         Show this help screen
"
end

function help_exit
    help
    exit 1
end

set args "h/help" "t/target-dir=" "f/force" "u/update"
argparse --name=installer $args -- $argv
or help_exit

if set -q _flag_help
    help
    exit 0
end

check_fzf

if test -z "$_flag_force"; and test -z "$_flag_update"
    set force
else
    set force 1
end

if test -z "$_flag_target_dir"
    set _flag_target_dir "$HOME/bin/"
end

if ! test -d "$_flag_target_dir"
    echo "Target directory not found!"
    exit 1
end

set tmp_dir (mktemp -d)
pushd "$tmp_dir"; or begin
    error "Couldn't switch to tmp_dir: $tmp_dir"
    exit 1
end

install_notes_cli "$_flag_target_dir" "$force"
install_powerline_go "$_flag_target_dir" "$force"
install_starship "$_flag_target_dir" "$force"
install_pdfcpu "$_flag_target_dir" "$force"
install_cascadia "$force"
install_act "$_flag_target_dir" "$force"
install_bat "$_flag_target_dir" "$force"
install_fd "$_flag_target_dir" "$force"
install_exa "$_flag_target_dir" "$force"

popd; or begin
    error "Couldn't pop from directory stack"
    exit 1
end
