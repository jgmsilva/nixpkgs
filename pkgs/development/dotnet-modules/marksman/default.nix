{ git, buildDotnetModule, fetchFromGitHub, dotnetCorePackages, lib, glibcLocales }:
buildDotnetModule rec {
  pname = "marksman";
  version = "2022-09-03";
  
  src = fetchFromGitHub{
    owner = "artempyanykh";
    repo = pname;
    rev = version;
    sha256 = "sha256-2PkWjRPwHH0fkmvQYt9jiMwFT5lIxEAPI9fqP4GUHYw=";
    deepClone = true;
  };
  
  projectFile = "Marksman/Marksman.fsproj";
  nugetDeps = ./deps.nix;
  buildInputs = [ git glibcLocales];
  executables = [ "marksman" ];

    
  dotnet-sdk = dotnetCorePackages.sdk_6_0;

  meta = with lib; {
    description = "A program that integrates with your editor to assist you in writing and maintaining your Markdown documents. Using LSP protocol it provides completion, goto definition, find references, rename refactoring, diagnostics, and more";
    homepage = "https://github.com/artempyanykh/marksman";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    maintainers = with maintainers; [ jgmsilva ];
  };
}

