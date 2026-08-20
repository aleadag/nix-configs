{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.mutableConfig;

  activeFiles = lib.filterAttrs (_: fileSpec: fileSpec.enable) cfg.files;

  toRelPath =
    path:
    let
      prefix = "${config.home.homeDirectory}/";
    in
    if lib.hasPrefix prefix path then lib.removePrefix prefix path else path;

  # Helper to generate activation script for a single file
  makeActivationScript =
    filePath: fileSpec:
    let
      relPath = toRelPath filePath;
      settingsFile =
        if fileSpec.source != null then
          fileSpec.source
        else if fileSpec.settings != { } then
          (pkgs.formats.${fileSpec.format} { }).generate "mutable-settings" fileSpec.settings
        else if config.home.file ? ${relPath} && (config.home.file.${relPath}.source or null) != null then
          config.home.file.${relPath}.source
        else
          null;
    in
    lib.optionalString (settingsFile != null) ''
      config_path="${filePath}"
      backup_ext="''${HOME_MANAGER_BACKUP_EXT:-}"
      backup_path="$config_path''${backup_ext:+.$backup_ext}"
      tmp="$(mktemp)"

      if [ ! -e "$config_path" ]; then
        mkdir -p "$(dirname "$config_path")"
        touch "$config_path"
      fi

      if [ -n "$backup_ext" ] && [ -e "$backup_path" ]; then
        ${lib.getExe pkgs.yq-go} eval-all -p=${fileSpec.format} -o=${fileSpec.format} '. as $item ireduce ({}; . * $item)' "$backup_path" "$config_path" "${settingsFile}" > "$tmp"
        $DRY_RUN_CMD mv "$tmp" "$config_path"
        $DRY_RUN_CMD chmod 600 "$config_path"
        $DRY_RUN_CMD rm -f "$backup_path"
      elif [[ -v DRY_RUN ]]; then
        echo "${lib.getExe pkgs.yq-go} eval-all -p=${fileSpec.format} -o=${fileSpec.format} '. as \$item ireduce ({}; . * \$item)' '$config_path' '${settingsFile}' > '$tmp'"
        echo mv "$tmp" "$config_path"
        echo chmod 600 "$config_path"
      else
        ${lib.getExe pkgs.yq-go} eval-all -p=${fileSpec.format} -o=${fileSpec.format} '. as $item ireduce ({}; . * $item)' "$config_path" "${settingsFile}" > "$tmp"
        $DRY_RUN_CMD mv "$tmp" "$config_path"
        $DRY_RUN_CMD chmod 600 "$config_path"
      fi
    '';

  allActivationScripts = lib.concatStrings (lib.mapAttrsToList makeActivationScript activeFiles);
in
{
  options.mutableConfig = {
    files = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Whether to manage this file mutably";
            };
            format = lib.mkOption {
              type = lib.types.enum [
                "json"
                "toml"
                "yaml"
              ];
              default = "json";
              description = "Serialization format of the settings file";
            };
            source = lib.mkOption {
              type = lib.types.nullOr lib.types.path;
              default = null;
              description = "Home Manager-generated store path or file to merge";
            };
            settings = lib.mkOption {
              type = lib.types.attrs;
              default = { };
              description = "Attribute set mapping file settings to merge";
            };
          };
        }
      );
      default = { };
      description = "Attribute set mapping target file paths to their mutable settings specification";
    };
  };

  config = lib.mkIf (activeFiles != { }) {
    # Disable home manager's management of configured files
    home.file = lib.mkMerge (
      lib.mapAttrsToList (file: _: {
        ${toRelPath file}.enable = lib.mkForce false;
      }) activeFiles
    );

    # Add activation script to merge settings
    home.activation.injectMutableSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${allActivationScripts}
    '';
  };
}
