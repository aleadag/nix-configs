{ config, lib, ... }:

{
  options.home-manager.dev.ollama.enable = lib.mkEnableOption "Ollama service";

  config = lib.mkIf config.home-manager.dev.ollama.enable {
    services.ollama.enable = true;
  };
}
