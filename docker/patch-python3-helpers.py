#!/usr/bin/env python3

import ast
import re
import sys
from pathlib import Path


def replace_once(path: Path, old: str, new: str, label: str) -> None:
    text = path.read_text()
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{label}: expected exactly one source pattern, found {count}")
    path.write_text(text.replace(old, new, 1))


def replace_region_once(path: Path, start: str, end: str, new: str, label: str) -> None:
    text = path.read_text()
    if text.count(start) != 1 or text.count(end) != 1:
        raise SystemExit(f"{label}: expected exactly one pair of region markers")
    start_index = text.index(start)
    end_index = text.index(end, start_index)
    path.write_text(text[:start_index] + new + text[end_index:])


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit("usage: patch-python3-helpers.py <lastz-source-root>")

    root = Path(sys.argv[1])
    fasta_file = root / "tabular_tools" / "fasta_file.py"
    two_bit_file = root / "tabular_tools" / "two_bit_file.py"
    expand_scores = root / "tools" / "expand_scores_file.py"
    build_fasta_hsx = root / "tools" / "build_fasta_hsx.py"
    hsx_file = root / "tools" / "hsx_file.py"
    any_to_qdna = root / "tools" / "any_to_qdna.py"

    replace_once(
        fasta_file,
        "from collections import MutableMapping",
        "from collections.abc import MutableMapping",
        "fasta_file MutableMapping import",
    )
    replace_once(
        two_bit_file,
        "from collections import MutableMapping",
        "from collections.abc import MutableMapping",
        "two_bit_file MutableMapping import",
    )
    replace_once(
        fasta_file,
        'raise ValueError("this .fai implementation doesn\'t support compressed fasta files (\\\"%d\\\")" % f)',
        'raise ValueError("this .fai implementation doesn\'t support compressed fasta files (\\\"%s\\\")" % f)',
        "compressed FASTA error formatting",
    )
    replace_once(
        fasta_file,
        '\t\telif (type(f) == str):\n\t\t\tf = open(f,"r")',
        '\t\telif (type(f) == str):\n'
        '\t\t\tif (f.endswith(".gz")) or (f.endswith(".gzip")):\n'
        '\t\t\t\tfrom gzip import open as gzip_open\n'
        '\t\t\t\tf = gzip_open(f,"rt")\n'
        '\t\t\telse:\n'
        '\t\t\t\tf = open(f,"r")',
        "gzip FASTA text reader",
    )

    replacements = (
        (
            '\t\t\t\traise "in scores file, unexpected assignment (line %d): %s" \\\n'
            '\t\t\t\t\t% (lineNumber,line)',
            '\t\t\t\traise ValueError("in scores file, unexpected assignment (line %d): %s" \\\n'
            '\t\t\t\t\t% (lineNumber,line))',
            "unexpected assignment exception",
        ),
        (
            '\t\t\t\traise "in scores file, %s is assigned twice (line %d): %s" \\\n'
            '\t\t\t\t\t% (name,lineNumber,line)',
            '\t\t\t\traise ValueError("in scores file, %s is assigned twice (line %d): %s" \\\n'
            '\t\t\t\t\t% (name,lineNumber,line))',
            "duplicate assignment exception",
        ),
        (
            '\t\t\t\t\traise "in scores file, bad assignment value (line %d): %s" \\\n'
            '\t\t\t\t\t\t% (lineNumber,line)',
            '\t\t\t\t\traise ValueError("in scores file, bad assignment value (line %d): %s" \\\n'
            '\t\t\t\t\t\t% (lineNumber,line))',
            "bad assignment exception",
        ),
        (
            '\t\t\t\traise "in scores file, inconsistent matrix (line %d): %s" \\\n'
            '\t\t\t\t\t% (lineNumber,line)',
            '\t\t\t\traise ValueError("in scores file, inconsistent matrix (line %d): %s" \\\n'
            '\t\t\t\t\t% (lineNumber,line))',
            "inconsistent matrix exception",
        ),
        (
            '\t\traise "scores file is missing a matrix"',
            '\t\traise ValueError("scores file is missing a matrix")',
            "missing matrix exception",
        ),
        (
            '\t\traise "scores file lacks A-to-A score"',
            '\t\traise ValueError("scores file lacks A-to-A score")',
            "missing A-to-A exception",
        ),
    )
    for old, new, label in replacements:
        replace_once(expand_scores, old, new, label)

    replace_region_once(
        build_fasta_hsx,
        "def write1(val):\n",
        "# fasta_sequences--\n",
        '''def write_bytes(data):
\tsys.stdout.buffer.write(data)

def write1(val):
\twrite_bytes(val.to_bytes(1,byteorder="little"))

def writeString(s):
\tencoded = s.encode("ascii")
\tassert (len(encoded) <= 255)
\twrite1(len(encoded))
\twrite_bytes(encoded)

def writeZeros(n):
\twrite_bytes(bytes(n))

def write4_little_endian(val):
\twrite_bytes(val.to_bytes(4,byteorder="little"))

def write5_little_endian(val):
\twrite_bytes(val.to_bytes(5,byteorder="little"))

def write6_little_endian(val):
\twrite_bytes(val.to_bytes(6,byteorder="little"))

def write4_big_endian(val):
\twrite_bytes(val.to_bytes(4,byteorder="big"))

def write5_big_endian(val):
\twrite_bytes(val.to_bytes(5,byteorder="big"))

def write6_big_endian(val):
\twrite_bytes(val.to_bytes(6,byteorder="big"))

''',
        "binary HSX stdout writer",
    )
    replace_region_once(
        hsx_file,
        "\tdef read1(self):\n",
        "\t# hash\n",
        '''\tdef read1(self):
\t\treturn self.file.read(1)[0]

\tdef read4(self):
\t\treturn struct.unpack(self.struct4,self.file.read(4))[0]

\tdef read5(self):
\t\treturn self.read_and_unpack(5)

\tdef read6(self):
\t\treturn self.read_and_unpack(6)

\tdef readString(self):
\t\tlength = self.file.read(1)[0]
\t\treturn self.file.read(length).decode("ascii")

\tdef read_and_unpack(self,byte_count):
\t\tdata = self.file.read(byte_count)
\t\tbyte_order = "little" if (self.byteOrder == "<") else "big"
\t\treturn int.from_bytes(data,byteorder=byte_order)

''',
        "binary HSX reader",
    )
    replace_once(
        any_to_qdna,
        '\t\tuaseg("simple qdna file cannot carry a sequence name")',
        '\t\tusage("simple qdna file cannot carry a sequence name")',
        "simple qdna usage error",
    )
    replace_region_once(
        any_to_qdna,
        "\t# === read the input file ===\n",
        "\ndef write_4(f,val):\n",
        '''\t# === read the input file ===

\tseq = stdin.buffer.read()
\tif (strip): seq = b"".join(seq.splitlines())

\t# === write the qdna file ===

\tif (not simple):
\t\theaderLen = 20
\t\tif (name == None):
\t\t\tnameOffset = 0
\t\t\tseqOffset  = headerLen + 8;
\t\telse:
\t\t\tnameOffset = headerLen + 8;
\t\t\tseqOffset  = nameOffset + len(name.encode("utf-8")) + 1

\t# prepend magic number

\tif (simple): write_4(stdout.buffer,qdnaOldMagic)
\telse:        write_4(stdout.buffer,qdnaMagic)

\t# write the rest of the header

\tif (not simple):
\t\twrite_4(stdout.buffer,qdnaVersion)
\t\twrite_4(stdout.buffer,headerLen)
\t\twrite_4(stdout.buffer,seqOffset)
\t\twrite_4(stdout.buffer,nameOffset)
\t\twrite_4(stdout.buffer,len(seq))
\t\twrite_4(stdout.buffer,0)

\t\tif (name != None):
\t\t\tstdout.buffer.write(name.encode("utf-8"))
\t\t\tstdout.buffer.write(bytes((0,)))

\t# write the sequence

\tstdout.buffer.write(seq)
''',
        "binary qdna input and stdout",
    )
    replace_region_once(
        any_to_qdna,
        "def write_4(f,val):\n",
        "\n\nif __name__ == \"__main__\": main()\n",
        '''def write_4(f,val):
\tf.write(val.to_bytes(4,byteorder="big"))
''',
        "binary qdna integer writer",
    )

    python_files = sorted((root / "tools").glob("*.py"))
    python_files += sorted((root / "tabular_tools").glob("*.py"))
    if len(python_files) != 23:
        raise SystemExit(f"Python helper surface: expected 23 files, found {len(python_files)}")

    for path in python_files:
        text = path.read_text()
        if "from collections import MutableMapping" in text:
            raise SystemExit(f"legacy MutableMapping import remains: {path}")
        if re.search(r"^\s*raise\s+[\"']", text, flags=re.MULTILINE):
            raise SystemExit(f"string exception remains: {path}")
        if "sys.stdout.write(chr" in text:
            raise SystemExit(f"text-mode binary stdout writer remains: {path}")
        if "ord(self.file.read(" in text:
            raise SystemExit(f"Python 2 bytes reader remains: {path}")
        ast.parse(text, filename=str(path))


if __name__ == "__main__":
    main()
