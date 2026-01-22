{ config, pkgs, ... }:

{
  # Install Neovim and language servers
  environment.systemPackages = with pkgs; [
    neovim

    # Language servers
    pyright          # Python
    clang-tools      # C/C++ (includes clangd)
    nixd             # Nix
    jdt-language-server  # Java

    # Essential tools for Telescope and other plugins
    ripgrep          # Fast grep for Telescope
    fd               # Fast find for Telescope
    nodejs           # Required by many plugins
    gcc              # Treesitter compilation
  ];

  # Nerd Fonts for icons in nvim
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  # Set neovim as default editor
  environment.variables.EDITOR = "nvim";

  # Aliases
  programs.bash.shellAliases = {
    vi = "nvim";
    vim = "nvim";
  };
}
