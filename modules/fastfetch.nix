{ pkgs, ... }:

{
  programs.fastfetch = {
    enable = true;

    settings = {
      logo = {
        type = "small";
        source = "apple";
        padding = {
          top = 1;
          left = 2;
          right = 5;
        };
        color = {
          "1" = "magenta";
        };
      };

      display = {
        separator = "  ";
        color = "1";
        key = {
          type = "icon";
        };
      };

      modules = [
        "break"
        {
          type = "title";
          format = "{user-name-colored}{at-symbol-colored}{host-name-colored}";
        }
        {
          type = "cpu";
          keyColor = "blue";
        }
        {
          type = "gpu";
          keyColor = "blue";
        }
        {
          type = "memory";
          keyColor = "blue";
        }
        {
          type = "disk";
          keyColor = "blue";
        }
        "break"
      ];
    };
  };
}

