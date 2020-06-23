{ lib, pkgs, ... }:
{
  systemd.user.services.hapture = {
    Unit.Description = "Hapture server";
    Install.WantedBy = [ "default.target" ];
    Service = {
      Type = "simple";
      ExecStart = lib.strings.concatStringsSep " " [
        "${builtins.getEnv "HOME"}/.local/bin/hapture"
        "--path ${builtins.getEnv "HOME"}/org/refile.org"
      ];
      Restart = "always";
    };
  };
}
