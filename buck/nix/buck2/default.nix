{ lib
, fetchFromGitHub
, rust-bin
, makeRustPlatform
, protobuf
, pkg-config
, openssl
, sqlite
}:

let
  rustChannel = "nightly";
  rustVersion = "2023-03-07";

  my-rust-bin = rust-bin."${rustChannel}"."${rustVersion}".default.override {
    extensions = [ "rust-analyzer" ];
  };

  rustPlatform = makeRustPlatform {
    rustc = my-rust-bin;
    cargo = my-rust-bin;
  };

in rustPlatform.buildRustPackage rec {
  pname = "buck2";
  version = "unstable-2023-05-02";

  src = fetchFromGitHub {
    owner = "facebook";
    repo = "buck2";
    rev = "a46bbe756142808889981c2dc2ac80082759c758";
    hash = "sha256-ycugIJk/NtifSPEtcQTlzOFgxQEkcAWUPoaUjos3Ias=";
  };

  cargoLock = {
    lockFile = ./Cargo.lock;
    outputHashes = {
      "perf-event-0.4.8" = "sha256-4OSGmbrL5y1g+wdA+W9DrhWlHQGeVCsMLz87pJNckvw=";
      "tonic-0.8.3" = "sha256-xuQVixIxTDS4IZIN46aMAer3v4/81IQEG975vuNNerU=";
    };
  };

  BUCK2_BUILD_PROTOC = "${protobuf}/bin/protoc";
  BUCK2_BUILD_PROTOC_INCLUDE = "${protobuf}/include";

  nativeBuildInputs = [ protobuf pkg-config ];
  buildInputs = [ openssl sqlite ];

  doCheck = false;
  dontStrip = true; # XXX (aseipp): cargo will delete dwarf info but leave symbols for backtraces

  patches = [ /* None, for now */ ];

  # Put in the Cargo.lock file.
  #
  # XXX NOTE (aseipp): Also, for now, suppress a really annoying 'tracing'
  # warning that makes the default build output uglier; once we self-bootstrap
  # buck2 with buck2 under Nix (ugh...) then we can get rid of this.
  postPatch = "cp ${./Cargo.lock} Cargo.lock";

  postInstall = ''
    mv $out/bin/buck2     $out/bin/buck
    ln -sfv $out/bin/buck $out/bin/buck2
    mv $out/bin/starlark  $out/bin/buck2-starlark
    mv $out/bin/read_dump $out/bin/buck2-read_dump
  '';
}
