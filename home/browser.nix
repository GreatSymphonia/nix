{ ... }:

let
  browser = "zen.desktop";   # <- remplace par le nom trouvé ci-dessus
in
{
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html"                 = browser;
      "application/xhtml+xml"     = browser;
      "x-scheme-handler/http"     = browser;
      "x-scheme-handler/https"    = browser;
      "x-scheme-handler/about"    = browser;
      "x-scheme-handler/unknown"  = browser;
    };
  };
}
