#!/usr/bin/env bash
set -Eeuo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
    printf 'This script only runs on macOS.\n' >&2
    exit 1
fi

os_version="$(sw_vers -productVersion)"

printf 'Setting macOS system settings\n'
printf 'Detected macOS version: %s\n\n' "$os_version"

sudo -v
while true; do
    sudo -n true
    sleep 60
    kill -0 "$$" || exit
done 2>/dev/null &
sudo_keepalive_pid="$!"
trap 'kill "$sudo_keepalive_pid" 2>/dev/null || true' EXIT

osascript -e 'tell application "System Settings" to quit' >/dev/null 2>&1 || true

if ! sudo nvram StartupMute=%01 2>/dev/null; then
    printf 'Warning: could not disable startup sound with nvram.\n' >&2
fi

# Appearance
defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"

# Save dialogs and documents
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# Hot corners
defaults write com.apple.dock wvous-tl-corner -int 0
defaults write com.apple.dock wvous-tr-corner -int 0
defaults write com.apple.dock wvous-bl-corner -int 0
defaults write com.apple.dock wvous-br-corner -int 0

# Keyboard
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Text
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# Mouse
defaults write NSGlobalDomain com.apple.mouse.scaling -float 1.5

# Animations
defaults write NSGlobalDomain NSWindowResizeTime -float 0.001
defaults write NSGlobalDomain QLPanelAnimationDuration -float 0
defaults write com.apple.dock mineffect -string "scale"

# Menu bar
defaults write com.apple.Siri StatusMenuVisible -bool false
defaults write com.apple.menuextra.battery ShowPercent -string "YES"

# Dock
defaults write com.apple.dock orientation -string "bottom"
defaults write com.apple.dock tilesize -int 64
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-time-modifier -float 0.25
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock magnification -bool false
defaults write com.apple.dock mru-spaces -bool false
defaults write com.apple.dock expose-animation-duration -float 0.1

defaults write com.apple.dock persistent-apps -array

add_app_to_dock() {
    local app_path="$1"

    if [[ ! -d "$app_path" ]]; then
        printf 'Skipping missing Dock app: %s\n' "$app_path" >&2
        return 0
    fi

    defaults write com.apple.dock persistent-apps -array-add \
        "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>$app_path</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>"
}

add_app_to_dock "/System/Library/CoreServices/Finder.app"
add_app_to_dock "/System/Applications/App Store.app"
add_app_to_dock "/Applications/Google Chrome.app"
add_app_to_dock "/Applications/Spotify.app"
add_app_to_dock "/System/Applications/System Settings.app"
add_app_to_dock "/Applications/Visual Studio Code.app"
add_app_to_dock "/Applications/Ghostty.app"

# Finder
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
defaults write com.apple.finder _FXSortFoldersFirst -bool true
defaults write com.apple.finder NewWindowTarget -string "PfHm"
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/"

defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Screenshots
defaults write com.apple.screencapture type -string "png"
defaults write com.apple.screencapture location -string "${HOME}/Downloads"

# Browsers
defaults write com.google.Chrome AppleEnableSwipeNavigateWithScrolls -bool false
defaults write com.google.Chrome AppleEnableMouseSwipeNavigateWithScrolls -bool false
defaults write org.mozilla.firefox AppleEnableSwipeNavigateWithScrolls -bool false
defaults write org.mozilla.firefox AppleEnableMouseSwipeNavigateWithScrolls -bool false
defaults write org.mozilla.firefox-developer-edition AppleEnableSwipeNavigateWithScrolls -bool false
defaults write org.mozilla.firefox-developer-edition AppleEnableMouseSwipeNavigateWithScrolls -bool false

# Safari
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true

# Activity Monitor
defaults write com.apple.ActivityMonitor ShowCategory -int 0
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection -int 0

for app in Finder Dock SystemUIServer; do
    killall "$app" >/dev/null 2>&1 || true
done

printf '\nmacOS system settings applied. Reboot or log out for all changes to take effect.\n'
