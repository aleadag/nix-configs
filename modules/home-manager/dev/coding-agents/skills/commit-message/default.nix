{
  config,
  lib,
  pkgs,
}:

pkgs.symlinkJoin {
  name = "commit-message-skill";
  paths = [ ];
  postBuild = ''
    mkdir -p $out/references

    # Copy base SKILL.md
    cat ${./SKILL.md} > $out/SKILL.md

    # Add references section with conditional jujutsu link
    echo "" >> $out/SKILL.md
    echo "For the final apply step, load exactly one reference:" >> $out/SKILL.md
    echo "" >> $out/SKILL.md
    echo "- Git: [references/git.md](references/git.md)" >> $out/SKILL.md
  ''
  + lib.optionalString (config.home-manager.cli.jujutsu.enable or false) ''
    echo "- Jujutsu: [references/jj.md](references/jj.md)" >> $out/SKILL.md
  ''
  + ''
    # Copy reference files
    cp ${./references/git.md} $out/references/git.md
  ''
  + lib.optionalString (config.home-manager.cli.jujutsu.enable or false) ''
    cp ${./references/jj.md} $out/references/jj.md
  '';
}
