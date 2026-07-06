{
  pkgs,
  ...
}:
let
  mkObsidianPlugin =
    {
      pname,
      version,
      owner,
      repo,
      hashMainJs,
      hashManifestJson,
      hashStylesCss ? null,
    }:
    let
      # Use version as the tag for the download URL
      baseUrl = "https://github.com/${owner}/${repo}/releases/download/${version}";
      mainJs = pkgs.fetchurl {
        url = "${baseUrl}/main.js";
        hash = hashMainJs;
      };
      manifestJson = pkgs.fetchurl {
        url = "${baseUrl}/manifest.json";
        hash = hashManifestJson;
      };
      stylesCss =
        if hashStylesCss != null then
          pkgs.fetchurl {
            url = "${baseUrl}/styles.css";
            hash = hashStylesCss;
          }
        else
          null;
    in
    pkgs.stdenvNoCC.mkDerivation {
      inherit pname version;
      dontUnpack = true;
      installPhase = ''
        runHook preInstall
        mkdir -p $out
        cp ${mainJs} $out/main.js
        cp ${manifestJson} $out/manifest.json
        ${if stylesCss != null then "cp ${stylesCss} $out/styles.css" else ""}
        runHook postInstall
      '';
    };
in
{
  heatmap-calendar = mkObsidianPlugin {
    pname = "heatmap-calendar";
    version = "0.7.1";
    owner = "Richardsl";
    repo = "heatmap-calendar-obsidian";
    hashMainJs = "sha256-aHY6cRsjKE/xVRv+aFg3RRpAWbdNOce9EhZZyeaiWbo=";
    hashManifestJson = "sha256-3YeYBNgebV1FV8zMvl8Ics1dEQvY/DUu5QPZ1YUtFO0=";
    hashStylesCss = "sha256-X7+rYZVoAihsT8ZQTHljVgh6ixTy48lhP6jANsg+0L0=";
  };

  kanban = mkObsidianPlugin {
    pname = "obsidian-kanban";
    version = "2.0.51";
    owner = "obsidian-community";
    repo = "obsidian-kanban";
    hashMainJs = "sha256-p+O9TPJfm39TqEHETOmQ2w7195VOvKsXrm3KgDEMOaw=";
    hashManifestJson = "sha256-JJdnhwl+rUZ5aeAUo1ZU56gOTbSal3aJpIr636FeGFQ=";
    hashStylesCss = "sha256-7PbdMfFyfEQczm9UeUsNORbc//yH+he4VceboEqF2ac=";
  };

  notebook-navigator = mkObsidianPlugin {
    pname = "notebook-navigator";
    version = "3.2.2";
    owner = "johansan";
    repo = "notebook-navigator";
    hashMainJs = "sha256-nh9sqjOmglMYD0TA6WLkN/d6mO31QA3AzMMTj495bv8=";
    hashManifestJson = "sha256-kpYI69RaCubbyyFGebtkMMi/NzeWpSN2n4od0GM+rh8=";
    hashStylesCss = "sha256-WZHFg/mJZIRM6TZefys/zFeRIHJzXWg+Wr5Fwariazg=";
  };

  dataview = mkObsidianPlugin {
    pname = "obsidian-dataview";
    version = "0.5.70";
    owner = "blacksmithgu";
    repo = "obsidian-dataview";
    hashMainJs = "sha256-a7HPcBCvrYMOc1dfyg4r+9MnnFYuPZ0k8tL0UWHrfQA=";
    hashManifestJson = "sha256-kjXbRxEtqBuFWRx57LmuJXTl5yIHBW6XZHL5BhYoYYU=";
    hashStylesCss = "sha256-MwbdkDLgD5ibpyM6N/0lW8TT9DQM7mYXYulS8/aqHek=";
  };

  quickadd = mkObsidianPlugin {
    pname = "quickadd";
    version = "2.17.2";
    owner = "chhoumann";
    repo = "quickadd";
    hashMainJs = "sha256-yPODyV+r+LFzyNd+BIUlCjsuCXPbYa6ZRcBlzNxuI34=";
    hashManifestJson = "sha256-2eyUCo9zsO5bbG52SiiOuekZHWDcS0M+UtMeVX83Dbo=";
    hashStylesCss = "sha256-SxnWmpiiLFx777fYQa4SzfkHYgdMfMgZNeDbjjLGBd0=";
  };

  periodic-notes = pkgs.fetchzip {
    url = "https://github.com/liamcain/obsidian-periodic-notes/releases/download/1.0.0-beta.3/periodic-notes-1.0.0-beta.3.zip";
    name = "periodic-notes";
    hash = "sha256-kqs+X6wb0YTnhXX1MGPW3C9S/387FfavmmfYlCGI1dc=";
  };

  templater = pkgs.fetchzip {
    url = "https://github.com/SilentVoid13/Templater/releases/download/2.23.1/templater-obsidian.zip";
    name = "templater-obsidian";
    stripRoot = false;
    hash = "sha256-3OLukyblgf+zw/Nt8obliCpCMsWBNNaHcDaDh43DUmY=";
  };

  tasks = pkgs.fetchzip {
    url = "https://github.com/obsidian-tasks-group/obsidian-tasks/releases/download/8.2.2/obsidian-tasks-8.2.2.zip";
    name = "obsidian-tasks";
    hash = "sha256-m5MoupjOV97tIAq3KTlrgHlqSrrGWGb+kA7Q2yAbcFw=";
  };
}
