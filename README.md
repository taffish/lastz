# lastz

`lastz` packages LASTZ for TAFFISH.

Package identity:

- name: `lastz`
- command: `taf-lastz`
- kind: `tool`
- version: `1.04.52-r1`
- license: Apache-2.0
- upstream: https://github.com/lastz/lastz

## What This App Packages

LASTZ is a pairwise DNA sequence aligner and BLASTZ-compatible command-line
tool. This app builds the tagged upstream LASTZ 1.04.52 release from source and
provides the standard integer-scoring `lastz`, floating-point `lastz_D`, and
the official `lastz_32` and `lastz_40` special builds.

The image also retains upstream Python3 helper scripts from `tools/` and
`tabular_tools/` under `/opt/lastz/share/lastz/` and places executable helper
scripts on `PATH`.

## Scope

This app supports:

- pairwise DNA alignment with LASTZ/BLASTZ-style command-line syntax
- scoring inference and integer or floating-point scoring modes
- LAV, AXT, MAF, SAM, CIGAR, GFA, BLASTN, PAF, rdotplot, text, and general
  tabular output modes supported by upstream LASTZ
- FASTA/FASTQ and upstream-supported sequence specifiers, including nib, 2bit,
  HSX, qdna, masks, anchors, subranges, and related advanced inputs
- upstream Python3 helper scripts for sorting/comparing alignment outputs,
  score-file utilities, HSX helpers, and tabular-output conversion

This app does not:

- download genomes, references, alignments, or scoring databases
- provide GPU acceleration; upstream points to separate KegAlign and SegAlign
  projects for GPU-accelerated alternatives
- choose biological alignment thresholds or perform multi-tool comparative
  genomics workflows by itself

## Container Contents

- `lastz`: default upstream command, standard integer-scoring LASTZ
- `lastz_D`: floating-point scoring build
- `lastz_32`: special build for larger target indexing, up to about 4.3 Gbp
- `lastz_40`: experimental special build for very large target indexing, up to
  about 1.1 Tbp for narrow use cases
- `tools/*.py` and `tools/*.sh`: upstream auxiliary Python3/shell scripts
- `tabular_tools/*.py`: upstream scripts for LASTZ general tabular output
- `/opt/lastz/share/doc/lastz/`: upstream README and HTML manual
- `/opt/lastz/share/testdata/`: small upstream test data used by smoke tests

## Usage

Default upstream command:

```sh
taf-lastz lastz target.fa query.fa --format=maf > target_vs_query.maf
```

Access upstream help:

```sh
taf-lastz -- --help
taf-lastz -- --version
```

Run an explicit packaged command:

```sh
taf-lastz lastz_D target.fa query.fa C=2 W=8 T=0 > float.lav
taf-lastz lastz_32 target.fa query.fa --format=sam > alignments.sam
taf-lastz lav_sort.py --key=beg1 < input.lav > sorted.lav
```

## Command Mode

TAFFISH command mode is enabled. Use the explicit `taf-lastz lastz ...` form
for normal LASTZ alignments; this avoids ambiguity because LASTZ's first
scientific argument is often an input path, while command mode treats a
non-option first argument as a possible executable name.

If the first argument is a packaged executable name, it is run inside the same
LASTZ container environment:

```sh
taf-lastz lastz target.fa query.fa --format=maf > target_vs_query.maf
taf-lastz lastz_D target.fa query.fa C=2 W=8 T=0
taf-lastz lastz_40 target.fa query.fa --format=paf > alignments.paf
taf-lastz maf_sort.py --key=pos1 < input.maf > sorted.maf
```

Use `taf-lastz -- --help` or `taf-lastz -- --version` for upstream
option-leading help/version calls to the default `lastz` command.

## Inputs

| Input | Meaning | Notes |
| --- | --- | --- |
| `target` | target DNA sequence or sequence collection | commonly FASTA; upstream also supports FASTQ, nib, 2bit, HSX, qdna, and sequence specifier actions |
| `query` | query DNA sequence or collection | optional for some modes such as `--self`; may be stdin where upstream supports it |
| scoring/control files | optional LASTZ scoring or inference inputs | passed directly to upstream options |
| masks/anchors/subsets | optional interval and alignment-control inputs | use upstream sequence specifier syntax and options |

## Output Notes

LASTZ writes its primary output to stdout unless an upstream option requests a
file. The default output is LAV. Common alternatives include `--format=axt`,
`--format=maf`, `--format=sam`, `--format=cigar`, `--format=blastn`,
`--format=paf`, `--format=rdotplot`, `--format=text`, and
`--format=general:<fields>`.

## Resources, Databases, and Platform

No external database, reference bundle, GPU device, service port, or network
access is required at run time. Native container builds are requested for
`linux/amd64` and `linux/arm64`.

LASTZ memory use depends on target size, seed/indexing settings, and selected
build. Use `lastz_32` or `lastz_40` only when the standard build cannot address
the target coordinate range; `lastz_40` is described upstream as experimental.

## Boundaries

This is a command-line runtime for the upstream LASTZ release. It is not a
workflow for whole-genome alignment post-processing, synteny visualization,
tree construction, or annotation transfer. Users remain responsible for
choosing scoring matrices, thresholds, masking strategy, and output format for
their scientific context.

## Troubleshooting

- In scripts, prefer `taf-lastz lastz target.fa query.fa ...` for normal
  alignments. This is clearer than relying on the implicit default command when
  the first LASTZ argument is an input path.
- If a default-command call starts with an option, use `taf-lastz -- --help` or
  `taf-lastz -- --version`.
- If a helper script is needed, call it by its script name, for example
  `taf-lastz lav_sort.py --key=beg1 < input.lav > sorted.lav`.
- If a large target fails because of coordinate/index limits, retry with
  `taf-lastz lastz_32 ...` or, for the narrow very-large-target use case,
  `taf-lastz lastz_40 ...`.

## Testing

The smoke test covers:

- wrapper metadata and help
- exact upstream runtime version
- presence of the four LASTZ binaries and selected Python3 helpers
- Python helper syntax checks
- native shared-library dependency checks with `ldd`
- a real alignment path on upstream test data across LAV, AXT, MAF, SAM, PAF,
  and floating-point LAV outputs

It does not replace full scientific validation on production datasets.

## License and Citation

TAFFISH app packaging: Apache-2.0.

Upstream LASTZ is distributed under the MIT license. Upstream documentation
lists the core reference as:

Harris RS (2007). Improved pairwise alignment of genomic DNA. Ph.D. thesis,
Pennsylvania State University.
