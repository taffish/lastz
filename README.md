# lastz

`lastz` packages the complete LASTZ 1.04.60 command-line release for TAFFISH.

## Package Identity

- command: `taf-lastz`
- kind: `tool`
- version: `1.04.60-r1`
- image: `ghcr.io/taffish/lastz:1.04.60-r1`
- native platforms: `linux/amd64`, `linux/arm64`
- TAFFISH app license: Apache-2.0
- upstream release: <https://github.com/lastz/lastz/releases/tag/1.04.60>

This upstream update fixes the `--masking` / `--segments` crash and carries
upstream compiler/build-system improvements. The packaging does not patch
LASTZ's C alignment algorithms or alter its default parameters.

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

LASTZ itself is a finite CLI application. Its official manual recommends
[GMAJ](https://globin.bx.psu.edu/dist/gmaj/), a separate Java MAF viewer.
The official GMAJ archive, JAR and documentation were inspected, but an
explicit redistribution grant was not found; its binary contains an
all-rights-reserved notice. GMAJ is therefore not bundled pending license
clarification. LASTZ's MIT license is not assumed to cover that separate
program. Export standard MAF and open it in a separately licensed/installed
viewer. No GUI runtime is claimed or tested in this package.

This package starts no browser service, daemon, listener or GPU/device
session. KegAlign and SegAlign are separate GPU aligner implementations, not
entry points in the packaged LASTZ source release.

## Installation

Install the latest published release:

```sh
taf update
taf install lastz
```

After this candidate is published, select its immutable identity explicitly:

```sh
taf install lastz 1.04.60-r1
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

TAFFISH 0.11 command mode reconstructs a shell command. For a path containing
spaces, preserve literal quotes inside the argument, for example:

```sh
taf-lastz lastz "'reference with spaces.fa'" query.fa \
  "'--output=result with spaces.maf'" --format=maf
```

This syntax was tested through the real wrapper. Merely passing a
normally shell-quoted path loses its boundary in this command mode.

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
writes under `/opt`, `/usr`, or image-internal `/var/lib`. The smoke sends
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

References may live in a personal directory such as
`$HOME/.local/share/taffish/lastz/references/<assembly-version>`, or a site
directory such as `/opt/taffish/lastz/references/<assembly-version>`.
An administrator prepares the chosen, legally shareable reference once,
records its source/version/checksums and keeps the directory traversable and
files readable by intended users (typically directories 0755 and files 0644).
Do not grant ordinary users write access to the published reference.
Build any HSX index beside the reference during preparation; its embedded
paths must remain valid at the mounted location. Publish a new directory for
reference changes instead of overwriting a shared reference in place.

For example, bind the same prepared root to a stable read-only container
path, and keep `query.fa` and output in the current directory:

```sh
TAFFISH_CONTAINER_BACKEND=docker \
  TAFFISH_DOCKER_RUN_ARGS="-v /opt/taffish/lastz/references/demo-v1:/refs:ro" \
  taf-lastz lastz /refs/reference.fa query.fa --format=maf > alignments.maf
TAFFISH_CONTAINER_BACKEND=podman \
  TAFFISH_PODMAN_RUN_ARGS="-v /opt/taffish/lastz/references/demo-v1:/refs:ro" \
  taf-lastz lastz /refs/reference.fa query.fa --format=maf > alignments.maf
TAFFISH_CONTAINER_BACKEND=apptainer \
  TAFFISH_APPTAINER_RUN_ARGS="--bind /opt/taffish/lastz/references/demo-v1:/refs:ro" \
  taf-lastz lastz /refs/reference.fa query.fa --format=maf > alignments.maf
```

Replace the host root with your personal/site reference path. There is no
automatic resource discovery, silent download or resource environment
override: use explicit input paths and backend binds. Omit the optional bind
when using files in the current directory. Missing resources fail rather
than downloading. These are sharing mechanics, not validation of a specific
production assembly or its license.

## Retained Python 3 Compatibility Repairs

The historical 1.04.52-r1 smoke compilation attempted to create `__pycache__` under
`/opt/lastz/share/lastz` and failed on a read-only Apptainer SIF. r1 also
contained build-time bytecode in that tree. r2 validates all 23 Python sources
through a disposable cache and ships no image-root `__pycache__`.

The Debian 12 runtime uses Python 3.11. The retained strict package patch updates two legacy
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
- Upstream `lastz --version` and `lastz --help` intentionally exit 1, even
  when they print valid information. For scripting, upstream also provides
  `--version:noerror`. Other non-zero helper/aligner exits are failures;
  inspect stderr and user-selected output before changing parameters.

## Testing and Release Boundary

Metadata smoke verifies the four binaries, the full helper surface, all 23
Python sources, read-only-safe bytecode compilation, all principal alignment
formats, LAV/MAF sorting, HSX build/read, FASTA/gzip/2bit tabular conversion,
score expansion, interval merging, and qdna/FASTA utilities. Maintainer checks
add canonical builds for both declared platforms, offline direct-container and
wrapper layers, read-only/non-root execution, Apptainer SIF immutability,
failure-log replay, image content/size, publish dry-run, and strict target
cleanup.

Build-time checks stay at version/help, dependency/source inventory, Python
compilation and upstream tiny tests. Full helper and masking regression
checks run after image construction. No rendering or GUI check is a build
requirement. The Action is already byte-identical to fresh `taf new` and is
left unchanged.

These are packaging and tiny functional checks, not scientific validation for
production genome-alignment parameters. See release.md for actual evidence
and any untested platform/backend combinations.

## License and Citation

TAFFISH packaging is Apache-2.0. Upstream LASTZ is MIT-licensed. The upstream
reference is:

Harris RS (2007). *Improved pairwise alignment of genomic DNA*. Ph.D. thesis,
Pennsylvania State University.
