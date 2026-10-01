#!/bin/sh

set -eu

smoke_work=

cleanup() {
    cd / 2>/dev/null || true
    if [ -n "$smoke_work" ] && [ -d "$smoke_work" ]; then
        rm -rf "$smoke_work"
    fi
}

trap cleanup EXIT
trap 'cleanup; exit 129' HUP
trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

new_workdir() {
    smoke_work=$(mktemp -d "/tmp/taf-lastz-$1.XXXXXX")
}

fail_stage() {
    stage=$1
    rc=$2
    stderr_file=$3
    printf 'stage=%s rc=%s\n' "$stage" "$rc" >&2
    if [ -f "$stderr_file" ]; then
        tail -n 80 "$stderr_file" >&2 || true
    fi
    exit "$rc"
}

run_cmd() {
    stage=$1
    stdout_file=$2
    stderr_file=$3
    shift 3
    set +e
    "$@" >"$stdout_file" 2>"$stderr_file"
    rc=$?
    set -e
    if [ "$rc" -ne 0 ]; then
        fail_stage "$stage" "$rc" "$stderr_file"
    fi
}

run_information() {
    stage=$1
    output_file=$2
    shift 2
    set +e
    "$@" >"$output_file" 2>&1
    rc=$?
    set -e
    # 上游 --version/--help 明确 exit(EXIT_FAILURE)，不是正常功能命令。
    if [ "$rc" -ne 1 ]; then
        printf 'stage=%s expected informational exit=1 actual=%s\n' "$stage" "$rc" >&2
        tail -n 80 "$output_file" >&2
        exit 1
    fi
}

run_stdin() {
    stage=$1
    stdin_file=$2
    stdout_file=$3
    stderr_file=$4
    shift 4
    set +e
    "$@" <"$stdin_file" >"$stdout_file" 2>"$stderr_file"
    rc=$?
    set -e
    if [ "$rc" -ne 0 ]; then
        fail_stage "$stage" "$rc" "$stderr_file"
    fi
}

testdata=/opt/lastz/share/testdata
tools=/opt/lastz/share/lastz/tools
tabular=/opt/lastz/share/lastz/tabular_tools

case "${1:-}" in
    source)
        grep -Fx 'LASTZ 1.04.60' /opt/lastz/share/doc/lastz/source.txt >/dev/null
        grep -Fx 'SHA256: e66bb419a6599861b1d48c3b209d3746e8008c3ddde33f0dfeaa76e634bccebf' \
            /opt/lastz/share/doc/lastz/source.txt >/dev/null
        grep -F 'Python 3 compatibility: strict package patch applied.' \
            /opt/lastz/share/doc/lastz/source.txt >/dev/null
        test "$(find "$tools" -maxdepth 1 -type f | wc -l)" -eq 19
        test "$(find "$tabular" -maxdepth 1 -type f | wc -l)" -eq 7
        test "$(find "$tools" "$tabular" -maxdepth 1 -type f -name '*.py' | wc -l)" -eq 23
        test "$(find "$tools" "$tabular" -maxdepth 1 -type f -perm /111 | wc -l)" -eq 22
        if find /opt/lastz -type d -name __pycache__ -print | grep -q .; then
            printf 'unexpected image-root __pycache__\n' >&2
            exit 1
        fi
        ;;
    versions)
        new_workdir versions
        for command in lastz lastz_D lastz_32 lastz_40; do
            run_information "$command-version" "$smoke_work/version" \
                "$command" --version
            grep -Fx 'lastz (version 1.04.60 released 20260928)' "$smoke_work/version" >/dev/null
            run_cmd "$command-libraries" "$smoke_work/libraries" "$smoke_work/libraries.stderr" \
                ldd "$(command -v "$command")"
            if grep -F 'not found' "$smoke_work/libraries"; then
                printf 'missing runtime library: %s\n' "$command" >&2
                exit 1
            fi
        done
        run_information lastz-help "$smoke_work/help" lastz --help
        grep -F 'target[[start..end]]' "$smoke_work/help" >/dev/null
        grep -F -- '--format=<type>' "$smoke_work/help" >/dev/null
        ;;
    pycompile)
        new_workdir pycompile
        find "$tools" "$tabular" -maxdepth 1 -type f -name '*.py' | sort \
            > "$smoke_work/python-files.txt"
        test "$(wc -l < "$smoke_work/python-files.txt")" -eq 23
        while IFS= read -r source_file; do
            PYTHONPYCACHEPREFIX="$smoke_work/pycache" \
                python3 -m py_compile "$source_file"
        done < "$smoke_work/python-files.txt"
        test "$(find "$smoke_work/pycache/opt/lastz/share/lastz" \
            -type f -name '*.pyc' | wc -l)" -eq 23
        if find /opt/lastz -type d -name __pycache__ -print | grep -q .; then
            printf 'pycompile wrote to the image root\n' >&2
            exit 1
        fi
        ;;
    align)
        new_workdir align
        run_cmd lastz-lav "$smoke_work/out.lav" "$smoke_work/lastz-lav.stderr" \
            lastz "$testdata/pseudocat.fa" "$testdata/pseudopig.fa" C=2 W=8 T=0 --format=lav
        grep -F '#:lav' "$smoke_work/out.lav" >/dev/null
        run_cmd lastz-axt "$smoke_work/out.axt" "$smoke_work/lastz-axt.stderr" \
            lastz "$testdata/pseudocat.fa" "$testdata/pseudopig.fa" C=2 W=8 T=0 --format=axt
        test -s "$smoke_work/out.axt"
        run_cmd lastz-maf "$smoke_work/out.maf" "$smoke_work/lastz-maf.stderr" \
            lastz "$testdata/pseudocat.fa" "$testdata/pseudopig.fa" C=2 W=8 T=0 --format=maf
        grep -F '##maf version=1' "$smoke_work/out.maf" >/dev/null
        run_cmd lastz-D "$smoke_work/out_D.lav" "$smoke_work/lastz-D.stderr" \
            lastz_D "$testdata/pseudocat.fa" "$testdata/pseudopig.fa" C=2 W=8 T=0
        test -s "$smoke_work/out_D.lav"
        run_cmd lastz-32 "$smoke_work/out.sam" "$smoke_work/lastz-32.stderr" \
            lastz_32 "$testdata/pseudocat.fa" "$testdata/pseudopig.fa" C=2 W=8 T=0 --format=sam-
        test -s "$smoke_work/out.sam"
        run_cmd lastz-40 "$smoke_work/out.paf" "$smoke_work/lastz-40.stderr" \
            lastz_40 "$testdata/pseudocat.fa" "$testdata/pseudopig.fa" C=2 W=8 T=0 --format=paf
        test -s "$smoke_work/out.paf"
        ;;
    helpers)
        new_workdir helpers
        run_cmd helper-lav-input "$smoke_work/out.lav" "$smoke_work/helper-lav-input.stderr" \
            lastz "$testdata/pseudocat.fa" "$testdata/pseudopig.fa" C=2 W=8 T=0 --format=lav
        run_stdin lav-sort "$smoke_work/out.lav" "$smoke_work/sorted.lav" "$smoke_work/lav-sort.stderr" \
            lav_sort.py --key=beg1
        grep -F '#:lav' "$smoke_work/sorted.lav" >/dev/null

        run_cmd helper-maf-input "$smoke_work/out.maf" "$smoke_work/helper-maf-input.stderr" \
            lastz "$testdata/pseudocat.fa" "$testdata/pseudopig.fa" C=2 W=8 T=0 --format=maf
        run_stdin maf-sort "$smoke_work/out.maf" "$smoke_work/sorted.maf" "$smoke_work/maf-sort.stderr" \
            maf_sort.py --key=beg1
        grep -F '##maf version=1' "$smoke_work/sorted.maf" >/dev/null

        cat "$testdata/pseudocat.fa" "$testdata/pseudopig.fa" > "$smoke_work/references.fa"
        run_cmd helper-tabular-input "$smoke_work/out.tsv" "$smoke_work/helper-tabular-input.stderr" \
            lastz "$testdata/pseudocat.fa" "$testdata/pseudopig.fa" C=2 W=8 T=0 \
            --format=general:name1,zstart1,end1,name2,strand2,zstart2+,end2+,cigarx
        run_stdin tabular-fasta "$smoke_work/out.tsv" "$smoke_work/from-fasta.maf" "$smoke_work/tabular-fasta.stderr" \
            tabular_to_maf.py --sequences="$smoke_work/references.fa"
        grep -F '##maf version=1' "$smoke_work/from-fasta.maf" >/dev/null

        python3 -c 'import gzip,sys; data=open(sys.argv[1],"rb").read(); gzip.open(sys.argv[2],"wb").write(data)' \
            "$smoke_work/references.fa" "$smoke_work/references.fa.gz"
        run_stdin tabular-gzip "$smoke_work/out.tsv" "$smoke_work/from-gzip.maf" "$smoke_work/tabular-gzip.stderr" \
            tabular_to_maf.py --sequences="$smoke_work/references.fa.gz"
        grep -F '##maf version=1' "$smoke_work/from-gzip.maf" >/dev/null

        run_cmd helper-2bit-input "$smoke_work/self.tsv" "$smoke_work/helper-2bit-input.stderr" \
            lastz "$testdata/pseudopig.2bit[multiple]" "$testdata/pseudopig.2bit[multiple]" \
            C=2 W=8 T=0 \
            --format=general:name1,zstart1,end1,name2,strand2,zstart2+,end2+,cigarx
        run_stdin tabular-2bit "$smoke_work/self.tsv" "$smoke_work/from-2bit.maf" "$smoke_work/tabular-2bit.stderr" \
            tabular_to_maf.py --sequences="$testdata/pseudopig.2bit"
        grep -F '##maf version=1' "$smoke_work/from-2bit.maf" >/dev/null

        cp "$testdata/pseudocat.fa" "$smoke_work/reference.fa"
        run_cmd build-hsx "$smoke_work/reference.hsx" "$smoke_work/build-hsx.stderr" \
            sh -c 'cd "$1" && build_fasta_hsx.py reference.fa' sh "$smoke_work"
        run_cmd pick-hsx "$smoke_work/picked.fa" "$smoke_work/pick-hsx.stderr" \
            pick_from_fasta_hsx.py "$smoke_work/reference.hsx" cat
        grep -F '> cat' "$smoke_work/picked.fa" >/dev/null

        run_cmd probabilities-scores "$smoke_work/scores.txt" "$smoke_work/probabilities-scores.stderr" \
            probabilities_to_scores.py --hoxd70 --scaleto=100
        grep -F 'A' "$smoke_work/scores.txt" >/dev/null
        run_stdin expand-scores "$smoke_work/scores.txt" "$smoke_work/expanded-scores.txt" "$smoke_work/expand-scores.stderr" \
            expand_scores_file.py
        grep -F 'O=406' "$smoke_work/expanded-scores.txt" >/dev/null

        printf 'not-a-matrix\n' > "$smoke_work/invalid-scores.txt"
        set +e
        expand_scores_file.py < "$smoke_work/invalid-scores.txt" \
            > "$smoke_work/invalid-scores.stdout" 2> "$smoke_work/invalid-scores.stderr"
        invalid_rc=$?
        set -e
        test "$invalid_rc" -ne 0
        grep -F 'scores file lacks A-to-A score' "$smoke_work/invalid-scores.stderr" >/dev/null

        printf '1 3\n3 5\n10 11\n' > "$smoke_work/intervals.txt"
        run_stdin merge-intervals "$smoke_work/intervals.txt" "$smoke_work/merged-intervals.txt" "$smoke_work/merge-intervals.stderr" \
            merge_masking_intervals.py
        grep -F "1$(printf '\t')5" "$smoke_work/merged-intervals.txt" >/dev/null
        run_stdin qdna-simple "$testdata/pseudocat.fa" "$smoke_work/pseudocat-simple.qdna" "$smoke_work/qdna-simple.stderr" \
            any_to_qdna.py --simple
        run_cmd qdna-simple-verify "$smoke_work/qdna-simple-verify.stdout" "$smoke_work/qdna-simple-verify.stderr" \
            python3 -c 'import pathlib,sys; source=pathlib.Path(sys.argv[1]).read_bytes(); qdna=pathlib.Path(sys.argv[2]).read_bytes(); assert qdna[:4] == bytes.fromhex("f656659e"); assert qdna[4:] == source' \
            "$testdata/pseudocat.fa" "$smoke_work/pseudocat-simple.qdna"
        run_stdin qdna-named "$testdata/pseudocat.fa" "$smoke_work/pseudocat-named.qdna" "$smoke_work/qdna-named.stderr" \
            any_to_qdna.py --name=cat
        run_cmd qdna-named-verify "$smoke_work/qdna-named-verify.stdout" "$smoke_work/qdna-named-verify.stderr" \
            python3 -c 'import pathlib,sys; source=pathlib.Path(sys.argv[1]).read_bytes(); qdna=pathlib.Path(sys.argv[2]).read_bytes(); assert qdna[:4] == bytes.fromhex("c4b47197"); assert b"cat\0" in qdna[:64]; assert qdna.endswith(source)' \
            "$testdata/pseudocat.fa" "$smoke_work/pseudocat-named.qdna"
        run_stdin fragments "$testdata/pseudocat.fa" "$smoke_work/fragments.fa" "$smoke_work/fragments.stderr" \
            fasta_fragments.py --fragment=20 --step=10 --head=2
        grep -F '>' "$smoke_work/fragments.fa" >/dev/null
        ;;
    masking)
        new_workdir masking
        run_cmd segments "$smoke_work/self.seg" "$smoke_work/segments.stderr" \
            lastz "$testdata/pseudocat.fa" "$testdata/pseudocat.fa" --format=segments
        test -s "$smoke_work/self.seg"
        run_cmd masked-segments "$smoke_work/masked.maf" "$smoke_work/masked.stderr" \
            lastz "$testdata/pseudocat.fa" "$testdata/pseudocat.fa" \
                --segments="$smoke_work/self.seg" --masking=1 --format=maf
        grep -F '##maf version=1' "$smoke_work/masked.maf" >/dev/null
        grep -E '^s[[:space:]]' "$smoke_work/masked.maf" >/dev/null
        ;;
    *)
        printf 'usage: taf-lastz-smoke {source|versions|pycompile|align|helpers|masking}\n' >&2
        exit 64
        ;;
esac

printf 'smoke:%s:ok\n' "$1"
