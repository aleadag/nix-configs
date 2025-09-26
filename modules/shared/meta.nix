{ lib, ... }:

{
  options.meta = {
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
