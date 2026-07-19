@{
    # Sources are relative to the repository root. Targets are relative to the
    # named Windows folder. This is a reference for manage.ps1, not a second
    # copy of any configuration.
    Entries = @(
        # Shared packages already present in this repository.
        @{ Name = 'Git';        Mode = 'Link'; Source = 'git/.gitconfig';        TargetRoot = 'Home';         Target = '.gitconfig' }
        @{ Name = 'Bash';       Mode = 'Link'; Source = 'bash/.bashrc';          TargetRoot = 'Home';         Target = '.bashrc' }
        @{ Name = 'Zsh';        Mode = 'Link'; Source = 'zsh/.zshrc';            TargetRoot = 'Home';         Target = '.zshrc' }
        @{ Name = 'Zprofile';   Mode = 'Link'; Source = 'zsh/.zprofile';         TargetRoot = 'Home';         Target = '.zprofile' }
        @{ Name = 'ZshPlugins'; Mode = 'Link'; Source = 'zsh/.zsh_plugins.txt';  TargetRoot = 'Home';         Target = '.zsh_plugins.txt' }
        @{ Name = 'Aliases';    Mode = 'Link'; Source = 'aliases/.aliases';     TargetRoot = 'Home';         Target = '.aliases' }
        @{ Name = 'Functions';  Mode = 'Link'; Source = 'functions/.functions'; TargetRoot = 'Home';         Target = '.functions' }
        @{ Name = 'Vim';        Mode = 'Link'; Source = 'vim/.vimrc';           TargetRoot = 'Home';         Target = '.vimrc' }
        @{ Name = 'Neovim';     Mode = 'Link'; Source = 'nvim/.config/nvim';    TargetRoot = 'LocalAppData'; Target = 'nvim' }
        @{ Name = 'Mise';       Mode = 'Link'; Source = 'windows/.config/mise/config.toml'; TargetRoot = 'Home'; Target = '.config/mise/config.toml' }

        # Windows package: this tree mirrors paths under $HOME and can also be
        # used with Stow from WSL.
        @{ Name = 'Mintty';     Mode = 'Link'; Source = 'windows/.minttyrc'; TargetRoot = 'Home'; Target = '.minttyrc' }
        @{ Name = 'GitBashProfile'; Mode = 'Link'; Source = 'windows/.bash_profile'; TargetRoot = 'Home'; Target = '.bash_profile' }
        @{ Name = 'PowerShell'; Mode = 'Link'; Source = 'windows/Documents/PowerShell/Microsoft.PowerShell_profile.ps1'; TargetRoot = 'Home'; Target = 'Documents/PowerShell/Microsoft.PowerShell_profile.ps1' }

        # Microsoft Store / GUI app settings: keep these as real files. Apply
        # copies them deliberately; do not create a link until we have tested
        # each application on the Windows machine.
        # PowerToys writes these machine/runtime facts itself. They are not
        # preferences and must not make a second setup run overwrite settings.
        @{ Name = 'PowerToys';        Mode = 'Copy'; Source = 'windows/AppData/Local/Microsoft/PowerToys/settings.json'; TargetRoot = 'Home'; Target = 'AppData/Local/Microsoft/PowerToys/settings.json'; IgnoreProperties = @('is_admin', 'is_elevated', 'powertoys_version', 'system_theme') }
        @{ Name = 'WinGetSettings';   Mode = 'Copy'; Source = 'windows/AppData/Local/Packages/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe/LocalState/settings.json'; TargetRoot = 'Home'; Target = 'AppData/Local/Packages/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe/LocalState/settings.json' }
        @{ Name = 'WindowsTerminal';  Mode = 'Copy'; Source = 'windows/AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json'; TargetRoot = 'Home'; Target = 'AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json' }
    )
}
