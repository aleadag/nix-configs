{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.home-manager.desktop.obsidian.enable = lib.mkEnableOption "Obsidian config" // {
    default = config.home-manager.desktop.enable;
  };

  config = lib.mkIf config.home-manager.desktop.obsidian.enable {
    programs.obsidian = {
      enable = true;
      cli.enable = true;
      defaultSettings = {
        app = {
          alwaysUpdateLinks = true;
          attachmentFolderPath = "_Media";
          newFileFolderPath = "0-Inbox";
          newFileLocation = "folder";
          promptDelete = false;
          safeMode = false;
          showLineNumber = true;
          vimMode = true;
        };
      };
      vaults =
        let
          corePlugins = [
            "backlink"
            "bases"
            "bookmarks"
            "command-palette"
            "editor-status"
            "file-recovery"
            "global-search"
            "graph"
            "note-composer"
            "outgoing-link"
            "outline"
            "page-preview"
            "switcher"
            "tag-pane"
            "templates"
            "word-count"
            "zk-prefixer"
          ];
          plugins = pkgs.callPackage ./plugins.nix { inherit pkgs; };
        in
        {
          awang = {
            target = "sync/AWANG";
            settings.corePlugins = [
              {
                name = "daily-notes";
                enable = true;
                settings = {
                  autorun = false;
                  folder = "-Daily-Notes";
                  template = "5-Templates/Daily-Notes";
                };
              }
            ]
            ++ corePlugins;
          };
          lucid = {
            target = "hacking/tiwater/lucid/lucid-docs";
            settings.corePlugins = [
              "file-explorer"
            ]
            ++ corePlugins;
          };
          lifewiki = {
            target = "Lifewiki";
            settings = {
              corePlugins = [
                "bases"
                {
                  name = "daily-notes";
                  enable = true;
                  settings = {
                    autorun = false;
                    folder = "-Daily-Notes";
                    template = "5-Templates/Daily-Notes";
                  };
                }
              ]
              ++ corePlugins;
              communityPlugins = with plugins; [
                heatmap-calendar
                notebook-navigator
                kanban
                {
                  pkg = dataview;
                  settings = {
                    inlineQueriesInCodeblocks = true;
                    enableInlineDataview = true;
                    enableDataviewJs = true;
                    enableInlineDataviewJs = true;
                  };
                }
                {
                  pkg = periodic-notes;
                  settings = {
                    showGettingStartedBanner = false;
                    hasMigratedDailyNoteSettings = true;
                    hasMigratedWeeklyNoteSettings = false;
                    daily = {
                      folder = "-Daily-Notes";
                      template = "5-Templates/Daily-Notes.md";
                      enabled = true;
                      format = "YYYY-MM-DD";
                    };
                    weekly = {
                      format = "GGGG-[W]WW";
                      template = "5-Templates/Weekly-Notes.md";
                      folder = "-Periodic-Notes";
                      enabled = true;
                    };
                    monthly = {
                      format = "YYYY-MM";
                      template = "5-Templates/Monthly-Notes.md";
                      folder = "-Periodic-Notes";
                      enabled = true;
                    };
                    quarterly = {
                      format = "YYYY-[Q]Q";
                      template = "5-Templates/Quarterly-Notes.md";
                      folder = "-Periodic-Notes";
                      enabled = true;
                    };
                    yearly = {
                      format = "YYYY";
                      template = "5-Templates/Yearly-Notes.md";
                      folder = "-Periodic-Notes";
                      enabled = true;
                    };
                  };
                }
                {
                  pkg = quickadd;
                  settings = {
                    choices = [
                      {
                        id = "dad7b11b-b288-4838-81b7-680152ca1766";
                        name = "Create Something";
                        type = "Multi";
                        command = true;
                        choices = [
                          {
                            id = "8b997f24-c23d-4911-8f5d-360903ef9c69";
                            name = "Create Project";
                            type = "Capture";
                            command = true;
                            appendLink = false;
                            captureTo = "2-Areas/";
                            captureToActiveFile = false;
                            createFileIfItDoesntExist = {
                              enabled = true;
                              createWithTemplate = true;
                              template = "5-Templates/Areas.md";
                            };
                            format = {
                              enabled = true;
                              format = "[[{{VALUE}}]] ➕ {{DATE}}";
                            };
                            insertAfter = {
                              enabled = true;
                              after = "## Projects 🎯";
                              insertAtEnd = true;
                              considerSubsections = false;
                              createIfNotFound = false;
                              createIfNotFoundLocation = "bottom";
                            };
                            prepend = false;
                            task = true;
                            openFileInNewTab = {
                              enabled = false;
                              direction = "vertical";
                              focus = true;
                            };
                            openFile = true;
                            openFileInMode = "default";
                          }
                          {
                            id = "123bcf64-17f4-4405-8e7c-05a26daabdfa";
                            name = "Create One-Off Task";
                            type = "Capture";
                            command = true;
                            appendLink = false;
                            captureTo = "-Daily-Notes/{{DATE}}";
                            captureToActiveFile = false;
                            createFileIfItDoesntExist = {
                              enabled = true;
                              createWithTemplate = true;
                              template = "5-Templates/Daily-Notes.md";
                            };
                            format = {
                              enabled = true;
                              format = "{{VALUE}} ➕ {{DATE}}";
                            };
                            insertAfter = {
                              enabled = true;
                              after = "## Notes 📝\\n";
                              insertAtEnd = true;
                              considerSubsections = false;
                              createIfNotFound = false;
                              createIfNotFoundLocation = "top";
                            };
                            prepend = false;
                            task = true;
                            openFileInNewTab = {
                              enabled = false;
                              direction = "vertical";
                              focus = true;
                            };
                            openFile = true;
                            openFileInMode = "default";
                          }
                          {
                            id = "96917cbb-f169-4448-aa0f-767258a15e02";
                            name = "Create Someday Maybe";
                            type = "Capture";
                            command = true;
                            appendLink = false;
                            captureTo = "Someday Maybe 💭.md";
                            captureToActiveFile = false;
                            createFileIfItDoesntExist = {
                              enabled = false;
                              createWithTemplate = false;
                              template = "";
                            };
                            format = {
                              enabled = true;
                              format = "- {{VALUE}} ➕ {{DATE}}";
                            };
                            insertAfter = {
                              enabled = true;
                              after = "## Inbox";
                              insertAtEnd = true;
                              considerSubsections = false;
                              createIfNotFound = false;
                              createIfNotFoundLocation = "top";
                            };
                            prepend = false;
                            task = false;
                            openFileInNewTab = {
                              enabled = false;
                              direction = "vertical";
                              focus = true;
                            };
                            openFile = true;
                            openFileInMode = "default";
                          }
                          {
                            id = "4e069106-0b50-4db3-8a84-8daba5d26caf";
                            name = "Create Passion";
                            type = "Capture";
                            command = true;
                            appendLink = false;
                            captureTo = "Passions Backlog 🎮.md";
                            captureToActiveFile = false;
                            createFileIfItDoesntExist = {
                              enabled = false;
                              createWithTemplate = false;
                              template = "";
                            };
                            format = {
                              enabled = true;
                              format = "{{VALUE}}";
                            };
                            insertAfter = {
                              enabled = true;
                              after = "## Wishlist";
                              insertAtEnd = false;
                              considerSubsections = false;
                              createIfNotFound = false;
                              createIfNotFoundLocation = "top";
                            };
                            prepend = false;
                            task = true;
                            openFileInNewTab = {
                              enabled = false;
                              direction = "vertical";
                              focus = true;
                            };
                            openFile = true;
                            openFileInMode = "default";
                          }
                        ];
                      }
                    ];
                    macros = [
                      {
                        name = "TaskSync";
                        id = "0808cd06-f809-434f-91b9-db4aca7dfb2c";
                        commands = [
                          {
                            name = "tasksync::SelectFromAllTasks";
                            type = "UserScript";
                            id = "ea8aebe5-e3b2-4e74-8bd5-496e68703195";
                            path = "_Scripts/tasksync.js";
                            settings = { };
                          }
                        ];
                        runOnStartup = false;
                      }
                      {
                        name = "JournalSync";
                        id = "6572ca9c-7948-4004-b466-dbc5d3b90f05";
                        commands = [
                          {
                            name = "journalsync::SelectFromAllTasks";
                            type = "UserScript";
                            id = "b363a144-1e37-4093-b9db-ff32c4373bab";
                            path = "_Scripts/journalsync.js";
                            settings = { };
                          }
                        ];
                        runOnStartup = false;
                      }
                      {
                        name = "PassionSync";
                        id = "056d1b13-02cb-4e52-9e7b-9db7ba22c28e";
                        commands = [
                          {
                            name = "passionsync::SelectFromAllTasks";
                            type = "UserScript";
                            id = "65d06f67-4d48-42b7-8d30-8a923d0fef19";
                            path = "_Scripts/passionsync.js";
                            settings = { };
                          }
                        ];
                        runOnStartup = false;
                      }
                      {
                        name = "SomedaySync";
                        id = "ac956cf2-1acb-4196-96ea-962b3408babb";
                        commands = [
                          {
                            name = "somedaysync::SelectFromAllTasks";
                            type = "UserScript";
                            id = "5041ee03-8382-4959-98cc-4ef920a5bba7";
                            path = "_Scripts/somedaysync.js";
                            settings = { };
                          }
                        ];
                        runOnStartup = false;
                      }
                      {
                        name = "ProjectSync";
                        id = "ade00d0a-42d1-4dd3-9bdf-1b3ad5d1cdc8";
                        commands = [
                          {
                            name = "projectsync::SelectFromAllTasks";
                            type = "UserScript";
                            id = "e8d6634f-68b1-49e1-b5e6-976189b1a2b6";
                            path = "_Scripts/projectsync.js";
                            settings = { };
                          }
                        ];
                        runOnStartup = false;
                      }
                    ];
                    inputPrompt = "single-line";
                    templateFolderPath = "5-Templates";
                    disableOnlineFeatures = true;
                  };
                }
                {
                  pkg = templater;
                  settings = {
                    auto_jump_to_cursor = true;
                    enable_folder_templates = true;
                    enable_ribbon_icon = true;
                    folder_templates = [
                      {
                        folder = "/";
                        template = "5-Templates/Filename-Template.md";
                      }
                    ];
                    syntax_highlighting = true;
                    templates_folder = "5-Templates";
                    trigger_on_file_creation = true;
                  };
                }
                {
                  pkg = tasks;
                  settings = {
                    globalQuery = "path does not include _Sources\npath does not include 5-Templates";
                    setCreatedDate = true;
                  };
                }
              ];
            };
          };
        };
    };
  };
}
