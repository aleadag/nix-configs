{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.home-manager.darwin.nvim-app;
  bundleId = "com.aleadag.nvim";
  nvim = config.programs.neovim.finalPackage;
  kitty =
    if config.programs.kitty.package != null then
      "${config.programs.kitty.package}/bin/kitty"
    else
      "${config.home-manager.darwin.homebrew.prefix}/bin/kitty";

  # UTIs to associate with nvim (via `open`).
  fileTypes = [
    "net.daringfireball.markdown"
    "public.plain-text"
    "public.source-code"
    "public.shell-script"
    "public.json"
  ];

  infoPlist = pkgs.writeText "Info.plist" ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>CFBundleExecutable</key>
      <string>nvim</string>
      <key>CFBundleIdentifier</key>
      <string>${bundleId}</string>
      <key>CFBundleName</key>
      <string>Nvim</string>
      <key>CFBundlePackageType</key>
      <string>APPL</string>
      <key>CFBundleShortVersionString</key>
      <string>1.0</string>
      <key>CFBundleVersion</key>
      <string>1.0</string>
      <key>LSUIElement</key>
      <true/>
    </dict>
    </plist>
  '';

  # Launch Services delivers opened files via an Apple Event, not argv, so a
  # plain shell script never sees them. This ObjC shim translates the
  # `openFiles:` event into a `kitty -- nvim <files>` invocation.
  launcherSource = pkgs.writeText "launcher.m" ''
    #import <Cocoa/Cocoa.h>

    @interface AppDelegate : NSObject <NSApplicationDelegate>
    @end

    @implementation AppDelegate

    - (void)application:(NSApplication *)sender openFiles:(NSArray<NSString *> *)filenames {
        NSMutableArray *arguments = [NSMutableArray arrayWithArray:@[
            @"--single-instance",
            @"--",
            @"${nvim}/bin/nvim"
        ]];
        [arguments addObjectsFromArray:filenames];

        NSTask *task = [[NSTask alloc] init];
        [task setLaunchPath:@"${kitty}"];
        [task setArguments:arguments];
        [task launch];

        [NSApp terminate:nil];
    }

    @end

    int main(int argc, const char *argv[]) {
        @autoreleasepool {
            NSApplication *app = [NSApplication sharedApplication];
            AppDelegate *delegate = [[AppDelegate alloc] init];
            [app setDelegate:delegate];
            [app run];
        }
        return 0;
    }
  '';

  launcher = pkgs.runCommand "nvim-app-launcher" { nativeBuildInputs = [ pkgs.clang ]; } ''
    mkdir -p "$out/bin"
    clang -framework Cocoa -O2 -o "$out/bin/nvim-launcher" ${launcherSource}
  '';

  nvimApp = pkgs.runCommand "Nvim.app" { } ''
    app="$out/Nvim.app"
    mkdir -p "$app/Contents/MacOS"
    cp ${infoPlist} "$app/Contents/Info.plist"
    cp ${launcher}/bin/nvim-launcher "$app/Contents/MacOS/nvim"
    chmod +x "$app/Contents/MacOS/nvim"
  '';

  dutiCommands = lib.concatMapStringsSep "\n" (
    type: "${pkgs.duti}/bin/duti -s ${bundleId} ${type} all"
  ) fileTypes;
in
{
  options.home-manager.darwin.nvim-app = {
    enable = lib.mkEnableOption "Nvim .app wrapper so `open` launches nvim" // {
      default = config.programs.neovim.enable;
    };
  };

  config = lib.mkIf (config.home-manager.darwin.enable && cfg.enable) {
    home.activation.installNvimApp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      apps_dir="$HOME/Applications"
      mkdir -p "$apps_dir"
      chmod -R u+w "$apps_dir/Nvim.app" 2>/dev/null || true
      rm -rf "$apps_dir/Nvim.app"
      cp -R ${nvimApp}/Nvim.app "$apps_dir/Nvim.app"
      chmod -R u+w "$apps_dir/Nvim.app"
      /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$apps_dir/Nvim.app"
      ${dutiCommands}
    '';
  };
}
