lastz 1.04.52-r2

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
  All upstream executable helpers are already on PATH; install_py.py is not
  needed for ordinary wrapper use.

Inputs and outputs:
  target/query  FASTA/FASTQ, nib, 2bit, HSX, qdna, or another supported
                sequence specifier
  extras        optional score/code files, masks, anchors, subranges, and
                upstream control files
  output        stdout by default; choose LAV, AXT, MAF, SAM, PAF, GFA,
                CIGAR, BLASTN, text, rdotplot, or general:<fields>
  Keep redirected output under a writable current/output directory.

Backend use:
  Docker:
    TAFFISH_CONTAINER_BACKEND=docker taf-lastz lastz target.fa query.fa ...
  Podman:
    TAFFISH_CONTAINER_BACKEND=podman taf-lastz lastz target.fa query.fa ...
  Apptainer:
    TAFFISH_CONTAINER_BACKEND=apptainer taf-lastz lastz target.fa query.fa ...
  Native linux/amd64 and linux/arm64 images are declared. Use an image matching
  the host architecture; do not describe one architecture as native on the
  other.

Inputs outside the current directory:
  Docker:
    TAFFISH_DOCKER_RUN_ARGS="-v /data/genomes:/data/genomes:ro" taf-lastz ...
  Podman:
    TAFFISH_PODMAN_RUN_ARGS="-v /data/genomes:/data/genomes:ro" taf-lastz ...
  Apptainer:
    TAFFISH_APPTAINER_RUN_ARGS="--bind /data/genomes:/data/genomes:ro" \
      taf-lastz ...
  Add a separate writable bind for external outputs. Paths stored inside HSX
  or control files must match container-visible paths.

Immediate notes:
  This app has no database, model, taxonomy, persistent cache, downloader,
  GUI, service, GPU, device, or runtime network requirement. References and
  score files are project inputs; mount large reusable resources read-only.
  Normal commands write only stdout, explicit output paths, the current
  directory, or temporary backend space. They do not need a writable image.
  r2 supports read-only SIF execution and the helper FASTA, gzip FASTA, and
  2bit conversion paths on the packaged Python runtime.

Troubleshooting:
  Use taf-lastz lastz ... for normal alignments so the first input path is not
  mistaken for a command name. Use taf-lastz -- --help for option-leading
  default-command arguments. A non-zero aligner/helper exit is authoritative;
  inspect stderr and output before changing biological parameters.

More help:
  https://lastz.github.io/lastz/
  /opt/lastz/share/doc/lastz/README.lastz.html inside the container

Wrapper controls:
  taf-lastz --help       show this installed task guide
  taf-lastz --version    show the immutable wrapper identity
  taf-lastz --compile    print the backend command without running it
  taf-lastz -- --help    pass --help to default lastz
