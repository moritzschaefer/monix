{ users, ... }:
{
  services.xserver.enable = false;
  services.xserver.desktopManager.kodi.enable = false;
  services.xserver.displayManager.autoLogin.enable = false;
  services.xserver.displayManager.autoLogin.user = "kodi";

  # Define a user account
  users.extraUsers.kodi.isNormalUser = true;
  nixpkgs.config.kodi.enableAdvancedLauncher = true;
}
