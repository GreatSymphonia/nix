{
  pandoc,
  makeWrapper,
  symlinkJoin,
}:

# pdflatex ne gère pas les caractères Unicode (ex. ≈). On force xelatex.
symlinkJoin {
  name = "pandoc-xelatex";
  paths = [ pandoc ];

  nativeBuildInputs = [ makeWrapper ];

  postBuild = ''
    wrapProgram $out/bin/pandoc --add-flags "--pdf-engine=xelatex"
  '';
}
