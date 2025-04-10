{ config, lib, ... }:

{
  options.meta = {
    username = lib.mkOption {
      description = "Main username.";
      type = lib.types.str;
      default = config.home.username or "awang";
    };
    fullname = lib.mkOption {
      description = "Main user full name.";
      type = lib.types.str;
      default = "Alexander Wang";
    };
    email = lib.mkOption {
      description = "Main e-mail.";
      type = lib.types.str;
      default = "aleadag@gmail.com";
    };
  };
}
