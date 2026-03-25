{ lib
, stdenv
, fetchFromGitHub
, bun
, nodejs
}:

stdenv.mkDerivation rec {
  pname = "hydra-server";
  version = "unstable-2025-02-13";
  
  src = fetchFromGitHub {
    owner = "dmilin1";
    repo = "hydra-server";
    rev = "main";
    hash = "sha256-dPUQ2H+I/kvhqjqZr16siJTE6DKeEZ1aindrotEohG8=";
  };

  nativeBuildInputs = [ bun nodejs ];

  #Allow network access to fetch npm packages during build
  # This is impure but necessary for Bun/npm packages without vendoring
  __noChroot = true;

  buildPhase = ''
    runHook preBuild
    
    export HOME=$TMPDIR
    
    # Install backend dependencies
    bun install --frozen-lockfile

    # Patch index.ts to use PORT environment variable
    sed -i 's/port: 3000,/port: parseInt(process.env.PORT || "3000"),/' index.ts

    # Build frontend
    cd frontend
    bun install --frozen-lockfile
    bun run build
    cd ..

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{bin,lib/hydra-server}

    # Copy all necessary files
    cp -r . $out/lib/hydra-server/
    
    # Remove frontend source (already built to dist/)
    rm -rf $out/lib/hydra-server/frontend

    # Create wrapper script
    cat > $out/bin/hydra-server <<EOF
    #!${stdenv.shell}
    cd $out/lib/hydra-server
    exec ${bun}/bin/bun run index.ts "\$@"
    EOF
    chmod +x $out/bin/hydra-server

    runHook postInstall
  '';

  meta = with lib; {
    description = "Backend service for the Hydra for Reddit app";
    homepage = "https://github.com/dmilin1/hydra-server";
    license = licenses.unfree; # Update if known
    maintainers = [ ];
    platforms = platforms.linux;
  };
}
