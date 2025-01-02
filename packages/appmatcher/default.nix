{ pkgs, ... }: with pkgs;
let
  uuid = "appmatcher@iberianpig.dev";
  pname = "fusuma-plugin-appmatcher";
  version = 1;
in
  lib.makeOverridable stdenv.mkDerivation {
    pname = "gnome-shell-extension-${pname}";
    version = builtins.toString version;
    src = ./../..;
    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/gnome-shell/extensions/
      cp -r -T ./lib/fusuma/plugin/appmatcher/gnome_extensions/${uuid} $out/share/gnome-shell/extensions/${uuid}
      runHook postInstall
    '';
    meta = {
      description = "Fusuma plugin configure app-specific gestures";
      homepage = "https://github.com/iberianpig/fusuma-plugin-appmatcher";
      license = lib.licenses.mit;
      platforms = lib.platforms.linux;
    };
    passthru = {
      extensionPortalSlug = pname;
      # Store the extension's UUID, because we might need it at some places
      extensionUuid = uuid;
    };
  }