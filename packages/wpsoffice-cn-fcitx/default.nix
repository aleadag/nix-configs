{
  stdenv,
  wpsoffice-cn,
  makeWrapper,
}:

stdenv.mkDerivation {
  name = "wpsoffice-cn-fcitx";

  dontUnpack = true;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share
    ln -s ${wpsoffice-cn}/share/* -t $out/share

    rm $out/share/applications
    cp -r ${wpsoffice-cn}/share/applications -t $out/share
    chmod -R u+w $out/share/applications
    for desktop in $out/share/applications/*; do
      sed -i \
        -e "s|^Exec=${wpsoffice-cn}/bin/et |Exec=$out/bin/et |" \
        -e "s|^Exec=${wpsoffice-cn}/bin/wpp |Exec=$out/bin/wpp |" \
        -e "s|^Exec=${wpsoffice-cn}/bin/wps |Exec=$out/bin/wps |" \
        -e "s|^Exec=${wpsoffice-cn}/bin/wpspdf |Exec=$out/bin/wpspdf |" \
        -e "s|^Exec=et |Exec=$out/bin/et |" \
        -e "s|^Exec=wpp |Exec=$out/bin/wpp |" \
        -e "s|^Exec=wps |Exec=$out/bin/wps |" \
        -e "s|^Exec=wpspdf |Exec=$out/bin/wpspdf |" \
        "$desktop"
    done

    if [ -d ${wpsoffice-cn}/share/templates ]; then
      rm $out/share/templates
      cp -r ${wpsoffice-cn}/share/templates -t $out/share
      chmod -R u+w $out/share/templates
      for desktop in $out/share/templates/*; do
        substituteInPlace $desktop \
          --replace-warn wps文字文档 WPS文字文档 \
          --replace-warn wps演示文档 WPS演示文稿 \
          --replace-warn wps表格文档 WPS表格工作表 \
          --replace-fail URL=.source URL=${wpsoffice-cn}/opt/kingsoft/wps-office/templates
      done
    fi

    mkdir -p $out/bin
    ln -s ${wpsoffice-cn}/bin/* -t $out/bin
    for exe in $out/bin/*; do
      wrapProgram $exe \
        --prefix XMODIFIERS : @im=fcitx \
        --prefix GTK_IM_MODULE : fcitx \
        --prefix QT_IM_MODULE : fcitx
    done

    runHook postInstall
  '';

  meta = wpsoffice-cn.meta // {
    description = "WPS Office CN wrapper with Fcitx support";
    mainProgram = "wps";
  };
}
