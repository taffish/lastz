lastz 1.04.52-r1

Purpose:
  LASTZ is a BLASTZ-compatible pairwise DNA sequence aligner. This TAFFISH
  app packages upstream LASTZ 1.04.52 with the standard, floating-score, and
  large-target special builds.

Usage:
  taf-lastz -- --help
  taf-lastz -- --version
  taf-lastz lastz target.fa query.fa --format=maf > target_vs_query.maf
  taf-lastz lastz_D target.fa query.fa C=2 W=8 T=0 > float.lav
  taf-lastz lastz_32 target.fa query.fa --format=sam > alignments.sam
  taf-lastz lav_sort.py --key=beg1 < input.lav > sorted.lav

Common workflows:
  taf-lastz lastz target.fa query.fa > alignments.lav
  taf-lastz lastz target.fa query.fa --format=axt > alignments.axt
  taf-lastz lastz target.fa query.fa --format=maf > alignments.maf
  taf-lastz lastz target.fa query.fa --format=paf > alignments.paf
  taf-lastz lastz target.fa query.fa --format=general:name1,zstart1,end1,name2,zstart2+,end2+ > alignments.tsv

Packaged commands:
  lastz       default command, standard integer-scoring LASTZ
  lastz_D     floating-point scoring build
  lastz_32    special build for larger target indexing, up to about 4.3 Gbp
  lastz_40    experimental special build for very large target indexing

Auxiliary scripts:
  Upstream Python3 helpers from tools/ and tabular_tools/ are available on PATH
  by script name, for example lav_sort.py, maf_sort.py, build_fasta_hsx.py,
  expand_scores_file.py, and tabular_to_maf.py.

Upstream help and version:
  taf-lastz -- --help
  taf-lastz -- --help=short
  taf-lastz -- --version
  taf-lastz lastz_D --version

Inputs:
  target     target DNA sequence or collection; commonly FASTA
  query      query DNA sequence or collection; optional for modes such as --self
  extras     optional scoring files, masks, anchors, subranges, and sequence
             specifier actions supported by upstream LASTZ

Key outputs:
  LAV        default LASTZ/BLASTZ-style alignment output
  AXT/MAF    common comparative-genomics alignment formats
  SAM/PAF    mapper-style alignment formats
  CIGAR      compact edit-string output
  general    custom tabular output fields from --format=general:<fields>

Platform and resources:
  Native container builds are requested for linux/amd64 and linux/arm64.
  No external database, reference bundle, GPU, service port, or network access
  is required at run time. Memory use depends on target size and alignment
  settings.

Boundaries:
  This app does not download genomes, choose biological thresholds, run GPU
  acceleration, or perform whole-genome post-processing workflows.
  Use lastz_32 or lastz_40 only when the standard build cannot address the
  target coordinate range; upstream describes lastz_40 as experimental.

Detailed documentation:
  https://lastz.github.io/lastz/
  /opt/lastz/share/doc/lastz/README.lastz.html inside the container

Wrapper options:
  taf-lastz --help       Show this TAFFISH help.
  taf-lastz --version    Show TAFFISH wrapper version.
  taf-lastz --compile    Compile the TAFFISH wrapper.
  taf-lastz -- --help    Pass option-leading arguments to the default command.

Notes:
  Command mode is enabled. Use taf-lastz lastz_D ... or taf-lastz lav_sort.py ...
  for explicit packaged commands. For normal alignments, prefer
  taf-lastz lastz target.fa query.fa ... so input paths are not confused with
  command names. Use taf-lastz -- --help or taf-lastz -- --version for upstream
  option-leading help/version calls.
