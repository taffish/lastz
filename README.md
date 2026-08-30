# lastz

`lastz` packages the complete LASTZ 1.04.52 command-line release for TAFFISH.

## Package Identity

- command: `taf-lastz`
- kind: `tool`
- version: `1.04.52-r2`
- image: `ghcr.io/taffish/lastz:1.04.52-r2`
- native platforms: `linux/amd64`, `linux/arm64`
- TAFFISH app license: Apache-2.0
- upstream release: <https://github.com/lastz/lastz/releases/tag/1.04.52>

This is a same-upstream successor. It does not change LASTZ's scientific
version, defaults, output formats, or public command surface.

## Scope

The image contains the four upstream binaries:

- `lastz`: standard integer-scoring build
- `lastz_D`: floating-point scoring build
- `lastz_32`: special build for targets up to about 4.3 Gbp
- `lastz_40`: experimental special build for very large target indexing

It also retains all 22 executable upstream scripts from `tools/` and
`tabular_tools/`, plus their support modules. Important helpers include:

- `lav_sort.py`, `maf_sort.py`, `axt_compare.py`, `gfa_compare.py`, and
  `lav_compare.py`
- `build_fasta_hsx.py`, `pick_from_fasta_hsx.py`, and the HSX support modules
- `tabular_to_maf.py` and the general-tabular support modules
- FASTA fragmentation/masking, masking-interval, qdna, score, and quantum-code
  utilities

LASTZ is a finite CLI application. It starts no GUI, browser service, daemon,
listener, GPU/device session, or long-running helper. Upstream mentions
KegAlign and SegAlign as separate GPU projects; they are not optional entry
points of this app.

## Installation

Install the latest published release:

```sh
taf update
taf install lastz
```

After r2 is published, select its immutable identity explicitly with:

```sh
taf install lastz 1.04.52-r2
```

## Main Commands

Use an explicit packaged command for normal work:

```sh
taf-lastz lastz target.fa query.fa --format=maf > target-vs-query.maf
taf-lastz lastz_D target.fa query.fa C=2 W=8 T=0 > floating.lav
taf-lastz lastz_32 target.fa query.fa --format=sam- > alignments.sam
taf-lastz lastz_40 target.fa query.fa --format=paf > alignments.paf
```

The wrapper also has a default-command path:

```sh
taf-lastz -- --version
taf-lastz -- --help
```

TAFFISH command mode treats a non-option first argument as a possible command.
Because a normal LASTZ first argument is often an input path, documentation
uses `taf-lastz lastz ...` to avoid ambiguity. Use
`taf-lastz upstream-command subcommand ...` for any upstream CLI that has its
own subcommands; `--` is mainly for option-leading arguments to default
`lastz`.

## Helper Examples

```sh
taf-lastz lav_sort.py --key=beg1 < input.lav > sorted.lav
taf-lastz maf_sort.py --key=score < input.maf > sorted.maf
taf-lastz build_fasta_hsx.py reference.fa > reference.hsx
taf-lastz pick_from_fasta_hsx.py reference.hsx chr1 > chr1.fa
taf-lastz tabular_to_maf.py --sequences=reference.fa \
  < alignments.tsv > alignments.maf
```

The helpers are already executable on the container `PATH`; users do not need
`install_py.py` for ordinary wrapper use.

## Inputs and Outputs

Common inputs are project-selected FASTA/FASTQ, nib, 2bit, HSX, qdna,
score/code files, masks, anchors, and sequence-specifier control files. They
are not an app database or model bundle.

LASTZ writes its primary result to stdout unless an upstream option selects a
file. Supported formats include LAV, AXT, MAF, SAM, PAF, GFA, CIGAR, BLASTN,
text, rdotplot, and custom `general:<fields>` tables. Helpers likewise write to
stdout or to an explicit user-selected path such as `--writecode=<file>`.

Normal execution writes only to stdout, the writable current/output directory,
explicit user-selected paths, and backend temporary space. It does not require
writes under `/opt`, `/usr`, or image-internal `/var/lib`. The r2 smoke sends
explicit Python bytecode checks to a unique disposable `/tmp` cache and leaves
the packaged helper tree unchanged.

## Backend and Mount Matrix

Both declared image platforms are native builds; neither is described as the
other architecture under emulation.

| Capability | Docker | Podman | Apptainer |
| --- | --- | --- | --- |
| Run on a matching amd64/arm64 host | `TAFFISH_CONTAINER_BACKEND=docker taf-lastz lastz ...` | `TAFFISH_CONTAINER_BACKEND=podman taf-lastz lastz ...` | `TAFFISH_CONTAINER_BACKEND=apptainer taf-lastz lastz ...` |
| Current-directory input/output | Wrapper bind | Wrapper bind | Wrapper bind |
| External read-only reference | `TAFFISH_DOCKER_RUN_ARGS="-v /data/genomes:/data/genomes:ro"` | `TAFFISH_PODMAN_RUN_ARGS="-v /data/genomes:/data/genomes:ro"` | `TAFFISH_APPTAINER_RUN_ARGS="--bind /data/genomes:/data/genomes:ro"` |

Keep output under the current directory when possible. If an output must live
outside it, add a separate writable bind. Paths embedded in HSX files or other
control files must match the paths visible inside the container.

## Resources and Offline Operation

This app has no downloadable database, model, taxonomy, persistent cache, or
resource catalog. References and scoring resources are scientific inputs
chosen by the user, so there is no justified personal/system-wide download
helper. Large reusable references can be mounted read-only with the backend
commands above.

The packaged commands and helpers are offline-capable. Documentation URLs are
references only; smoke and normal computation do not require network access.

## r2 Compatibility Repair

r1's explicit smoke compilation attempted to create `__pycache__` under
`/opt/lastz/share/lastz` and failed on a read-only Apptainer SIF. r1 also
contained build-time bytecode in that tree. r2 validates all 23 Python sources
through a disposable cache and ships no image-root `__pycache__`.

The Debian 12 runtime uses Python 3.11. r2 strictly updates two legacy
`MutableMapping` imports, restores the documented plain/gzip FASTA and 2bit
paths in `tabular_to_maf.py`, and converts six invalid Python 3 string
exceptions in `expand_scores_file.py` to `ValueError` without changing valid
score-file output. It also repairs Python 3 binary I/O in the HSX writer/reader
and both qdna output modes. Normal helper imports suppress bytecode writes;
the explicit compilation smoke still proves all 23 sources through its unique
temporary cache.

## Troubleshooting

- If an input path is interpreted as a command, use the explicit
  `taf-lastz lastz target query ...` form.
- If a command begins with an option, use `taf-lastz -- --help` or another
  appropriate default-command invocation.
- If a file outside the current directory is missing, add the matching
  backend-specific read-only bind and keep embedded paths container-visible.
- Use `lastz_32` or `lastz_40` only for the documented coordinate-range need;
  upstream describes `lastz_40` as experimental.
- A non-zero helper or aligner exit is authoritative. Inspect its stderr and
  user-selected output before changing biological parameters.

## Testing and Release Boundary

Metadata smoke verifies the four binaries, the full helper surface, all 23
Python sources, read-only-safe bytecode compilation, all principal alignment
formats, LAV/MAF sorting, HSX build/read, FASTA/gzip/2bit tabular conversion,
score expansion, interval merging, and qdna/FASTA utilities. Maintainer checks
add canonical builds for both declared platforms, offline direct-container and
wrapper layers, read-only/non-root execution, Apptainer SIF immutability,
failure-log replay, image content/size, publish dry-run, and strict target
cleanup.

These are packaging and tiny functional checks, not scientific validation for
production genome-alignment parameters.

## License and Citation

TAFFISH packaging is Apache-2.0. Upstream LASTZ is MIT-licensed. The upstream
reference is:

Harris RS (2007). *Improved pairwise alignment of genomic DNA*. Ph.D. thesis,
Pennsylvania State University.
