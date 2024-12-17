{pkgs, ...}:

{

  kernel.python.minimal = {
    enable = true;
  };

  kernel.haskell.minimal = {
    enable = true;
    nixpkgs = pkgs;
  # haskellCompiler = "ghc902";
    extraHaskellPackages = p: with p; [

    # bytestring
      cassava
      Chart
    # containers
      criterion
    # deepseq
      exact-combinatorics
      hspec
      hspec-discover
      hvega
      optparse-applicative
      QuickCheck
      statistics
      vector

      deltaq
      probability-polynomial

    ];
  };

}
