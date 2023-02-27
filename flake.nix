{
    inputs = {
	nixpkgs.url = "github:NixOS/nixpkgs";
	flake-utils.url = "github:numtide/flake-utils";

	pjass.url = "github:lep/pjass";
	#pjass.url = "git+file:/Users/lep/dev/pjass";
	pjass.inputs.nixpkgs.follows = "nixpkgs";
	pjass.inputs.flake-utils.follows = "flake-utils";

	jhcr.url = "github:lep/jhcr";
	#jhcr.url = "git+file:/Users/lep/dev/jass-hot-code-reload";
	jhcr.inputs.nixpkgs.follows = "nixpkgs";
	jhcr.inputs.flake-utils.follows = "flake-utils";
	jhcr.inputs.common-j.follows = "common-j";

	common-j.url = "github:lep/common-j";
	common-j.inputs.nixpkgs.follows = "nixpkgs";
	common-j.inputs.flake-utils.follows = "flake-utils";

	mpq.url = "git+file:/Users/lep/dev/mpq";
	mpq.inputs.nixpkgs.follows = "nixpkgs";
	mpq.inputs.flake-utils.follows = "flake-utils";

	compressmpq.url = "github:lep/compressmpq";
	compressmpq.inputs.nixpkgs.follows = "nixpkgs";
	compressmpq.inputs.flake-utils.follows = "flake-utils";
    };

    outputs = { self, nixpkgs, flake-utils, pjass, jhcr, common-j, mpq, compressmpq }:
	flake-utils.lib.eachDefaultSystem (system:
            let pkgs = import nixpkgs { inherit system; };
		pjass-drv = pjass.defaultPackage.${system};
		jhcr-drv = jhcr.defaultPackage.${system};
		mpq-drv = mpq.defaultPackage.${system};
		compressmpq-drv = compressmpq.defaultPackage.${system};

		wc3 = pkgs.writeShellScriptBin "wc3" ''
		    /Applications/Warcraft\ III/_retail_/x86_64/Warcraft\ III.app/Contents/MacOS/Warcraft\ III -launch -nowfpause -windowmode windowed -width 1024 -height 768 -loadfile "$1"
		'';


		jhcr-start = pkgs.writeShellScriptBin "jhcr-start" ''
		    set -e
		    pjass ${common-j}/common.j blizzard.j "$1"
		    ${jhcr-drv}/bin/jhcr init ${common-j}/common.j blizzard.j "$1"
		    ${pjass-drv}/bin/pjass ${common-j}/common.j blizzard.j jhcr_war3map.j
		    ${mpq-drv}/bin/mpq add base.w3x jhcr_war3map.j --name war3map.j
		    ${wc3}/bin/wc3 "$(realpath base.w3x)" &
		'';

		jhcr-update = pkgs.writeShellScriptBin "jhcr-update" ''
		    set -e
		    pjass ${common-j}/common.j blizzard.j "$1"
		    ${jhcr-drv}/bin/jhcr update "$1" --preload-path ~/Library/Application\ Support/Blizzard/Warcraft\ III/CustomMapData/
		'';
            in {
		packages = {
		    inherit jhcr-update jhcr-start wc3;
		    inherit pjass compressmpq mpq;
		};

		devShell = pkgs.mkShell {
		    env = {
			commonj = "${common-j}/common.j";
		    };
		    buildInputs = [
			pkgs.lua5_3_compat
			pjass-drv
			jhcr-drv
			mpq-drv
			compressmpq-drv
			wc3
			jhcr-start
			jhcr-update
		    ];
		};
            }
	);
}
