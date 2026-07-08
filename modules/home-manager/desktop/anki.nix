{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.home-manager.desktop.anki;
  ankiMcpPythonDeps = pkgs.python3.withPackages (
    ps: with ps; [
      anyio
      httpx
      mcp
      packaging
      pydantic
      pydantic-settings
      starlette
      uvicorn
      websockets
    ]
  );
  ankiMcpServer = pkgs.anki-utils.buildAnkiAddon (finalAttrs: {
    pname = "anki-mcp-server";
    version = "0.25.0";
    src = pkgs.fetchFromGitHub {
      owner = "ankimcp";
      repo = "anki-mcp-server-addon";
      rev = "v${finalAttrs.version}";
      hash = "sha256-d+XVzeXWFF7xe2TAUY06kbvsZ40OA+jG5upjzb74ksQ=";
    };
    sourceRoot = "${finalAttrs.src.name}/anki_mcp_server";
    postFixup = ''
      addonDir="$out/share/anki/addons/anki-mcp-server"

      rm -rf "$addonDir/vendor/shared"
      mkdir -p "$addonDir/vendor/shared"
      for entry in ${ankiMcpPythonDeps}/${pkgs.python3.sitePackages}/*; do
        ln -s "$entry" "$addonDir/vendor/shared/"
      done

      rm -rf "$addonDir/_cache"
    '';
  });
in
{
  options.home-manager.desktop.anki.enable = lib.mkEnableOption "Anki config" // {
    default = config.home-manager.desktop.enable;
  };

  config = lib.mkIf cfg.enable {
    programs.anki = {
      enable = true;
      addons = [
        ankiMcpServer
      ];
      profiles."Alexander" = {
        default = true;
        sync = {
          username = "ylsdwang@gmail.com";
          syncMedia = true;
        };
      };
    };
  };
}
