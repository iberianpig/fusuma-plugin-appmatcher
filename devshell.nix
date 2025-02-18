{ flake, pkgs }:
pkgs.mkShell {
  # Add build dependencies
  packages = [
    pkgs.ruby
    pkgs.libyaml
  ];

  # Add environment variables
  env = { };

  # Load custom bash code
  shellHook = ''

  '';
}
