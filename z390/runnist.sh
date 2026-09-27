#!/bin/bash
# runnist.sh: run the NIST COBOL test suite with z390 zCobol.
#
# Bash counterpart of RUNNIST.BAT. Argument names are case-sensitive.
# Trace with bash -x; this script does not accept tron or troff.
# When this script is traced, cblc and cblclg are started with bash -x as well.
#
# This script reflects the current status of the adoption process of the
# NIST test suite in z390 / zCobol. We reconcile source versions and fix
# compiler breakage. Most compiles end with RC=8; other issues are left
# for future maintenance.

NIST_RC=0
parmrc=0
test_all=
cleanup=
z390dir=
z390_LVL=
NIST_LVL=
copymbr=0
copyerr=0
datambr=0
dataerr=0
nocount=0
tested=0
testgood=0
testwarn=0
testerr=0
testfail=0
test_ALT=
test_K=
test_EX=
test_CM=
test_DB=
test_IC=
test_IF=
test_IX=
test_NC=
test_OB=
test_RL=
test_RW=
test_SG=
test_SM=
test_SQ=
test_ST=

script_dir=$(cd "$(dirname "$0")" && pwd)
cd "$script_dir/.." || exit 1
nistdir=$(pwd)
allerr="$nistdir/z390/#all.err"
full_log="$nistdir/z390/#full_log.txt"
sort_log="$nistdir/z390/#allsort.err"
summary="$nistdir/z390/RUNNIST.ERR"

finish() {
  exit "$NIST_RC"
}

show_help() {
  NIST_RC=8
  echo .
  echo "$0 ERROR: no arguments provided - path to z390 repository unknown"
  echo .
  echo "The path to a local clone of the z390 repository with z390.jar available must be specified."
  echo "Note: if z390.jar is not available, please run the z390 documented build procedure."
  echo .
  echo "When the z390 path is omitted, no tests can be run"
  echo "When the z390 path is specified, the default is to run all tests"
  echo "This default can be overriden by specifying one or more of the following parameters:"
  echo "- cleanup = cleanup only; no compiles"
  echo "- ALT= ALT* copy members"
  echo "- CM = Communications Module"
  echo "- DB = Debug module"
  echo "- EX = Executive module"
  echo "- IC = Inter-Program Communication"
  echo "- IF = Intrinsic Functions"
  echo "- IX = Indexed I/O"
  echo "- K  = K* copy members"
  echo "- NC = Nucleus"
  echo "- OB = Obsolete features"
  echo "- RL = Relative I/O"
  echo "- RW = Report Writer"
  echo "- SG = Segmentation"
  echo "- SM = Source Manipulation"
  echo "- SQ = Sequential I/O"
  echo "- ST = Sort / Merge"
  echo .
  echo "There is no prescribed order of parameters"
  echo "Parameter names are case-sensitive."
  echo "Trace this script with bash -x."
  echo .
  echo "To specify z390 options, provide them in variable z390opt"
  echo .
}

no_nistrepo() {
  NIST_RC=12
  echo "$0 ERROR: $nistdir is not a git repository"
  finish
}

no_z390repo() {
  NIST_RC=12
  echo "$0 ERROR: $z390dir is not a git repository"
  finish
}

# Run this module when every module is selected, or when its flag is Y.
section() {
  if [ "$test_all" != "N" ]; then
    return 0
  fi
  [ "$1" = "Y" ]
}

# Remove generated files. Match extensions case-insensitively so cleanup
# removes the same files Windows deletes with *.ERR and the like.
sub_clean() {
  local dir=$1
  find "$dir" -maxdepth 1 -type f \( \
    -iname '*.390' -o -iname '*.BAL' -o -iname '*.ERR' -o -iname '*.LOG' \
    -o -iname '*.LST' -o -iname '*.MLC' -o -iname '*.OBJ' -o -iname '*.OUT' \
    -o -iname '*.PRN' -o -iname '*.CBL_ZC_LABELS.CPY' \
  \) -delete
}

sub_cobol() {
  local proc=$1
  local dir=$2
  local pgm=$3
  local mode=${4:-}
  local myRC=0
  local err="$dir/$pgm.ERR"

  if [ "$mode" = "NOCOUNT" ]; then
    nocount=$((nocount + 1))
  else
    tested=$((tested + 1))
  fi

  if [ ! -f "$dir/$pgm.CBL" ]; then
    if [ "$NIST_RC" -lt 12 ]; then NIST_RC=12; fi
    testerr=$((testerr + 1))
    echo "$dir/$pgm.CBL not found" >> "$err"
    cat "$err"
    cat "$err" >> "$allerr" 2>/dev/null || true
    return 0
  fi

  export XXXXX047="${script_dir}/"
  export XXXXX048="${nistdir}/z390alt/"
  if [ "$proc" = "cblclg" ]; then
    export XXXXX055="$dir/${pgm}_XXXXX055.OUT"
  else
    export XXXXX055=
  fi

  # z390opt is split on spaces, as %z390opt% is in RUNNIST.BAT.
  # bash -x is the counterpart of the tron argument RUNNIST.BAT passes down.
  local -a trace_flag=()
  case $- in
    *x*) trace_flag=(-x) ;;
  esac
  set -f
  bash "${trace_flag[@]}" "${z390dir}/bash/${proc}" "$dir/$pgm" notiming "SYSCPY(+${script_dir}/)" $z390opt
  myRC=$?
  set +f
  if [ "$myRC" -gt "$NIST_RC" ]; then NIST_RC=$myRC; fi

  if [ "$mode" != "NOCOUNT" ]; then
    if [ "$myRC" -eq 0 ]; then
      testgood=$((testgood + 1))
    elif [ "$myRC" -eq 4 ]; then
      testwarn=$((testwarn + 1))
    elif [ "$myRC" -eq 8 ]; then
      testerr=$((testerr + 1))
    else
      testfail=$((testfail + 1))
    fi
  fi
  cat "$err" >> "$allerr" 2>/dev/null || true
}

sub_copy() {
  local dir=$1
  local pgm=$2
  local err="$dir/$pgm.ERR"
  if [ -f "$dir/$pgm.CPY" ]; then
    copymbr=$((copymbr + 1))
    echo "$dir/$pgm.CPY found" >> "$err"
  else
    if [ "$NIST_RC" -lt 12 ]; then NIST_RC=12; fi
    copyerr=$((copyerr + 1))
    echo "$dir/$pgm.CPY not found" >> "$err"
  fi
  cat "$err"
  cat "$err" >> "$allerr" 2>/dev/null || true
}

sub_data() {
  local dir=$1
  local pgm=$2
  local err="$dir/$pgm.ERR"
  if [ -f "$dir/$pgm.DAT" ]; then
    datambr=$((datambr + 1))
    echo "$dir/$pgm.DAT found" >> "$err"
  else
    if [ "$NIST_RC" -lt 12 ]; then NIST_RC=12; fi
    dataerr=$((dataerr + 1))
    echo "$dir/$pgm.DAT not found" >> "$err"
  fi
  cat "$err"
  cat "$err" >> "$allerr" 2>/dev/null || true
}

# Windows SORT /+17 compares from the 17th character.
sort_plus17() {
  local input=$1
  local output=$2
  local rc
  set -o pipefail
  awk -v col=17 '{
    key = substr($0, col)
    printf "%s\034%s\n", key, $0
  }' "$input" | LC_ALL=C sort -t $'\034' -k1,1 | awk 'BEGIN { FS = "\034" } {
    print substr($0, length($1) + 2)
  }' > "$output"
  rc=$?
  set +o pipefail
  return "$rc"
}

# Same substitutions as RunNistEdit.PS1, using the paths recorded in this run.
edit_full_log() {
  local file=$1
  local tmp
  tmp=$(mktemp)
  awk -v nist="$nistdir" -v z390="$z390dir" '
    BEGIN {
      nist_repl = "<z390development/nistcobol85>"
      z390_repl = "<z390development/z390>"
    }
    {
      line = $0
      while ((i = index(line, nist)) > 0)
        line = substr(line, 1, i - 1) nist_repl substr(line, i + length(nist))
      while ((i = index(line, z390)) > 0)
        line = substr(line, 1, i - 1) z390_repl substr(line, i + length(z390))
      gsub(/IO=[0-9]+/, "IO=***", line)
      gsub(/FID= *[0-9]+ ERR=/, "FID=*** ERR=", line)
      print line
    }
  ' "$file" > "$tmp" && mv "$tmp" "$file"
}

if [ $# -eq 0 ]; then
  show_help
  finish
fi

while [ $# -gt 0 ]; do
  case "$1" in
    ALT) test_ALT=Y; test_all=N ;;
    K) test_K=Y; test_all=N ;;
    EX) test_EX=Y; test_all=N ;;
    CM) test_CM=Y; test_all=N ;;
    DB) test_DB=Y; test_all=N ;;
    IC) test_IC=Y; test_all=N ;;
    IF) test_IF=Y; test_all=N ;;
    IX) test_IX=Y; test_all=N ;;
    NC) test_NC=Y; test_all=N ;;
    OB) test_OB=Y; test_all=N ;;
    RL) test_RL=Y; test_all=N ;;
    RW) test_RW=Y; test_all=N ;;
    SG) test_SG=Y; test_all=N ;;
    SM) test_SM=Y; test_all=N ;;
    SQ) test_SQ=Y; test_all=N ;;
    ST) test_ST=Y; test_all=N ;;
    cleanup) cleanup=Y; test_all=N ;;
    *)
      # A z390 root contains bash/cblclg, the counterpart of bat/CBLCLG.BAT.
      if [ -f "$1/bash/cblclg" ] && z390dir=$(cd -- "$1" && pwd); then
        :
      else
        echo "$0 Unknown parameter: $1"
        parmrc=8
        test_all=N
      fi
      ;;
  esac
  shift
done

NIST_LVL=$(git rev-parse HEAD) || no_nistrepo

# Unknown parameters are reported above. RUNNIST.BAT then returns the
# current NIST_RC, which is still 0.
if [ "$parmrc" -eq 8 ]; then
  finish
fi

if [ "$cleanup" != "Y" ]; then
  if [ -z "$z390dir" ] || [ ! -f "$z390dir/z390.jar" ]; then
    show_help
    finish
  fi
  cd "$z390dir" || {
    NIST_RC=12
    echo "$0 ERROR: cannot enter $z390dir"
    finish
  }
  z390_LVL=$(git rev-parse HEAD) || no_z390repo
fi

echo "Cleaning up..."
sub_clean "$nistdir/src"
sub_clean "$nistdir/z390"
echo "Cleanup complete"
if [ "$cleanup" = "Y" ]; then
  finish
fi

# ALT copy members and purpose:
if section "${test_ALT}"; then
  sub_copy "$nistdir/src" ALTL1  # intended for use by EXEC85
  sub_copy "$nistdir/src" ALTLB  # intended for use by EXEC85
fi

# K* copy members
if section "${test_K}"; then
  sub_copy "$nistdir/src" K101A
  sub_copy "$nistdir/src" K1DAA
  sub_copy "$nistdir/src" K1FDA
  sub_copy "$nistdir/src" K1P01
  sub_copy "$nistdir/src" K1PRA
  sub_copy "$nistdir/src" K1PRB
  sub_copy "$nistdir/src" K1PRC
  sub_copy "$nistdir/src" K1SEA
  sub_copy "$nistdir/src" K1W01
  sub_copy "$nistdir/src" K1W02
  sub_copy "$nistdir/src" K1W03
  sub_copy "$nistdir/src" K1W04
  sub_copy "$nistdir/src" K1WKA
  sub_copy "$nistdir/src" K1WKB
  sub_copy "$nistdir/src" K1WKC
  sub_copy "$nistdir/src" K1WKY
  sub_copy "$nistdir/src" K1WKZ
  sub_copy "$nistdir/src" K2PRA
  sub_copy "$nistdir/src" K2SEA
  sub_copy "$nistdir/src" K3FCA
  sub_copy "$nistdir/src" K3FCB
  sub_copy "$nistdir/src" K3IOA
  sub_copy "$nistdir/src" K3IOB
  sub_copy "$nistdir/src" K3LGE
  sub_copy "$nistdir/src" K3OCA
  sub_copy "$nistdir/src" K3SCA
  sub_copy "$nistdir/src" K3SML
  sub_copy "$nistdir/src" K3SNA
  sub_copy "$nistdir/src" K3SNB
  sub_copy "$nistdir/src" K4NTA  # defined but never used (on purpose)
  sub_copy "$nistdir/src" K501A
  sub_copy "$nistdir/src" K501B
  sub_copy "$nistdir/src" K5SDA
  sub_copy "$nistdir/src" K5SDB
  sub_copy "$nistdir/src" K6SCA
  sub_copy "$nistdir/src" K7SEA
  sub_copy "$nistdir/src" KK208A
  sub_copy "$nistdir/src" KP001
  sub_copy "$nistdir/src" KP002
  sub_copy "$nistdir/src" KP003
  sub_copy "$nistdir/src" KP004
  sub_copy "$nistdir/src" KP005
  sub_copy "$nistdir/src" KP006
  sub_copy "$nistdir/src" KP007
  sub_copy "$nistdir/src" KP008
  sub_copy "$nistdir/src" KP009
  sub_copy "$nistdir/src" KP010  # not used but probably belonged with SM206A
  sub_copy "$nistdir/src" KSM31
  sub_copy "$nistdir/src" KSM41
fi

# EX = Executive module
if section "${test_EX}"; then
  sub_cobol cblclg "$nistdir/src" EXEC85
fi

# CM = Communications Module
if section "${test_CM}"; then
  sub_cobol cblclg "$nistdir/src" CM101M
  sub_cobol cblclg "$nistdir/src" CM102M
  sub_cobol cblclg "$nistdir/src" CM103M
  sub_cobol cblclg "$nistdir/src" CM104M
  sub_cobol cblclg "$nistdir/src" CM105M
  sub_cobol cblclg "$nistdir/src" CM201M
  sub_cobol cblclg "$nistdir/src" CM202M
  sub_cobol cblclg "$nistdir/src" CM303M
  sub_cobol cblclg "$nistdir/src" CM401M
fi

# DB = Debug module
if section "${test_DB}"; then
  sub_cobol cblclg "$nistdir/src" DB101A
  sub_cobol cblclg "$nistdir/src" DB102A
  sub_cobol cblclg "$nistdir/src" DB103M
  sub_cobol cblclg "$nistdir/src" DB104A
  sub_cobol cblclg "$nistdir/src" DB105A
  sub_cobol cblclg "$nistdir/src" DB201A
  sub_cobol cblclg "$nistdir/src" DB202A
  sub_cobol cblclg "$nistdir/src" DB203A
  sub_cobol cblclg "$nistdir/src" DB204A
  sub_cobol cblclg "$nistdir/src" DB205A
  sub_cobol cblclg "$nistdir/src" DB301M
  sub_cobol cblclg "$nistdir/src" DB302M
  sub_cobol cblclg "$nistdir/src" DB303M
  sub_cobol cblclg "$nistdir/src" DB304M
  sub_cobol cblclg "$nistdir/src" DB305M
fi

# IC = Inter-Program Communication - subprograms must be compiled before each main program!
if section "${test_IC}"; then
  sub_cobol cblc   "$nistdir/src" IC102A
  sub_cobol cblclg "$nistdir/src" IC101A
  sub_cobol cblc   "$nistdir/src" IC104A
  sub_cobol cblc   "$nistdir/src" IC105A
  sub_cobol cblclg "$nistdir/src" IC103A
  sub_cobol cblc   "$nistdir/src" IC107A
  sub_cobol cblclg "$nistdir/src" IC106A
  sub_cobol cblc   "$nistdir/src" IC109A
  sub_cobol cblc   "$nistdir/src" IC110A
  sub_cobol cblc   "$nistdir/src" IC111A
  sub_cobol cblclg "$nistdir/src" IC108A
  sub_cobol cblc   "$nistdir/src" IC113A
  sub_cobol cblclg "$nistdir/src" IC112A  # fails to generate the call to IC113A
  sub_cobol cblc   "$nistdir/src" IC115A
  sub_cobol cblclg "$nistdir/src" IC114A
  sub_cobol cblc   "$nistdir/src" IC117M
  sub_cobol cblc   "$nistdir/src" IC118M
  sub_cobol cblclg "$nistdir/src" IC116M
  sub_cobol cblc   "$nistdir/src" IC202A
  sub_cobol cblclg "$nistdir/src" IC201A
  sub_cobol cblc   "$nistdir/src" IC204A
  sub_cobol cblc   "$nistdir/src" IC205A
  sub_cobol cblc   "$nistdir/src" IC206A
  sub_cobol cblclg "$nistdir/src" IC203A
  sub_cobol cblc   "$nistdir/src" IC208A
  sub_cobol cblclg "$nistdir/src" IC207A
  sub_cobol cblc   "$nistdir/src" IC210A
  sub_cobol cblc   "$nistdir/src" IC211A
  sub_cobol cblc   "$nistdir/src" IC212A
  sub_cobol cblclg "$nistdir/src" IC209A
  sub_cobol cblc   "$nistdir/src" IC214A
  sub_cobol cblc   "$nistdir/src" IC215A
  sub_cobol cblclg "$nistdir/src" IC213A
  sub_cobol cblc   "$nistdir/src" IC217A
  sub_cobol cblclg "$nistdir/src" IC216A
  sub_cobol cblclg "$nistdir/src" IC222A
  sub_cobol cblc   "$nistdir/z390" IC222A1 NOCOUNT  # instead of the original
  sub_cobol cblclg "$nistdir/z390" IC222A  NOCOUNT  # instead of the original
  sub_cobol cblclg "$nistdir/src" IC223A
  sub_cobol cblc   "$nistdir/z390" IC223A1 NOCOUNT  # instead of the original
  sub_cobol cblclg "$nistdir/z390" IC223A  NOCOUNT  # instead of the original
  sub_cobol cblclg "$nistdir/src" IC224A
  sub_cobol cblc   "$nistdir/z390" IC224A1 NOCOUNT  # instead of the original
  sub_cobol cblclg "$nistdir/z390" IC224A  NOCOUNT  # instead of the original
  sub_cobol cblclg "$nistdir/src" IC225A
  sub_cobol cblc   "$nistdir/z390" IC225A1 NOCOUNT  # instead of the original
  sub_cobol cblclg "$nistdir/z390" IC225A  NOCOUNT  # instead of the original
  sub_cobol cblclg "$nistdir/src" IC226A
  sub_cobol cblc   "$nistdir/z390" IC226A1 NOCOUNT  # instead of the original
  sub_cobol cblclg "$nistdir/z390" IC226A  NOCOUNT  # instead of the original
  sub_cobol cblclg "$nistdir/src" IC227A
  sub_cobol cblc   "$nistdir/z390" IC227A1 NOCOUNT  # instead of the original
  sub_cobol cblclg "$nistdir/z390" IC227A  NOCOUNT  # instead of the original
  sub_cobol cblclg "$nistdir/src" IC228A
  sub_cobol cblc   "$nistdir/z390" IC228A1 NOCOUNT  # instead of the original
  sub_cobol cblclg "$nistdir/z390" IC228A  NOCOUNT  # instead of the original
  sub_cobol cblclg "$nistdir/src" IC233A
  sub_cobol cblc   "$nistdir/z390" IC233A1 NOCOUNT  # instead of the original
  sub_cobol cblclg "$nistdir/z390" IC233A  NOCOUNT  # instead of the original
  sub_cobol cblclg "$nistdir/src" IC234A
  sub_cobol cblc   "$nistdir/z390" IC234A1 NOCOUNT  # instead of the original
  sub_cobol cblc   "$nistdir/z390" IC234A2 NOCOUNT  # instead of the original
  sub_cobol cblc   "$nistdir/z390" IC234A3 NOCOUNT  # instead of the original
  sub_cobol cblclg "$nistdir/z390" IC234A  NOCOUNT  # instead of the original
  sub_cobol cblclg "$nistdir/src" IC235A
  sub_cobol cblc   "$nistdir/z390" IC235A1 NOCOUNT  # instead of the original
  sub_cobol cblc   "$nistdir/z390" IC235A2 NOCOUNT  # instead of the original
  sub_cobol cblclg "$nistdir/z390" IC235A  NOCOUNT  # instead of the original
  sub_cobol cblclg "$nistdir/src" IC237A
  sub_cobol cblc   "$nistdir/z390" IC237A1 NOCOUNT  # instead of the original
  sub_cobol cblclg "$nistdir/z390" IC237A  NOCOUNT  # instead of the original
  sub_cobol cblclg "$nistdir/src" IC401M
fi

# IF = Intrinsic Functions
if section "${test_IF}"; then
  sub_cobol cblclg "$nistdir/src" IF101A
  sub_cobol cblclg "$nistdir/src" IF102A
  sub_cobol cblclg "$nistdir/src" IF103A
  sub_cobol cblclg "$nistdir/src" IF104A
  sub_cobol cblclg "$nistdir/src" IF105A
  sub_cobol cblclg "$nistdir/src" IF106A
  sub_cobol cblclg "$nistdir/src" IF107A
  sub_cobol cblclg "$nistdir/src" IF108A
  sub_cobol cblclg "$nistdir/src" IF109A
  sub_cobol cblclg "$nistdir/src" IF110A
  sub_cobol cblclg "$nistdir/src" IF111A
  sub_cobol cblclg "$nistdir/src" IF112A
  sub_cobol cblclg "$nistdir/src" IF113A
  sub_cobol cblclg "$nistdir/src" IF114A
  sub_cobol cblclg "$nistdir/src" IF115A
  sub_cobol cblclg "$nistdir/src" IF116A
  sub_cobol cblclg "$nistdir/src" IF117A
  sub_cobol cblclg "$nistdir/src" IF118A
  sub_cobol cblclg "$nistdir/src" IF119A
  sub_cobol cblclg "$nistdir/src" IF120A
  sub_cobol cblclg "$nistdir/src" IF121A
  sub_cobol cblclg "$nistdir/src" IF122A
  sub_cobol cblclg "$nistdir/src" IF123A
  sub_cobol cblclg "$nistdir/src" IF124A
  sub_cobol cblclg "$nistdir/src" IF125A
  sub_cobol cblclg "$nistdir/src" IF126A
  sub_cobol cblclg "$nistdir/src" IF127A
  sub_cobol cblclg "$nistdir/src" IF128A
  sub_cobol cblclg "$nistdir/src" IF129A
  sub_cobol cblclg "$nistdir/src" IF130A
  sub_cobol cblclg "$nistdir/src" IF131A
  sub_cobol cblclg "$nistdir/src" IF132A
  sub_cobol cblclg "$nistdir/src" IF133A
  sub_cobol cblclg "$nistdir/src" IF134A
  sub_cobol cblclg "$nistdir/src" IF135A
  sub_cobol cblclg "$nistdir/src" IF136A
  sub_cobol cblclg "$nistdir/src" IF137A
  sub_cobol cblclg "$nistdir/src" IF138A
  sub_cobol cblclg "$nistdir/src" IF139A
  sub_cobol cblclg "$nistdir/src" IF140A
  sub_cobol cblclg "$nistdir/src" IF141A
  sub_cobol cblclg "$nistdir/src" IF142A
  sub_cobol cblclg "$nistdir/src" IF401M
  sub_cobol cblclg "$nistdir/src" IF402M
  sub_cobol cblclg "$nistdir/src" IF403M
fi

# IX = Indexed I/O
if section "${test_IX}"; then
  sub_cobol cblc   "$nistdir/src" IX102A
  sub_cobol cblc   "$nistdir/src" IX103A
  sub_cobol cblclg "$nistdir/src" IX101A
  sub_cobol cblclg "$nistdir/src" IX104A
  sub_cobol cblclg "$nistdir/src" IX105A
  sub_cobol cblclg "$nistdir/src" IX106A
  sub_cobol cblclg "$nistdir/src" IX107A
  sub_cobol cblclg "$nistdir/src" IX108A
  sub_cobol cblc   "$nistdir/src" IX110A
  sub_cobol cblc   "$nistdir/src" IX111A
  sub_cobol cblclg "$nistdir/src" IX109A
  sub_cobol cblclg "$nistdir/src" IX112A
  sub_cobol cblc   "$nistdir/src" IX114A
  sub_cobol cblc   "$nistdir/src" IX115A
  sub_cobol cblc   "$nistdir/src" IX116A
  sub_cobol cblc   "$nistdir/src" IX117A
  sub_cobol cblc   "$nistdir/src" IX118A
  sub_cobol cblc   "$nistdir/src" IX119A
  sub_cobol cblc   "$nistdir/src" IX120A
  sub_cobol cblclg "$nistdir/src" IX113A
  sub_cobol cblclg "$nistdir/src" IX121A
  sub_cobol cblc   "$nistdir/src" IX202A
  sub_cobol cblc   "$nistdir/src" IX203A
  sub_cobol cblclg "$nistdir/src" IX201A
  sub_cobol cblclg "$nistdir/src" IX204A
  sub_cobol cblclg "$nistdir/src" IX205A
  sub_cobol cblclg "$nistdir/src" IX206A
  sub_cobol cblclg "$nistdir/src" IX207A
  sub_cobol cblclg "$nistdir/src" IX208A
  sub_cobol cblclg "$nistdir/src" IX209A
  sub_cobol cblclg "$nistdir/src" IX210A
  sub_cobol cblclg "$nistdir/src" IX211A
  sub_cobol cblclg "$nistdir/src" IX212A
  sub_cobol cblclg "$nistdir/src" IX213A
  sub_cobol cblclg "$nistdir/src" IX214A
  sub_cobol cblclg "$nistdir/src" IX215A
  sub_cobol cblclg "$nistdir/src" IX216A
  sub_cobol cblclg "$nistdir/src" IX217A
  sub_cobol cblclg "$nistdir/src" IX218A
  sub_cobol cblclg "$nistdir/src" IX301M
  sub_cobol cblclg "$nistdir/src" IX302M
  sub_cobol cblclg "$nistdir/src" IX401M
fi

# NC = Nucleus
if section "${test_NC}"; then
  sub_cobol cblclg "$nistdir/src" NC101A
  sub_cobol cblclg "$nistdir/src" NC102A
  sub_cobol cblclg "$nistdir/src" NC103A
  sub_cobol cblclg "$nistdir/src" NC104A
  sub_cobol cblclg "$nistdir/src" NC105A
  sub_cobol cblclg "$nistdir/src" NC106A
  sub_cobol cblclg "$nistdir/src" NC107A
  sub_cobol cblclg "$nistdir/src" NC108M
  sub_data         "$nistdir/src" NC109M  # intended usage unknown
  sub_cobol cblclg "$nistdir/src" NC109M
  sub_cobol cblclg "$nistdir/src" NC110M
  sub_cobol cblclg "$nistdir/src" NC111A
  sub_cobol cblclg "$nistdir/src" NC112A
  sub_cobol cblclg "$nistdir/src" NC113M
  sub_cobol cblclg "$nistdir/src" NC114M
  sub_cobol cblclg "$nistdir/src" NC115A
  sub_cobol cblclg "$nistdir/src" NC116A
  sub_cobol cblclg "$nistdir/src" NC117A
  sub_cobol cblclg "$nistdir/src" NC118A
  sub_cobol cblclg "$nistdir/src" NC119A
  sub_cobol cblclg "$nistdir/src" NC120A
  sub_cobol cblclg "$nistdir/src" NC121M
  sub_cobol cblclg "$nistdir/src" NC122A
  sub_cobol cblclg "$nistdir/src" NC123A
  sub_cobol cblclg "$nistdir/src" NC124A
  sub_cobol cblclg "$nistdir/src" NC125A
  sub_cobol cblclg "$nistdir/src" NC126A
  sub_cobol cblclg "$nistdir/src" NC127A
  sub_cobol cblclg "$nistdir/src" NC131A
  sub_cobol cblclg "$nistdir/src" NC132A
  sub_cobol cblclg "$nistdir/src" NC133A
  sub_cobol cblclg "$nistdir/src" NC134A
  sub_cobol cblclg "$nistdir/src" NC135A
  sub_cobol cblclg "$nistdir/src" NC136A
  sub_cobol cblclg "$nistdir/src" NC137A
  sub_cobol cblclg "$nistdir/src" NC138A
  sub_cobol cblclg "$nistdir/src" NC139A
  sub_cobol cblclg "$nistdir/src" NC140A
  sub_cobol cblclg "$nistdir/src" NC141A
  sub_cobol cblclg "$nistdir/src" NC170A
  sub_cobol cblclg "$nistdir/src" NC171A
  sub_cobol cblclg "$nistdir/src" NC172A
  sub_cobol cblclg "$nistdir/src" NC173A
  sub_cobol cblclg "$nistdir/src" NC174A
  sub_cobol cblclg "$nistdir/src" NC175A
  sub_cobol cblclg "$nistdir/src" NC176A
  sub_cobol cblclg "$nistdir/src" NC177A
  sub_cobol cblclg "$nistdir/src" NC201A
  sub_cobol cblclg "$nistdir/src" NC202A
  sub_cobol cblclg "$nistdir/src" NC203A
  sub_cobol cblclg "$nistdir/src" NC204M
  sub_data         "$nistdir/src" NC204M  # intended usage unknown
  sub_cobol cblclg "$nistdir/src" NC205A
  sub_cobol cblclg "$nistdir/src" NC206A
  sub_cobol cblclg "$nistdir/src" NC207A
  sub_cobol cblclg "$nistdir/src" NC208A
  sub_cobol cblclg "$nistdir/src" NC209A
  sub_cobol cblclg "$nistdir/src" NC210A
  sub_cobol cblclg "$nistdir/src" NC211A
  sub_cobol cblclg "$nistdir/src" NC214M
  sub_cobol cblclg "$nistdir/src" NC215A
  sub_cobol cblclg "$nistdir/src" NC216A
  sub_cobol cblclg "$nistdir/src" NC217A
  sub_cobol cblclg "$nistdir/src" NC218A
  sub_cobol cblclg "$nistdir/src" NC219A
  sub_cobol cblclg "$nistdir/src" NC220M
  sub_cobol cblclg "$nistdir/src" NC221A
  sub_cobol cblclg "$nistdir/src" NC222A
  sub_cobol cblclg "$nistdir/src" NC223A
  sub_cobol cblclg "$nistdir/src" NC224A
  sub_cobol cblclg "$nistdir/src" NC225A
  sub_cobol cblclg "$nistdir/src" NC231A
  sub_cobol cblclg "$nistdir/src" NC232A
  sub_cobol cblclg "$nistdir/src" NC233A
  sub_cobol cblclg "$nistdir/src" NC234A
  sub_cobol cblclg "$nistdir/src" NC235A
  sub_cobol cblclg "$nistdir/src" NC236A
  sub_cobol cblclg "$nistdir/src" NC237A
  sub_cobol cblclg "$nistdir/src" NC238A
  sub_cobol cblclg "$nistdir/src" NC239A
  sub_cobol cblclg "$nistdir/src" NC240A
  sub_cobol cblclg "$nistdir/src" NC241A
  sub_cobol cblclg "$nistdir/src" NC242A
  sub_cobol cblclg "$nistdir/src" NC243A
  sub_cobol cblclg "$nistdir/src" NC244A
  sub_cobol cblclg "$nistdir/src" NC245A
  sub_cobol cblclg "$nistdir/src" NC246A
  sub_cobol cblclg "$nistdir/src" NC247A
  sub_cobol cblclg "$nistdir/src" NC248A
  sub_cobol cblclg "$nistdir/src" NC250A
  sub_cobol cblclg "$nistdir/src" NC251A
  sub_cobol cblclg "$nistdir/src" NC252A
  sub_cobol cblclg "$nistdir/src" NC253A
  sub_cobol cblclg "$nistdir/src" NC254A
  sub_cobol cblclg "$nistdir/src" NC302M
  sub_cobol cblclg "$nistdir/src" NC303M
  sub_cobol cblclg "$nistdir/src" NC401M
fi

# OB = Obsolete
if section "${test_OB}"; then
  sub_cobol cblc   "$nistdir/src" OBIC2A
  sub_cobol cblc   "$nistdir/src" OBIC3A
  sub_cobol cblclg "$nistdir/src" OBIC1A
  sub_cobol cblclg "$nistdir/src" OBNC1M
  sub_cobol cblclg "$nistdir/src" OBNC2M
  sub_cobol cblclg "$nistdir/src" OBSQ1A
  sub_cobol cblc   "$nistdir/src" OBSQ4A
  sub_cobol cblc   "$nistdir/src" OBSQ5A
  sub_cobol cblclg "$nistdir/src" OBSQ3A
fi

# RL = Relative I/O
if section "${test_RL}"; then
  sub_cobol cblc   "$nistdir/src" RL102A
  sub_cobol cblc   "$nistdir/src" RL103A
  sub_cobol cblclg "$nistdir/src" RL101A
  sub_cobol cblclg "$nistdir/src" RL104A
  sub_cobol cblclg "$nistdir/src" RL105A
  sub_cobol cblclg "$nistdir/src" RL106A
  sub_cobol cblclg "$nistdir/src" RL107A
  sub_cobol cblc   "$nistdir/src" RL109A
  sub_cobol cblc   "$nistdir/src" RL110A
  sub_cobol cblclg "$nistdir/src" RL108A
  sub_cobol cblclg "$nistdir/src" RL111A
  sub_cobol cblclg "$nistdir/src" RL112A
  sub_cobol cblclg "$nistdir/src" RL113A
  sub_cobol cblclg "$nistdir/src" RL114A
  sub_cobol cblclg "$nistdir/src" RL115A
  sub_cobol cblclg "$nistdir/src" RL116A
  sub_cobol cblclg "$nistdir/src" RL117A
  sub_cobol cblclg "$nistdir/src" RL118A
  sub_cobol cblclg "$nistdir/src" RL119A
  sub_cobol cblc   "$nistdir/src" RL202A
  sub_cobol cblc   "$nistdir/src" RL203A
  sub_cobol cblclg "$nistdir/src" RL201A
  sub_cobol cblclg "$nistdir/src" RL204A
  sub_cobol cblclg "$nistdir/src" RL205A
  sub_cobol cblc   "$nistdir/src" RL207A
  sub_cobol cblc   "$nistdir/src" RL208A
  sub_cobol cblclg "$nistdir/src" RL206A
  sub_cobol cblclg "$nistdir/src" RL209A
  sub_cobol cblclg "$nistdir/src" RL210A
  sub_cobol cblclg "$nistdir/src" RL211A
  sub_cobol cblc   "$nistdir/src" RL213A
  sub_cobol cblclg "$nistdir/src" RL212A
  sub_cobol cblclg "$nistdir/src" RL301M
  sub_cobol cblclg "$nistdir/src" RL302M
  sub_cobol cblclg "$nistdir/src" RL401M
fi

# RW = Report Writer
if section "${test_RW}"; then
  sub_cobol cblclg "$nistdir/src" RW101A
  sub_cobol cblclg "$nistdir/src" RW102A
  sub_cobol cblclg "$nistdir/src" RW103A
  sub_cobol cblclg "$nistdir/src" RW104A
  sub_cobol cblclg "$nistdir/src" RW301M
  sub_cobol cblclg "$nistdir/src" RW302M
fi

# SG = Segmentation
if section "${test_SG}"; then
  sub_cobol cblclg "$nistdir/src" SG101A
  sub_cobol cblclg "$nistdir/src" SG102A
  sub_cobol cblclg "$nistdir/src" SG103A
  sub_cobol cblclg "$nistdir/src" SG104A
  sub_cobol cblclg "$nistdir/src" SG105A
  sub_cobol cblclg "$nistdir/src" SG106A
  sub_cobol cblclg "$nistdir/src" SG201A
  sub_cobol cblclg "$nistdir/src" SG202A
  sub_cobol cblclg "$nistdir/src" SG203A
  sub_cobol cblclg "$nistdir/src" SG204A
  sub_cobol cblclg "$nistdir/src" SG302M
  sub_cobol cblclg "$nistdir/src" SG303M
  sub_cobol cblclg "$nistdir/src" SG401M
fi

# SM = Source Manipulation
if section "${test_SM}"; then
  sub_cobol cblc   "$nistdir/src" SM102A
  sub_cobol cblclg "$nistdir/src" SM101A
  sub_cobol cblc   "$nistdir/src" SM104A
  sub_cobol cblclg "$nistdir/src" SM103A
  sub_cobol cblclg "$nistdir/src" SM105A
  sub_cobol cblclg "$nistdir/src" SM106A
  sub_cobol cblclg "$nistdir/src" SM107A
  sub_cobol cblc   "$nistdir/src" SM202A
  sub_cobol cblclg "$nistdir/src" SM201A
  sub_cobol cblc   "$nistdir/src" SM204A
  sub_cobol cblclg "$nistdir/src" SM203A
  sub_cobol cblclg "$nistdir/src" SM205A
  sub_cobol cblclg "$nistdir/src" SM206A
  sub_cobol cblclg "$nistdir/src" SM207A
  sub_cobol cblclg "$nistdir/src" SM208A
  sub_cobol cblclg "$nistdir/src" SM301M
  sub_cobol cblclg "$nistdir/src" SM401M
fi

# SQ = Sequential I/O
if section "${test_SQ}"; then
  sub_cobol cblclg "$nistdir/src" SQ101M
  sub_cobol cblclg "$nistdir/z390" SQ101M NOCOUNT  # instead of the original
  sub_cobol cblclg "$nistdir/src" SQ102A
  sub_cobol cblclg "$nistdir/src" SQ103A
  sub_cobol cblclg "$nistdir/src" SQ104A
  sub_cobol cblclg "$nistdir/src" SQ105A
  sub_cobol cblclg "$nistdir/src" SQ106A
  sub_cobol cblclg "$nistdir/src" SQ107A
  sub_cobol cblclg "$nistdir/src" SQ108A
  sub_cobol cblclg "$nistdir/src" SQ109M
  sub_cobol cblclg "$nistdir/src" SQ110M
  sub_cobol cblclg "$nistdir/src" SQ111A
  sub_cobol cblclg "$nistdir/src" SQ112A
  sub_cobol cblclg "$nistdir/src" SQ113A
  sub_cobol cblclg "$nistdir/src" SQ114A
  sub_cobol cblclg "$nistdir/src" SQ115A
  sub_cobol cblclg "$nistdir/src" SQ116A
  sub_cobol cblclg "$nistdir/src" SQ117A
  sub_cobol cblclg "$nistdir/src" SQ121A
  sub_cobol cblclg "$nistdir/src" SQ122A
  sub_cobol cblclg "$nistdir/src" SQ123A
  sub_cobol cblclg "$nistdir/src" SQ124A
  sub_cobol cblclg "$nistdir/src" SQ125A
  sub_cobol cblclg "$nistdir/src" SQ126A
  sub_cobol cblclg "$nistdir/src" SQ127A
  sub_cobol cblclg "$nistdir/src" SQ128A
  sub_cobol cblclg "$nistdir/src" SQ129A
  sub_cobol cblclg "$nistdir/src" SQ130A
  sub_cobol cblclg "$nistdir/src" SQ131A
  sub_cobol cblclg "$nistdir/src" SQ132A
  sub_cobol cblclg "$nistdir/src" SQ133A
  sub_cobol cblclg "$nistdir/src" SQ134A
  sub_cobol cblclg "$nistdir/src" SQ135A
  sub_cobol cblclg "$nistdir/src" SQ136A
  sub_cobol cblclg "$nistdir/src" SQ137A
  sub_cobol cblclg "$nistdir/src" SQ138A
  sub_cobol cblclg "$nistdir/src" SQ139A
  sub_cobol cblclg "$nistdir/src" SQ140A
  sub_cobol cblclg "$nistdir/src" SQ141A
  sub_cobol cblclg "$nistdir/src" SQ142A
  sub_cobol cblclg "$nistdir/src" SQ143A
  sub_cobol cblclg "$nistdir/src" SQ144A
  sub_cobol cblclg "$nistdir/src" SQ146A
  sub_cobol cblclg "$nistdir/src" SQ147A
  sub_cobol cblclg "$nistdir/src" SQ148A
  sub_cobol cblclg "$nistdir/src" SQ149A
  sub_cobol cblclg "$nistdir/src" SQ150A
  sub_cobol cblclg "$nistdir/src" SQ151A
  sub_cobol cblclg "$nistdir/src" SQ152A
  sub_cobol cblclg "$nistdir/src" SQ153A
  sub_cobol cblclg "$nistdir/src" SQ154A
  sub_cobol cblclg "$nistdir/src" SQ155A
  sub_cobol cblclg "$nistdir/src" SQ156A
  sub_cobol cblclg "$nistdir/src" SQ201M
  sub_cobol cblc   "$nistdir/src" SQ203A
  sub_cobol cblclg "$nistdir/src" SQ202A
  sub_cobol cblclg "$nistdir/src" SQ204A
  sub_cobol cblclg "$nistdir/src" SQ205A
  sub_cobol cblclg "$nistdir/src" SQ206A
  sub_cobol cblclg "$nistdir/src" SQ207M
  sub_cobol cblclg "$nistdir/src" SQ208M
  sub_cobol cblclg "$nistdir/src" SQ209M
  sub_cobol cblclg "$nistdir/src" SQ210M
  sub_cobol cblclg "$nistdir/src" SQ211A
  sub_cobol cblclg "$nistdir/src" SQ212A
  sub_cobol cblclg "$nistdir/src" SQ213A
  sub_cobol cblclg "$nistdir/src" SQ214A
  sub_cobol cblclg "$nistdir/src" SQ215A
  sub_cobol cblclg "$nistdir/src" SQ216A
  sub_cobol cblclg "$nistdir/src" SQ217A
  sub_cobol cblclg "$nistdir/src" SQ218A
  sub_cobol cblclg "$nistdir/src" SQ219A
  sub_cobol cblclg "$nistdir/src" SQ220A
  sub_cobol cblclg "$nistdir/src" SQ221A
  sub_cobol cblclg "$nistdir/src" SQ222A
  sub_cobol cblclg "$nistdir/src" SQ223A
  sub_cobol cblclg "$nistdir/src" SQ224A
  sub_cobol cblclg "$nistdir/src" SQ225A
  sub_cobol cblclg "$nistdir/src" SQ226A
  sub_cobol cblclg "$nistdir/src" SQ227A
  sub_cobol cblclg "$nistdir/src" SQ228A
  sub_cobol cblclg "$nistdir/src" SQ229A
  sub_cobol cblclg "$nistdir/src" SQ230A
  sub_cobol cblclg "$nistdir/src" SQ302M
  sub_cobol cblclg "$nistdir/src" SQ303M
  sub_cobol cblclg "$nistdir/src" SQ401M
fi

# ST = Sort / Merge
if section "${test_ST}"; then
  sub_cobol cblc   "$nistdir/src" ST102A
  sub_cobol cblc   "$nistdir/src" ST103A
  sub_cobol cblclg "$nistdir/src" ST101A
  sub_cobol cblc   "$nistdir/src" ST105A
  sub_cobol cblclg "$nistdir/src" ST104A
  sub_cobol cblc   "$nistdir/src" ST107A
  sub_cobol cblclg "$nistdir/src" ST106A
  sub_cobol cblclg "$nistdir/src" ST108A
  sub_cobol cblc   "$nistdir/src" ST110A
  sub_cobol cblc   "$nistdir/src" ST111A
  sub_cobol cblclg "$nistdir/src" ST109A
  sub_cobol cblc   "$nistdir/src" ST113M
  sub_cobol cblc   "$nistdir/src" ST114M
  sub_cobol cblclg "$nistdir/src" ST112M
  sub_cobol cblc   "$nistdir/src" ST116A
  sub_cobol cblc   "$nistdir/src" ST117A
  sub_cobol cblclg "$nistdir/src" ST115A
  sub_cobol cblclg "$nistdir/src" ST118A
  sub_cobol cblc   "$nistdir/src" ST120A
  sub_cobol cblc   "$nistdir/src" ST121A
  sub_cobol cblclg "$nistdir/src" ST119A
  sub_cobol cblc   "$nistdir/src" ST123A
  sub_cobol cblc   "$nistdir/src" ST124A
  sub_cobol cblclg "$nistdir/src" ST122A
  sub_cobol cblc   "$nistdir/src" ST126A
  sub_cobol cblclg "$nistdir/src" ST125A
  sub_cobol cblclg "$nistdir/src" ST127A
  sub_cobol cblclg "$nistdir/src" ST131A
  sub_cobol cblclg "$nistdir/src" ST132A
  sub_cobol cblclg "$nistdir/src" ST133A
  sub_cobol cblclg "$nistdir/src" ST134A
  sub_cobol cblclg "$nistdir/src" ST135A
  sub_cobol cblclg "$nistdir/src" ST136A
  sub_cobol cblclg "$nistdir/src" ST137A
  sub_cobol cblclg "$nistdir/src" ST139A
  sub_cobol cblclg "$nistdir/src" ST140A
  sub_cobol cblclg "$nistdir/src" ST144A
  sub_cobol cblclg "$nistdir/src" ST146A
  sub_cobol cblclg "$nistdir/src" ST147A
  sub_cobol cblclg "$nistdir/src" ST301M
fi

{
  echo "$0 $copymbr copy members found and $copyerr not found"
  echo "$0 $datambr data members found and $dataerr not found"
  echo "$0 $tested compiles completed:         "
  echo "$0 - okay RC=0 for $testgood tests     "
  echo "$0 - warn RC=4 for $testwarn tests     "
  echo "$0 - err  RC=8 for $testerr tests      "
  echo "$0 - any other for $testfail tests     "
  echo "$0 - and $nocount not NIST             "
  echo "$0 z390 repository is at hash $z390_LVL"
  echo "$0 NIST repository is at hash $NIST_LVL"
  echo "$0 Date: $(date '+%d/%m/%Y %H:%M:%S')  "
} > "$summary"

cat "$summary" >> "$allerr"
echo .
cat "$summary"
echo .
echo "See $sort_log for complete list of all messages"

cp "$allerr" "$full_log"
myRC=$?
if [ "$myRC" -gt "$NIST_RC" ]; then NIST_RC=$myRC; fi

sort_plus17 "$allerr" "$sort_log"
myRC=$?
if [ "$myRC" -gt "$NIST_RC" ]; then NIST_RC=$myRC; fi

edit_full_log "$full_log"

echo .
echo "final return code is $NIST_RC"
finish
