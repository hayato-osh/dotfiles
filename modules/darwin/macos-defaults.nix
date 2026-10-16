{ host, ... }:

{
  system.defaults = {
    dock = {
      orientation = "left";
      tilesize = 50;
      largesize = 80;
      autohide = true;
      show-recents = false;
      mineffect = "genie";
      mru-spaces = false;
    };

    screencapture = {
      disable-shadow = true;
      location = "${host.homeDirectory}/Desktop";
      type = "png";
    };

    finder = {
      QuitMenuItem = true;
      ShowPathbar = true;
      _FXSortFoldersFirst = true;
      FXDefaultSearchScope = "SCcf";
    };

    controlcenter.Sound = true;

    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      "com.apple.mouse.tapBehavior" = 1;
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
      AppleInterfaceStyle = "Dark";
    };
  };
}
