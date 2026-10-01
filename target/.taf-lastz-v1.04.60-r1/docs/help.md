lastz 1.04.60-r1

Usage:
  taf-lastz lastz target.fa query.fa --format=maf > alignments.maf
  taf-lastz lastz_D target.fa query.fa C=2 W=8 T=0 > floating.lav
  taf-lastz lastz_32 target.fa query.fa --format=sam- > alignments.sam
  taf-lastz lastz_40 target.fa query.fa --format=paf > alignments.paf
  taf-lastz -- --help
  taf-lastz -- --version

Command roles:
  lastz       standard integer-scoring aligner
  lastz_D     floating-point scoring build
  lastz_32    special build for targets up to about 4.3 Gbp
  lastz_40    experimental very-large-target build

Useful helpers:
  taf-lastz lav_sort.py --key=beg1 < input.lav > sorted.lav
  taf-lastz maf_sort.py --key=score < input.maf > sorted.maf
  taf-lastz build_fasta_hsx.py reference.fa > reference.hsx
  taf-lastz pick_from_fasta_hsx.py reference.hsx chr1 > chr1.fa
  taf-lastz tabular_to_maf.py --sequences=reference.fa \
    < alignments.tsv > alignments.maf
  All 22 upstream executable helpers are already on PATH.

Inputs and outputs:
  target/query  FASTA/FASTQ, nib, 2bit, HSX, qdna or other sequence specifiers
  extras        optional scores, masks, anchors and upstream control files
  output        stdout by default; LAV, AXT, MAF, SAM, PAF, GFA, CIGAR,
                BLASTN, text, rdotplot or general:<fields>
  Keep output in a writable current directory or explicit writable bind.
  Normal computation is offline; no database/model download is required.

Backend selection:
  TAFFISH_CONTAINER_BACKEND=docker taf-lastz lastz target.fa query.fa --format=maf
  TAFFISH_CONTAINER_BACKEND=podman taf-lastz lastz target.fa query.fa --format=maf
  TAFFISH_CONTAINER_BACKEND=apptainer taf-lastz lastz target.fa query.fa --format=maf
  Images support native linux/amd64 and linux/arm64. Apptainer needs Linux;
  on macOS use Docker/Podman or run the wrapper on a Linux server.

Shared references:
  Ask your administrator for a prepared reference, or prepare your own.
  Example: /opt/taffish/lastz/references/demo-v1/reference.fa on the host.
  Keep query.fa in the current directory; replace the example host root.
  Docker:
    TAFFISH_CONTAINER_BACKEND=docker \
      TAFFISH_DOCKER_RUN_ARGS="-v /opt/taffish/lastz/references/demo-v1:/refs:ro" \
      taf-lastz lastz /refs/reference.fa query.fa --format=maf > alignments.maf
  Podman:
    TAFFISH_CONTAINER_BACKEND=podman \
      TAFFISH_PODMAN_RUN_ARGS="-v /opt/taffish/lastz/references/demo-v1:/refs:ro" \
      taf-lastz lastz /refs/reference.fa query.fa --format=maf > alignments.maf
  Apptainer:
    TAFFISH_CONTAINER_BACKEND=apptainer \
      TAFFISH_APPTAINER_RUN_ARGS="--bind /opt/taffish/lastz/references/demo-v1:/refs:ro" \
      taf-lastz lastz /refs/reference.fa query.fa --format=maf > alignments.maf
  The same binds work for a personal prepared root. No automatic discovery.
  Omit the bind for current-directory inputs. HSX embedded paths must remain
  valid inside the container. See README for preparation and permissions.

Troubleshooting:
  Use taf-lastz lastz ... so an input path is not mistaken for a command.
  Use taf-lastz -- --help for default-command option-leading arguments.
  For spaces, preserve literal quotes in TAFFISH 0.11 command mode, e.g.
    taf-lastz lastz "'target with spaces.fa'" query.fa --format=maf
  Upstream --version/--help intentionally exit 1 after printing information.
  Other nonzero exits are failures; inspect stderr before changing parameters.
  This package has no GUI. Export MAF for a separately installed viewer;
  the recommended GMAJ is not bundled pending redistribution clarification.

More help:
  https://lastz.github.io/lastz/
  /opt/lastz/share/doc/lastz/README.lastz.html inside the container

Wrapper controls:
  taf-lastz --help       show this task guide
  taf-lastz --version    show wrapper identity
  taf-lastz --compile    print the backend command without running it
  taf-lastz -- --help    pass --help to default lastz
