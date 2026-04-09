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
    version = "2.5.6";
    owner = "johansan";
    repo = "notebook-navigator";
    hashMainJs = "sha256-qWJjDHQ8JeZ5XkWLPRbN426jLKCYzrjQoFj4Ncn9akA=";
    hashManifestJson = "sha256-qoBSO5+oRJxlGYc2yRvxRSgvroS3FR4a/tjYgGf7P9g=";
    hashStylesCss = "sha256-0aCp2/qOE+1UTDmw1MFTrdzGzpl7NEVMH5orXiOcfhE=";
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
    version = "2.12.0";
    owner = "chhoumann";
    repo = "quickadd";
    hashMainJs = "sha256-4JQDvZ4g/pev/R1TIlugn76tp/XgJN3otkxYkFKb/74=";
    hashManifestJson = "sha256-jquOX5wWMt/waHXHm7VYMqCoL2/s4kbgVyjKvb6CSIk=";
    hashStylesCss = "sha256-6CDyjLti9gRyegen3uYUOG52XvPZi8VBrIY85ZYby6I=";
  };

  periodic-notes = pkgs.fetchzip {
    url = "https://github.com/liamcain/obsidian-periodic-notes/releases/download/1.0.0-beta.3/periodic-notes-1.0.0-beta.3.zip";
    name = "periodic-notes";
    hash = "sha256-kqs+X6wb0YTnhXX1MGPW3C9S/387FfavmmfYlCGI1dc=";
  };

  templater = pkgs.fetchzip {
    url = "https://github.com/SilentVoid13/Templater/releases/download/2.18.1/templater-obsidian.zip";
    name = "templater-obsidian";
    stripRoot = false;
    hash = "sha256-xh6iQn0IXsa2gJH8360MQagpJT3M4+FrdWQGMOH5d7E=";
  };

  tasks = pkgs.fetchzip {
    url = "https://github.com/obsidian-tasks-group/obsidian-tasks/releases/download/7.23.1/obsidian-tasks-7.23.1.zip";
    name = "obsidian-tasks";
    hash = "sha256-/iHHTVzN3Cv7w4kwlfHUghnSsT8VFt3G75aetdk0OGE=";
  };
}
