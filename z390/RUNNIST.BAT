@if /I "%1" == "tron" (echo on) else (echo off)
rem run z390 zcobol sample regression tests

setlocal
if /I "%1" == "tron" (set z_TraceMode=tron
                      shift /1
              ) else (if /I "%1" == "troff" (set z_TraceMode=troff
                                             shift /1
                                     ) else (set z_TraceMode=)
                      )
set /A z_NestLevel=%z_NestLevel%+1
set NIST_RC=0
rem ----- Lvl(%z_NestLevel%) Start %0 %1 %2 %3 %4 %5 %6 %7 %8 %9

rem -- *************************************************************
rem -- 
rem -- This script runs the NIST cobol test suite using z390 zCobol
rem -- which can be found in github repository z390development/z390
rem -- 
rem -- This bat script reflects the current status of the adoption
rem -- process of the NIST test suite in z390 / zCobol.
rem -- We have found 5 sets of the NIST test suite. None of them seem
rem -- to be ultimately authoritative as the NIST itself has abandoned
rem -- the entire test suite.
rem -- 
rem -- We are moving forward one program at a time, comparing the program
rem -- versions available and fixing any breakages in zCobol as we go.
rem -- That is, most compiles end with RC=8 - there are tons of issues
rem -- to be resolved. What we fix is where the compile process ends
rem -- abnormally, e.g. with a java exception and a stack trace.
rem -- 
rem -- Long story short: we reconcile source versions, and fix compiler breakage.
rem -- All other issues are left for future maintenance.
rem -- 
rem -- *************************************************************

pushd %~dps0..
if %1. == . goto help

set parmrc=0
:parmloop
if /I %1. EQU   .       goto parmdone
if /I %1. EQU ALT.     (set test_ALT=Y&&goto parmnotall)
if /I %1. EQU CM.      (set test_CM=Y&&goto parmnotall)
if /I %1. EQU DB.      (set test_DB=Y&&goto parmnotall)
if /I %1. EQU EX.      (set test_EX=Y&&goto parmnotall)
if /I %1. EQU IC.      (set test_IC=Y&&goto parmnotall)
if /I %1. EQU IF.      (set test_IF=Y&&goto parmnotall)
if /I %1. EQU IX.      (set test_IX=Y&&goto parmnotall)
if /I %1. EQU K.       (set test_K=Y&&goto parmnotall)
if /I %1. EQU NC.      (set test_NC=Y&&goto parmnotall)
if /I %1. EQU OB.      (set test_OB=Y&&goto parmnotall)
if /I %1. EQU RL.      (set test_RL=Y&&goto parmnotall)
if /I %1. EQU RW.      (set test_RW=Y&&goto parmnotall)
if /I %1. EQU SG.      (set test_SG=Y&&goto parmnotall)
if /I %1. EQU SM.      (set test_SM=Y&&goto parmnotall)
if /I %1. EQU SQ.      (set test_SQ=Y&&goto parmnotall)
if /I %1. EQU ST.      (set test_ST=Y&&goto parmnotall)
if /I %1. EQU cleanup. (set cleanup=Y&&goto parmnotall)
rem -- should be the path to z390
if exist %1\bat\CBLCLG.BAT (set z390dir=%1&&goto parmnext)
echo %0 Unknown parameter: %1
set parmrc=8
:parmnotall
set test_all=N
:parmnext
shift /1
goto parmloop
:parmdone
rem -- check for prior errors and validate path to z390
rem -- extract current hash ID from NIST and z390 repositories
set nistdir=%CD%
for /f "delims=" %%i in ('git rev-parse HEAD') do set NIST_LVL=%%i || goto no_nistrepo

if %parmrc%   EQU 8  goto return
if %cleanup%. EQU Y. goto cleanup
if %z390dir%. EQU .  goto help
if not exist %z390dir%\z390.jar goto help
rem -- switch to z390 directory
cd %z390dir%
for /f "delims=" %%i in ('git rev-parse HEAD') do set z390_LVL=%%i || goto no_z390repo

rem --
rem -- clear leftovers from prior runs
:cleanup
echo Cleaning up...
call :sub_clean %nistdir%\src
call :sub_clean %nistdir%\z390
echo Cleanup complete
if %cleanup%. EQU Y. goto return

rem --
rem -- initialize result counters
set /A copymbr  = 0
set /A copyerr  = 0
set /A datambr  = 0
set /A dataerr  = 0
set /A nocount  = 0
set /A tested   = 0
set /A testgood = 0
set /A testwarn = 0
set /A testerr  = 0
set /A testfail = 0

rem --
rem -- ALT copy members and purpose:
if /I %test_all%. EQU N. if /I %test_ALT%. NEQ Y. goto skip_ALT
call :sub_copy CBL    %nistdir%\src ALTL1 || rem intended for use by EXEC85
call :sub_copy CBL    %nistdir%\src ALTLB || rem intended for use by EXEC85
:skip_ALT

rem --
rem -- K* copy members
if /I %test_all%. EQU N. if /I %test_K%. NEQ Y. goto skip_K
call :sub_copy CBL    %nistdir%\src K101A
call :sub_copy CBL    %nistdir%\src K1DAA
call :sub_copy CBL    %nistdir%\src K1FDA
call :sub_copy CBL    %nistdir%\src K1P01
call :sub_copy CBL    %nistdir%\src K1PRA
call :sub_copy CBL    %nistdir%\src K1PRB
call :sub_copy CBL    %nistdir%\src K1PRC
call :sub_copy CBL    %nistdir%\src K1SEA
call :sub_copy CBL    %nistdir%\src K1W01
call :sub_copy CBL    %nistdir%\src K1W02
call :sub_copy CBL    %nistdir%\src K1W03
call :sub_copy CBL    %nistdir%\src K1W04
call :sub_copy CBL    %nistdir%\src K1WKA
call :sub_copy CBL    %nistdir%\src K1WKB
call :sub_copy CBL    %nistdir%\src K1WKC
call :sub_copy CBL    %nistdir%\src K1WKY
call :sub_copy CBL    %nistdir%\src K1WKZ
call :sub_copy CBL    %nistdir%\src K2PRA
call :sub_copy CBL    %nistdir%\src K2SEA
call :sub_copy CBL    %nistdir%\src K3FCA
call :sub_copy CBL    %nistdir%\src K3FCB
call :sub_copy CBL    %nistdir%\src K3IOA
call :sub_copy CBL    %nistdir%\src K3IOB
call :sub_copy CBL    %nistdir%\src K3LGE
call :sub_copy CBL    %nistdir%\src K3OCA
call :sub_copy CBL    %nistdir%\src K3SCA
call :sub_copy CBL    %nistdir%\src K3SML
call :sub_copy CBL    %nistdir%\src K3SNA
call :sub_copy CBL    %nistdir%\src K3SNB
call :sub_copy CBL    %nistdir%\src K4NTA || rem defined but never used (on purpose)
call :sub_copy CBL    %nistdir%\src K501A
call :sub_copy CBL    %nistdir%\src K501B
call :sub_copy CBL    %nistdir%\src K5SDA
call :sub_copy CBL    %nistdir%\src K5SDB
call :sub_copy CBL    %nistdir%\src K6SCA
call :sub_copy CBL    %nistdir%\src K7SEA
call :sub_copy CBL    %nistdir%\src KK208A
call :sub_copy CBL    %nistdir%\src KP001
call :sub_copy CBL    %nistdir%\src KP002
call :sub_copy CBL    %nistdir%\src KP003
call :sub_copy CBL    %nistdir%\src KP004
call :sub_copy CBL    %nistdir%\src KP005
call :sub_copy CBL    %nistdir%\src KP006
call :sub_copy CBL    %nistdir%\src KP007
call :sub_copy CBL    %nistdir%\src KP008
call :sub_copy CBL    %nistdir%\src KP009
call :sub_copy CBL    %nistdir%\src KP010 || rem not used but probably belonged with SM206A
call :sub_copy CBL    %nistdir%\src KSM31
call :sub_copy CBL    %nistdir%\src KSM41
:skip_K

rem --
rem -- EX = Executive module
if /I %test_all%. EQU N. if /I %test_EX%. NEQ Y. goto skip_EX
call :sub_cobol CBLCLG %nistdir%\src EXEC85
:skip_EX

rem --
rem -- CM = Communications Module
if /I %test_all%. EQU N. if /I %test_CM%. NEQ Y. goto skip_CM
call :sub_cobol CBLCLG %nistdir%\src CM101M
call :sub_cobol CBLCLG %nistdir%\src CM102M
call :sub_cobol CBLCLG %nistdir%\src CM103M
call :sub_cobol CBLCLG %nistdir%\src CM104M
call :sub_cobol CBLCLG %nistdir%\src CM105M
call :sub_cobol CBLCLG %nistdir%\src CM201M
call :sub_cobol CBLCLG %nistdir%\src CM202M
call :sub_cobol CBLCLG %nistdir%\src CM303M
call :sub_cobol CBLCLG %nistdir%\src CM401M
:skip_CM

rem --
rem -- DB = Debug module
if /I %test_all%. EQU N. if /I %test_DB%. NEQ Y. goto skip_DB
call :sub_cobol CBLCLG %nistdir%\src DB101A
call :sub_cobol CBLCLG %nistdir%\src DB102A
call :sub_cobol CBLCLG %nistdir%\src DB103M
call :sub_cobol CBLCLG %nistdir%\src DB104A
call :sub_cobol CBLCLG %nistdir%\src DB105A
call :sub_cobol CBLCLG %nistdir%\src DB201A
call :sub_cobol CBLCLG %nistdir%\src DB202A
call :sub_cobol CBLCLG %nistdir%\src DB203A
call :sub_cobol CBLCLG %nistdir%\src DB204A
call :sub_cobol CBLCLG %nistdir%\src DB205A
call :sub_cobol CBLCLG %nistdir%\src DB301M
call :sub_cobol CBLCLG %nistdir%\src DB302M
call :sub_cobol CBLCLG %nistdir%\src DB303M
call :sub_cobol CBLCLG %nistdir%\src DB304M
call :sub_cobol CBLCLG %nistdir%\src DB305M
:skip_DB

rem --
rem -- IC = Inter-Program Communication - subprograms must be compiled before each main program!
if /I %test_all%. EQU N. if /I %test_IC%. NEQ Y. goto skip_IC
call :sub_cobol CBLC   %nistdir%\src IC102A
call :sub_cobol CBLCLG %nistdir%\src IC101A
call :sub_cobol CBLC   %nistdir%\src IC104A
call :sub_cobol CBLC   %nistdir%\src IC105A
call :sub_cobol CBLCLG %nistdir%\src IC103A
call :sub_cobol CBLC   %nistdir%\src IC107A
call :sub_cobol CBLCLG %nistdir%\src IC106A
call :sub_cobol CBLC   %nistdir%\src IC109A
call :sub_cobol CBLC   %nistdir%\src IC110A
call :sub_cobol CBLC   %nistdir%\src IC111A
call :sub_cobol CBLCLG %nistdir%\src IC108A
call :sub_cobol CBLC   %nistdir%\src IC113A
call :sub_cobol CBLCLG %nistdir%\src IC112A || rem fails to generate the call to IC113A
call :sub_cobol CBLC   %nistdir%\src IC115A
call :sub_cobol CBLCLG %nistdir%\src IC114A
call :sub_cobol CBLC   %nistdir%\src IC117M
call :sub_cobol CBLC   %nistdir%\src IC118M
call :sub_cobol CBLCLG %nistdir%\src IC116M
call :sub_cobol CBLC   %nistdir%\src IC202A
call :sub_cobol CBLCLG %nistdir%\src IC201A
call :sub_cobol CBLC   %nistdir%\src IC204A
call :sub_cobol CBLC   %nistdir%\src IC205A
call :sub_cobol CBLC   %nistdir%\src IC206A
call :sub_cobol CBLCLG %nistdir%\src IC203A
call :sub_cobol CBLC   %nistdir%\src IC208A
call :sub_cobol CBLCLG %nistdir%\src IC207A
call :sub_cobol CBLC   %nistdir%\src IC210A
call :sub_cobol CBLC   %nistdir%\src IC211A
call :sub_cobol CBLC   %nistdir%\src IC212A
call :sub_cobol CBLCLG %nistdir%\src IC209A
call :sub_cobol CBLC   %nistdir%\src IC214A
call :sub_cobol CBLC   %nistdir%\src IC215A
call :sub_cobol CBLCLG %nistdir%\src IC213A
call :sub_cobol CBLC   %nistdir%\src IC217A
call :sub_cobol CBLCLG %nistdir%\src IC216A
call :sub_cobol CBLCLG %nistdir%\src  IC222A
call :sub_cobol CBLC   %nistdir%\z390 IC222A1 NOCOUNT || rem instead of the original
call :sub_cobol CBLCLG %nistdir%\z390 IC222A  NOCOUNT || rem instead of the original
call :sub_cobol CBLCLG %nistdir%\src  IC223A
call :sub_cobol CBLC   %nistdir%\z390 IC223A1 NOCOUNT || rem instead of the original
call :sub_cobol CBLCLG %nistdir%\z390 IC223A  NOCOUNT || rem instead of the original
call :sub_cobol CBLCLG %nistdir%\src  IC224A
call :sub_cobol CBLC   %nistdir%\z390 IC224A1 NOCOUNT || rem instead of the original
call :sub_cobol CBLCLG %nistdir%\z390 IC224A  NOCOUNT || rem instead of the original
call :sub_cobol CBLCLG %nistdir%\src  IC225A
call :sub_cobol CBLC   %nistdir%\z390 IC225A1 NOCOUNT || rem instead of the original
call :sub_cobol CBLCLG %nistdir%\z390 IC225A  NOCOUNT || rem instead of the original
call :sub_cobol CBLCLG %nistdir%\src  IC226A
call :sub_cobol CBLC   %nistdir%\z390 IC226A1 NOCOUNT || rem instead of the original
call :sub_cobol CBLCLG %nistdir%\z390 IC226A  NOCOUNT || rem instead of the original
call :sub_cobol CBLCLG %nistdir%\src  IC227A
call :sub_cobol CBLC   %nistdir%\z390 IC227A1 NOCOUNT || rem instead of the original
call :sub_cobol CBLCLG %nistdir%\z390 IC227A  NOCOUNT || rem instead of the original
call :sub_cobol CBLCLG %nistdir%\src  IC228A
call :sub_cobol CBLC   %nistdir%\z390 IC228A1 NOCOUNT || rem instead of the original
call :sub_cobol CBLCLG %nistdir%\z390 IC228A  NOCOUNT || rem instead of the original
call :sub_cobol CBLCLG %nistdir%\src  IC233A
call :sub_cobol CBLC   %nistdir%\z390 IC233A1 NOCOUNT || rem instead of the original
call :sub_cobol CBLCLG %nistdir%\z390 IC233A  NOCOUNT || rem instead of the original
call :sub_cobol CBLCLG %nistdir%\src  IC234A
call :sub_cobol CBLC   %nistdir%\z390 IC234A1 NOCOUNT || rem instead of the original
call :sub_cobol CBLC   %nistdir%\z390 IC234A2 NOCOUNT || rem instead of the original
call :sub_cobol CBLC   %nistdir%\z390 IC234A3 NOCOUNT || rem instead of the original
call :sub_cobol CBLCLG %nistdir%\z390 IC234A  NOCOUNT || rem instead of the original
call :sub_cobol CBLCLG %nistdir%\src  IC235A
call :sub_cobol CBLC   %nistdir%\z390 IC235A1 NOCOUNT || rem instead of the original
call :sub_cobol CBLC   %nistdir%\z390 IC235A2 NOCOUNT || rem instead of the original
call :sub_cobol CBLCLG %nistdir%\z390 IC235A  NOCOUNT || rem instead of the original
call :sub_cobol CBLCLG %nistdir%\src  IC237A
call :sub_cobol CBLC   %nistdir%\z390 IC237A1 NOCOUNT || rem instead of the original
call :sub_cobol CBLCLG %nistdir%\z390 IC237A  NOCOUNT || rem instead of the original
call :sub_cobol CBLCLG %nistdir%\src  IC401M
:skip_IC

rem --
rem -- IF = Intrinsic Functions
if /I %test_all%. EQU N. if /I %test_IF%. NEQ Y. goto skip_IF
call :sub_cobol CBLCLG %nistdir%\src IF101A
call :sub_cobol CBLCLG %nistdir%\src IF102A
call :sub_cobol CBLCLG %nistdir%\src IF103A
call :sub_cobol CBLCLG %nistdir%\src IF104A
call :sub_cobol CBLCLG %nistdir%\src IF105A
call :sub_cobol CBLCLG %nistdir%\src IF106A
call :sub_cobol CBLCLG %nistdir%\src IF107A
call :sub_cobol CBLCLG %nistdir%\src IF108A
call :sub_cobol CBLCLG %nistdir%\src IF109A
call :sub_cobol CBLCLG %nistdir%\src IF110A
call :sub_cobol CBLCLG %nistdir%\src IF111A
call :sub_cobol CBLCLG %nistdir%\src IF112A
call :sub_cobol CBLCLG %nistdir%\src IF113A
call :sub_cobol CBLCLG %nistdir%\src IF114A
call :sub_cobol CBLCLG %nistdir%\src IF115A
call :sub_cobol CBLCLG %nistdir%\src IF116A
call :sub_cobol CBLCLG %nistdir%\src IF117A
call :sub_cobol CBLCLG %nistdir%\src IF118A
call :sub_cobol CBLCLG %nistdir%\src IF119A
call :sub_cobol CBLCLG %nistdir%\src IF120A
call :sub_cobol CBLCLG %nistdir%\src IF121A
call :sub_cobol CBLCLG %nistdir%\src IF122A
call :sub_cobol CBLCLG %nistdir%\src IF123A
call :sub_cobol CBLCLG %nistdir%\src IF124A
call :sub_cobol CBLCLG %nistdir%\src IF125A
call :sub_cobol CBLCLG %nistdir%\src IF126A
call :sub_cobol CBLCLG %nistdir%\src IF127A
call :sub_cobol CBLCLG %nistdir%\src IF128A
call :sub_cobol CBLCLG %nistdir%\src IF129A
call :sub_cobol CBLCLG %nistdir%\src IF130A
call :sub_cobol CBLCLG %nistdir%\src IF131A
call :sub_cobol CBLCLG %nistdir%\src IF132A
call :sub_cobol CBLCLG %nistdir%\src IF133A
call :sub_cobol CBLCLG %nistdir%\src IF134A
call :sub_cobol CBLCLG %nistdir%\src IF135A
call :sub_cobol CBLCLG %nistdir%\src IF136A
call :sub_cobol CBLCLG %nistdir%\src IF137A
call :sub_cobol CBLCLG %nistdir%\src IF138A
call :sub_cobol CBLCLG %nistdir%\src IF139A
call :sub_cobol CBLCLG %nistdir%\src IF140A
call :sub_cobol CBLCLG %nistdir%\src IF141A
call :sub_cobol CBLCLG %nistdir%\src IF142A
call :sub_cobol CBLCLG %nistdir%\src IF401M
call :sub_cobol CBLCLG %nistdir%\src IF402M
call :sub_cobol CBLCLG %nistdir%\src IF403M
:skip_IF

rem --
rem -- IX = Indexed I/O
if /I %test_all%. EQU N. if /I %test_IX%. NEQ Y. goto skip_IX
call :sub_cobol CBLC   %nistdir%\src IX102A
call :sub_cobol CBLC   %nistdir%\src IX103A
call :sub_cobol CBLCLG %nistdir%\src IX101A
call :sub_cobol CBLCLG %nistdir%\src IX104A
call :sub_cobol CBLCLG %nistdir%\src IX105A
call :sub_cobol CBLCLG %nistdir%\src IX106A
call :sub_cobol CBLCLG %nistdir%\src IX107A
call :sub_cobol CBLCLG %nistdir%\src IX108A
call :sub_cobol CBLC   %nistdir%\src IX110A
call :sub_cobol CBLC   %nistdir%\src IX111A
call :sub_cobol CBLCLG %nistdir%\src IX109A
call :sub_cobol CBLCLG %nistdir%\src IX112A
call :sub_cobol CBLC   %nistdir%\src IX114A
call :sub_cobol CBLC   %nistdir%\src IX115A
call :sub_cobol CBLC   %nistdir%\src IX116A
call :sub_cobol CBLC   %nistdir%\src IX117A
call :sub_cobol CBLC   %nistdir%\src IX118A
call :sub_cobol CBLC   %nistdir%\src IX119A
call :sub_cobol CBLC   %nistdir%\src IX120A
call :sub_cobol CBLCLG %nistdir%\src IX113A
call :sub_cobol CBLCLG %nistdir%\src IX121A
call :sub_cobol CBLC   %nistdir%\src IX202A
call :sub_cobol CBLC   %nistdir%\src IX203A
call :sub_cobol CBLCLG %nistdir%\src IX201A
call :sub_cobol CBLCLG %nistdir%\src IX204A
call :sub_cobol CBLCLG %nistdir%\src IX205A
call :sub_cobol CBLCLG %nistdir%\src IX206A
call :sub_cobol CBLCLG %nistdir%\src IX207A
call :sub_cobol CBLCLG %nistdir%\src IX208A
call :sub_cobol CBLCLG %nistdir%\src IX209A
call :sub_cobol CBLCLG %nistdir%\src IX210A
call :sub_cobol CBLCLG %nistdir%\src IX211A
call :sub_cobol CBLCLG %nistdir%\src IX212A
call :sub_cobol CBLCLG %nistdir%\src IX213A
call :sub_cobol CBLCLG %nistdir%\src IX214A
call :sub_cobol CBLCLG %nistdir%\src IX215A
call :sub_cobol CBLCLG %nistdir%\src IX216A
call :sub_cobol CBLCLG %nistdir%\src IX217A
call :sub_cobol CBLCLG %nistdir%\src IX218A
call :sub_cobol CBLCLG %nistdir%\src IX301M
call :sub_cobol CBLCLG %nistdir%\src IX302M
call :sub_cobol CBLCLG %nistdir%\src IX401M
:skip_IX


rem --
rem -- NC = Nucleus
if /I %test_all%. EQU N. if /I %test_NC%. NEQ Y. goto skip_NC
call :sub_cobol CBLCLG %nistdir%\src NC101A
call :sub_cobol CBLCLG %nistdir%\src NC102A
call :sub_cobol CBLCLG %nistdir%\src NC103A
call :sub_cobol CBLCLG %nistdir%\src NC104A
call :sub_cobol CBLCLG %nistdir%\src NC105A
call :sub_cobol CBLCLG %nistdir%\src NC106A
call :sub_cobol CBLCLG %nistdir%\src NC107A
call :sub_cobol CBLCLG %nistdir%\src NC108M
call :sub_data  CBL    %nistdir%\src NC109M || rem intended usage unknown
call :sub_cobol CBLCLG %nistdir%\src NC109M
call :sub_cobol CBLCLG %nistdir%\src NC110M
call :sub_cobol CBLCLG %nistdir%\src NC111A
call :sub_cobol CBLCLG %nistdir%\src NC112A
call :sub_cobol CBLCLG %nistdir%\src NC113M
call :sub_cobol CBLCLG %nistdir%\src NC114M
call :sub_cobol CBLCLG %nistdir%\src NC115A
call :sub_cobol CBLCLG %nistdir%\src NC116A
call :sub_cobol CBLCLG %nistdir%\src NC117A
call :sub_cobol CBLCLG %nistdir%\src NC118A
call :sub_cobol CBLCLG %nistdir%\src NC119A
call :sub_cobol CBLCLG %nistdir%\src NC120A
call :sub_cobol CBLCLG %nistdir%\src NC121M
call :sub_cobol CBLCLG %nistdir%\src NC122A
call :sub_cobol CBLCLG %nistdir%\src NC123A
call :sub_cobol CBLCLG %nistdir%\src NC124A
call :sub_cobol CBLCLG %nistdir%\src NC125A
call :sub_cobol CBLCLG %nistdir%\src NC126A
call :sub_cobol CBLCLG %nistdir%\src NC127A
call :sub_cobol CBLCLG %nistdir%\src NC131A
call :sub_cobol CBLCLG %nistdir%\src NC132A
call :sub_cobol CBLCLG %nistdir%\src NC133A
call :sub_cobol CBLCLG %nistdir%\src NC134A
call :sub_cobol CBLCLG %nistdir%\src NC135A
call :sub_cobol CBLCLG %nistdir%\src NC136A
call :sub_cobol CBLCLG %nistdir%\src NC137A
call :sub_cobol CBLCLG %nistdir%\src NC138A
call :sub_cobol CBLCLG %nistdir%\src NC139A
call :sub_cobol CBLCLG %nistdir%\src NC140A
call :sub_cobol CBLCLG %nistdir%\src NC141A
call :sub_cobol CBLCLG %nistdir%\src NC170A
call :sub_cobol CBLCLG %nistdir%\src NC171A
call :sub_cobol CBLCLG %nistdir%\src NC172A
call :sub_cobol CBLCLG %nistdir%\src NC173A
call :sub_cobol CBLCLG %nistdir%\src NC174A
call :sub_cobol CBLCLG %nistdir%\src NC175A
call :sub_cobol CBLCLG %nistdir%\src NC176A
call :sub_cobol CBLCLG %nistdir%\src NC177A
call :sub_cobol CBLCLG %nistdir%\src NC201A
call :sub_cobol CBLCLG %nistdir%\src NC202A
call :sub_cobol CBLCLG %nistdir%\src NC203A
call :sub_cobol CBLCLG %nistdir%\src NC204M
call :sub_data  CBL    %nistdir%\src NC204M || rem intended usage unknown
call :sub_cobol CBLCLG %nistdir%\src NC205A
call :sub_cobol CBLCLG %nistdir%\src NC206A
call :sub_cobol CBLCLG %nistdir%\src NC207A
call :sub_cobol CBLCLG %nistdir%\src NC208A
call :sub_cobol CBLCLG %nistdir%\src NC209A
call :sub_cobol CBLCLG %nistdir%\src NC210A
call :sub_cobol CBLCLG %nistdir%\src NC211A
call :sub_cobol CBLCLG %nistdir%\src NC214M
call :sub_cobol CBLCLG %nistdir%\src NC215A
call :sub_cobol CBLCLG %nistdir%\src NC216A
call :sub_cobol CBLCLG %nistdir%\src NC217A
call :sub_cobol CBLCLG %nistdir%\src NC218A
call :sub_cobol CBLCLG %nistdir%\src NC219A
call :sub_cobol CBLCLG %nistdir%\src NC220M
call :sub_cobol CBLCLG %nistdir%\src NC221A
call :sub_cobol CBLCLG %nistdir%\src NC222A
call :sub_cobol CBLCLG %nistdir%\src NC223A
call :sub_cobol CBLCLG %nistdir%\src NC224A
call :sub_cobol CBLCLG %nistdir%\src NC225A
call :sub_cobol CBLCLG %nistdir%\src NC231A
call :sub_cobol CBLCLG %nistdir%\src NC232A
call :sub_cobol CBLCLG %nistdir%\src NC233A
call :sub_cobol CBLCLG %nistdir%\src NC234A
call :sub_cobol CBLCLG %nistdir%\src NC235A
call :sub_cobol CBLCLG %nistdir%\src NC236A
call :sub_cobol CBLCLG %nistdir%\src NC237A
call :sub_cobol CBLCLG %nistdir%\src NC238A
call :sub_cobol CBLCLG %nistdir%\src NC239A
call :sub_cobol CBLCLG %nistdir%\src NC240A
call :sub_cobol CBLCLG %nistdir%\src NC241A
call :sub_cobol CBLCLG %nistdir%\src NC242A
call :sub_cobol CBLCLG %nistdir%\src NC243A
call :sub_cobol CBLCLG %nistdir%\src NC244A
call :sub_cobol CBLCLG %nistdir%\src NC245A
call :sub_cobol CBLCLG %nistdir%\src NC246A
call :sub_cobol CBLCLG %nistdir%\src NC247A
call :sub_cobol CBLCLG %nistdir%\src NC248A
call :sub_cobol CBLCLG %nistdir%\src NC250A
call :sub_cobol CBLCLG %nistdir%\src NC251A
call :sub_cobol CBLCLG %nistdir%\src NC252A
call :sub_cobol CBLCLG %nistdir%\src NC253A
call :sub_cobol CBLCLG %nistdir%\src NC254A
call :sub_cobol CBLCLG %nistdir%\src NC302M
call :sub_cobol CBLCLG %nistdir%\src NC303M
call :sub_cobol CBLCLG %nistdir%\src NC401M
:skip_NC

rem --
rem -- OB = Obsolete
if /I %test_all%. EQU N. if /I %test_OB%. NEQ Y. goto skip_OB
call :sub_cobol CBLC   %nistdir%\src OBIC2A
call :sub_cobol CBLC   %nistdir%\src OBIC3A
call :sub_cobol CBLCLG %nistdir%\src OBIC1A
call :sub_cobol CBLCLG %nistdir%\src OBNC1M
call :sub_cobol CBLCLG %nistdir%\src OBNC2M
call :sub_cobol CBLCLG %nistdir%\src OBSQ1A
call :sub_cobol CBLC   %nistdir%\src OBSQ4A
call :sub_cobol CBLC   %nistdir%\src OBSQ5A
call :sub_cobol CBLCLG %nistdir%\src OBSQ3A
:skip_OB

rem --
rem -- RL = Relative I/O
if /I %test_all%. EQU N. if /I %test_RL%. NEQ Y. goto skip_RL
call :sub_cobol CBLC   %nistdir%\src RL102A
call :sub_cobol CBLC   %nistdir%\src RL103A
call :sub_cobol CBLCLG %nistdir%\src RL101A
call :sub_cobol CBLCLG %nistdir%\src RL104A
call :sub_cobol CBLCLG %nistdir%\src RL105A
call :sub_cobol CBLCLG %nistdir%\src RL106A
call :sub_cobol CBLCLG %nistdir%\src RL107A
call :sub_cobol CBLC   %nistdir%\src RL109A
call :sub_cobol CBLC   %nistdir%\src RL110A
call :sub_cobol CBLCLG %nistdir%\src RL108A
call :sub_cobol CBLCLG %nistdir%\src RL111A
call :sub_cobol CBLCLG %nistdir%\src RL112A
call :sub_cobol CBLCLG %nistdir%\src RL113A
call :sub_cobol CBLCLG %nistdir%\src RL114A
call :sub_cobol CBLCLG %nistdir%\src RL115A
call :sub_cobol CBLCLG %nistdir%\src RL116A
call :sub_cobol CBLCLG %nistdir%\src RL117A
call :sub_cobol CBLCLG %nistdir%\src RL118A
call :sub_cobol CBLCLG %nistdir%\src RL119A
call :sub_cobol CBLC   %nistdir%\src RL202A
call :sub_cobol CBLC   %nistdir%\src RL203A
call :sub_cobol CBLCLG %nistdir%\src RL201A
call :sub_cobol CBLCLG %nistdir%\src RL204A
call :sub_cobol CBLCLG %nistdir%\src RL205A
call :sub_cobol CBLC   %nistdir%\src RL207A
call :sub_cobol CBLC   %nistdir%\src RL208A
call :sub_cobol CBLCLG %nistdir%\src RL206A
call :sub_cobol CBLCLG %nistdir%\src RL209A
call :sub_cobol CBLCLG %nistdir%\src RL210A
call :sub_cobol CBLCLG %nistdir%\src RL211A
call :sub_cobol CBLC   %nistdir%\src RL213A
call :sub_cobol CBLCLG %nistdir%\src RL212A
call :sub_cobol CBLCLG %nistdir%\src RL301M
call :sub_cobol CBLCLG %nistdir%\src RL302M
call :sub_cobol CBLCLG %nistdir%\src RL401M
:skip_RL

rem --
rem -- RW = Report Writer
if /I %test_all%. EQU N. if /I %test_RW%. NEQ Y. goto skip_RW
call :sub_cobol CBLCLG %nistdir%\src RW101A
call :sub_cobol CBLCLG %nistdir%\src RW102A
call :sub_cobol CBLCLG %nistdir%\src RW103A
call :sub_cobol CBLCLG %nistdir%\src RW104A
call :sub_cobol CBLCLG %nistdir%\src RW301M
call :sub_cobol CBLCLG %nistdir%\src RW302M
:skip_RW

rem --
rem -- SG = Segmentation
if /I %test_all%. EQU N. if /I %test_SG%. NEQ Y. goto skip_SG
call :sub_cobol CBLCLG %nistdir%\src SG101A
call :sub_cobol CBLCLG %nistdir%\src SG102A
call :sub_cobol CBLCLG %nistdir%\src SG103A
call :sub_cobol CBLCLG %nistdir%\src SG104A
call :sub_cobol CBLCLG %nistdir%\src SG105A
call :sub_cobol CBLCLG %nistdir%\src SG106A
call :sub_cobol CBLCLG %nistdir%\src SG201A
call :sub_cobol CBLCLG %nistdir%\src SG202A
call :sub_cobol CBLCLG %nistdir%\src SG203A
call :sub_cobol CBLCLG %nistdir%\src SG204A
call :sub_cobol CBLCLG %nistdir%\src SG302M
call :sub_cobol CBLCLG %nistdir%\src SG303M
call :sub_cobol CBLCLG %nistdir%\src SG401M
:skip_SG

rem --
rem -- SM = Source Manipulation
if /I %test_all%. EQU N. if /I %test_SM%. NEQ Y. goto skip_SM
call :sub_cobol CBLC   %nistdir%\src SM102A
call :sub_cobol CBLCLG %nistdir%\src SM101A
call :sub_cobol CBLC   %nistdir%\src SM104A
call :sub_cobol CBLCLG %nistdir%\src SM103A
call :sub_cobol CBLCLG %nistdir%\src SM105A
call :sub_cobol CBLCLG %nistdir%\src SM106A
call :sub_cobol CBLCLG %nistdir%\src SM107A
call :sub_cobol CBLC   %nistdir%\src SM202A
call :sub_cobol CBLCLG %nistdir%\src SM201A
call :sub_cobol CBLC   %nistdir%\src SM204A
call :sub_cobol CBLCLG %nistdir%\src SM203A
call :sub_cobol CBLCLG %nistdir%\src SM205A
call :sub_cobol CBLCLG %nistdir%\src SM206A
call :sub_cobol CBLCLG %nistdir%\src SM207A
call :sub_cobol CBLCLG %nistdir%\src SM208A
call :sub_cobol CBLCLG %nistdir%\src SM301M
call :sub_cobol CBLCLG %nistdir%\src SM401M
:skip_SM

rem --
rem -- SQ = Sequential I/O
if /I %test_all%. EQU N. if /I %test_SQ%. NEQ Y. goto skip_SQ
call :sub_cobol CBLCLG %nistdir%\src  SQ101M
call :sub_cobol CBLCLG %nistdir%\z390 SQ101M NOCOUNT || rem instead of the original
call :sub_cobol CBLCLG %nistdir%\src  SQ102A
call :sub_cobol CBLCLG %nistdir%\src  SQ103A
call :sub_cobol CBLCLG %nistdir%\src  SQ104A
call :sub_cobol CBLCLG %nistdir%\src  SQ105A
call :sub_cobol CBLCLG %nistdir%\src  SQ106A
call :sub_cobol CBLCLG %nistdir%\src  SQ107A
call :sub_cobol CBLCLG %nistdir%\src  SQ108A
call :sub_cobol CBLCLG %nistdir%\src  SQ109M
call :sub_cobol CBLCLG %nistdir%\src  SQ110M
call :sub_cobol CBLCLG %nistdir%\src  SQ111A
call :sub_cobol CBLCLG %nistdir%\src  SQ112A
call :sub_cobol CBLCLG %nistdir%\src  SQ113A
call :sub_cobol CBLCLG %nistdir%\src  SQ114A
call :sub_cobol CBLCLG %nistdir%\src  SQ115A
call :sub_cobol CBLCLG %nistdir%\src  SQ116A
call :sub_cobol CBLCLG %nistdir%\src  SQ117A
call :sub_cobol CBLCLG %nistdir%\src  SQ121A
call :sub_cobol CBLCLG %nistdir%\src  SQ122A
call :sub_cobol CBLCLG %nistdir%\src  SQ123A
call :sub_cobol CBLCLG %nistdir%\src  SQ124A
call :sub_cobol CBLCLG %nistdir%\src  SQ125A
call :sub_cobol CBLCLG %nistdir%\src  SQ126A
call :sub_cobol CBLCLG %nistdir%\src  SQ127A
call :sub_cobol CBLCLG %nistdir%\src  SQ128A
call :sub_cobol CBLCLG %nistdir%\src  SQ129A
call :sub_cobol CBLCLG %nistdir%\src  SQ130A
call :sub_cobol CBLCLG %nistdir%\src  SQ131A
call :sub_cobol CBLCLG %nistdir%\src  SQ132A
call :sub_cobol CBLCLG %nistdir%\src  SQ133A
call :sub_cobol CBLCLG %nistdir%\src  SQ134A
call :sub_cobol CBLCLG %nistdir%\src  SQ135A
call :sub_cobol CBLCLG %nistdir%\src  SQ136A
call :sub_cobol CBLCLG %nistdir%\src  SQ137A
call :sub_cobol CBLCLG %nistdir%\src  SQ138A
call :sub_cobol CBLCLG %nistdir%\src  SQ139A
call :sub_cobol CBLCLG %nistdir%\src  SQ140A
call :sub_cobol CBLCLG %nistdir%\src  SQ141A
call :sub_cobol CBLCLG %nistdir%\src  SQ142A
call :sub_cobol CBLCLG %nistdir%\src  SQ143A
call :sub_cobol CBLCLG %nistdir%\src  SQ144A
call :sub_cobol CBLCLG %nistdir%\src  SQ146A
call :sub_cobol CBLCLG %nistdir%\src  SQ147A
call :sub_cobol CBLCLG %nistdir%\src  SQ148A
call :sub_cobol CBLCLG %nistdir%\src  SQ149A
call :sub_cobol CBLCLG %nistdir%\src  SQ150A
call :sub_cobol CBLCLG %nistdir%\src  SQ151A
call :sub_cobol CBLCLG %nistdir%\src  SQ152A
call :sub_cobol CBLCLG %nistdir%\src  SQ153A
call :sub_cobol CBLCLG %nistdir%\src  SQ154A
call :sub_cobol CBLCLG %nistdir%\src  SQ155A
call :sub_cobol CBLCLG %nistdir%\src  SQ156A
call :sub_cobol CBLCLG %nistdir%\src  SQ201M
call :sub_cobol CBLC   %nistdir%\src  SQ203A
call :sub_cobol CBLCLG %nistdir%\src  SQ202A
call :sub_cobol CBLCLG %nistdir%\src  SQ204A
call :sub_cobol CBLCLG %nistdir%\src  SQ205A
call :sub_cobol CBLCLG %nistdir%\src  SQ206A
call :sub_cobol CBLCLG %nistdir%\src  SQ207M
call :sub_cobol CBLCLG %nistdir%\src  SQ208M
call :sub_cobol CBLCLG %nistdir%\src  SQ209M
call :sub_cobol CBLCLG %nistdir%\src  SQ210M
call :sub_cobol CBLCLG %nistdir%\src  SQ211A
call :sub_cobol CBLCLG %nistdir%\src  SQ212A
call :sub_cobol CBLCLG %nistdir%\src  SQ213A
call :sub_cobol CBLCLG %nistdir%\src  SQ214A
call :sub_cobol CBLCLG %nistdir%\src  SQ215A
call :sub_cobol CBLCLG %nistdir%\src  SQ216A
call :sub_cobol CBLCLG %nistdir%\src  SQ217A
call :sub_cobol CBLCLG %nistdir%\src  SQ218A
call :sub_cobol CBLCLG %nistdir%\src  SQ219A
call :sub_cobol CBLCLG %nistdir%\src  SQ220A
call :sub_cobol CBLCLG %nistdir%\src  SQ221A
call :sub_cobol CBLCLG %nistdir%\src  SQ222A
call :sub_cobol CBLCLG %nistdir%\src  SQ223A
call :sub_cobol CBLCLG %nistdir%\src  SQ224A
call :sub_cobol CBLCLG %nistdir%\src  SQ225A
call :sub_cobol CBLCLG %nistdir%\src  SQ226A
call :sub_cobol CBLCLG %nistdir%\src  SQ227A
call :sub_cobol CBLCLG %nistdir%\src  SQ228A
call :sub_cobol CBLCLG %nistdir%\src  SQ229A
call :sub_cobol CBLCLG %nistdir%\src  SQ230A
call :sub_cobol CBLCLG %nistdir%\src  SQ302M
call :sub_cobol CBLCLG %nistdir%\src  SQ303M
call :sub_cobol CBLCLG %nistdir%\src  SQ401M
:skip_SQ

rem --
rem -- ST = Sort / Merge
if /I %test_all%. EQU N. if /I %test_ST%. NEQ Y. goto skip_ST
call :sub_cobol CBLC   %nistdir%\src  ST102A
call :sub_cobol CBLC   %nistdir%\src  ST103A
call :sub_cobol CBLCLG %nistdir%\src  ST101A
call :sub_cobol CBLC   %nistdir%\src  ST105A
call :sub_cobol CBLCLG %nistdir%\src  ST104A
call :sub_cobol CBLC   %nistdir%\src  ST107A
call :sub_cobol CBLCLG %nistdir%\src  ST106A
call :sub_cobol CBLCLG %nistdir%\src  ST108A
call :sub_cobol CBLC   %nistdir%\src  ST110A
call :sub_cobol CBLC   %nistdir%\src  ST111A
call :sub_cobol CBLCLG %nistdir%\src  ST109A
call :sub_cobol CBLC   %nistdir%\src  ST113M
call :sub_cobol CBLC   %nistdir%\src  ST114M
call :sub_cobol CBLCLG %nistdir%\src  ST112M
call :sub_cobol CBLC   %nistdir%\src  ST116A
call :sub_cobol CBLC   %nistdir%\src  ST117A
call :sub_cobol CBLCLG %nistdir%\src  ST115A
call :sub_cobol CBLCLG %nistdir%\src  ST118A
call :sub_cobol CBLC   %nistdir%\src  ST120A
call :sub_cobol CBLC   %nistdir%\src  ST121A
call :sub_cobol CBLCLG %nistdir%\src  ST119A
call :sub_cobol CBLC   %nistdir%\src  ST123A
call :sub_cobol CBLC   %nistdir%\src  ST124A
call :sub_cobol CBLCLG %nistdir%\src  ST122A
call :sub_cobol CBLC   %nistdir%\src  ST126A
call :sub_cobol CBLCLG %nistdir%\src  ST125A
call :sub_cobol CBLCLG %nistdir%\src  ST127A
call :sub_cobol CBLCLG %nistdir%\src  ST131A
call :sub_cobol CBLCLG %nistdir%\src  ST132A
call :sub_cobol CBLCLG %nistdir%\src  ST133A
call :sub_cobol CBLCLG %nistdir%\src  ST134A
call :sub_cobol CBLCLG %nistdir%\src  ST135A
call :sub_cobol CBLCLG %nistdir%\src  ST136A
call :sub_cobol CBLCLG %nistdir%\src  ST137A
call :sub_cobol CBLCLG %nistdir%\src  ST139A
call :sub_cobol CBLCLG %nistdir%\src  ST140A
call :sub_cobol CBLCLG %nistdir%\src  ST144A
call :sub_cobol CBLCLG %nistdir%\src  ST146A
call :sub_cobol CBLCLG %nistdir%\src  ST147A
call :sub_cobol CBLCLG %nistdir%\src  ST301M
:skip_ST

rem --
rem -- Create result statistics to error file
echo %0 %copymbr% copy members found and %copyerr% not found> %nistdir%\z390\RUNNIST.ERR
echo %0 %datambr% data members found and %dataerr% not found>>%nistdir%\z390\RUNNIST.ERR
echo %0 %tested% compiles completed:         >>%nistdir%\z390\RUNNIST.ERR
echo %0 - okay RC=0 for %testgood% tests     >>%nistdir%\z390\RUNNIST.ERR
echo %0 - warn RC=4 for %testwarn% tests     >>%nistdir%\z390\RUNNIST.ERR
echo %0 - err  RC=8 for %testerr% tests      >>%nistdir%\z390\RUNNIST.ERR
echo %0 - any other for %testfail% tests     >>%nistdir%\z390\RUNNIST.ERR
echo %0 - and %nocount% not NIST             >>%nistdir%\z390\RUNNIST.ERR
echo %0 z390 repository is at hash %z390_LVL%>>%nistdir%\z390\RUNNIST.ERR
echo %0 NIST repository is at hash %NIST_LVL%>>%nistdir%\z390\RUNNIST.ERR
echo %0 Date: %DATE% %TIME%                  >>%nistdir%\z390\RUNNIST.ERR

rem --
rem -- Report statistics to current log and to #all.err file
type %nistdir%\z390\RUNNIST.ERR >>%nistdir%\z390\#all.err
echo .
type %nistdir%\z390\RUNNIST.ERR
echo .
echo See %nistdir%\sz390\$allsort.err for complete list of all messages

rem --
rem -- sort complete log file, then exit
copy %nistdir%\z390\#all.err %nistdir%\z390\#full_log.txt >NUL
set myRC=%ERRORLEVEL%
if %myRC% GTR %NIST_RC% set NIST_RC=%myRC%
sort /+17 %nistdir%\z390\#all.err /O %nistdir%\z390\#allsort.err
set myRC=%ERRORLEVEL%
if %myRC% GTR %NIST_RC% set NIST_RC=%myRC%
echo .
echo final return code is %NIST_RC%
goto return

:help
set NIST_RC=8
echo .
echo %0 ERROR: no arguments provided - path to z390 repository unknown
echo .
echo The path to a local clone of the z390 repository with z390.jar available must be specified.
echo Note: if z390.jar is not available, please run the z390 documented build procedure.
echo .
echo When the z390 path is omitted, no tests can be run
echo When the z390 path is specified, the default is to run all tests
echo This default can be overriden by specifying one or more of the following parameters:
echo - cleanup = cleanup only; no compiles
echo - ALT= ALT* copy members
echo - CM = Communications Module
echo - DB = Debug module
echo - EX = Executive module
echo - IC = Inter-Program Communication
echo - IF = Intrinsic Functions
echo - IX = Indexed I/O
echo - K  = K* copy members
echo - NC = Nucleus
echo - OB = Obsolete features
echo - RW = Report Writer
echo - SG = Segmentation
echo - SM = Source Manipulation
echo - SQ = Sequential I/O
echo .
echo There is no prescribed order of parameters
echo .
echo To specify z390 options, provide them in variable z390opt
echo .
goto return

:no_nistrepo
set NIST_RC=12
echo %0 ERROR: %nistdir% is not a git repository
goto return

:no_z390repo
set NIST_RC=12
echo %0 ERROR: %z390dir% is not a git repository
goto return

:return
popd
rem ----- Lvl(%z_NestLevel%)  End %0 %1 %2 %3 %4 %5 %6 %7 %8 %9
exit /b %NIST_RC%



:sub_clean
rem -- removes all non-source files from a source directory
rem -- %1 = source dir to clean up
if exist %1\*.390                del %1\*.390
if exist %1\*.BAL                del %1\*.BAL
if exist %1\*.ERR                del %1\*.ERR
if exist %1\*.LOG                del %1\*.LOG
if exist %1\*.LST                del %1\*.LST
if exist %1\*.MLC                del %1\*.MLC
if exist %1\*.OBJ                del %1\*.OBJ
if exist %1\*.OUT                del %1\*.OUT
if exist %1\*.PRN                del %1\*.PRN
if exist %1\*.CBL_ZC_LABELS.CPY  del %1\*.CBL_ZC_LABELS.CPY
goto :EOF



:sub_cobol
rem -- compiles, links, runs a Cobol program
rem -- %1 = batch procedure to use: CBLC / CBLCL /CBLCLG
rem -- %2 = directory with source file
rem -- %3 = source file name without extension
rem -- %4 = COUNT/NOCOUNT indicator. COUNT is the default.
set dir=%2
set pgm=%3
if /I %4. EQU NOCOUNT. set /A nocount = %nocount% + 1
if /I %4. NEQ NOCOUNT. set /A tested  = %tested%  + 1
if not exist %dir%\%pgm%.CBL goto :sub_nocbl
rem -- set copy source location
set XXXXX047=%~dps0
set XXXXX048=%~dps0\..\z390alt\
rem -- set printer destination if GO step is requested
if %1 == CBLCLG (set XXXXX055=%dir%\%pgm%_XXXXX055.OUT
         ) else (set XXXXX055=)
call bat\%1 %z_TraceMode% %dir%\%pgm% notiming SYSCPY(+%~dps0) %z390opt%
set myRC=%ERRORLEVEL%
if %myRC% GTR %NIST_RC% set NIST_RC=%myRC%
rem -- bump applicable result counter
if /I %4. EQU NOCOUNT. goto :sub_cobol_end
if %myRC% == 0 (set /A testgood = %testgood% + 1 && goto :sub_cobol_end)
if %myRC% == 4 (set /A testwarn = %testwarn% + 1 && goto :sub_cobol_end)
if %myRC% == 8 (set /A testerr  = %testerr%  + 1 && goto :sub_cobol_end)
set /A testfail = %testfail% + 1
goto :sub_cobol_end
:sub_nocbl
if 12 GTR %NIST_RC% set NIST_RC=12
set /A testerr = %testerr% + 1
echo %dir%\%pgm%.CBL not found >>%dir%\%pgm%.ERR
type %dir%\%pgm%.ERR
:sub_cobol_end
type %dir%\%pgm%.ERR >>%nistdir%\z390\#all.err 2>nul
goto :EOF



:sub_copy
rem -- count copy member
rem -- %1 = batch procedure to use (irrelevant)
rem -- %2 = directory with source file
rem -- %3 = source file name without extension
rem -- %4 = COUNT/NOCOUNT indicator. COUNT is the default.
if not exist %2\%3.CPY goto :sub_nocopy
set /A copymbr = %copymbr% + 1
echo %2\%3.CPY found >>%2\%3.ERR
goto :sub_copy_end
:sub_nocopy
if 12 GTR %NIST_RC% set NIST_RC=12
set /A copyerr = %copyerr% + 1
echo %2\%3.CPY not found >>%2\%3.ERR
:sub_copy_end
type %2\%3.ERR
type %2\%3.ERR >>%nistdir%\z390\#all.err 2>nul
goto :EOF



:sub_data
rem -- count copy member
rem -- %1 = batch procedure to use (irrelevant)
rem -- %2 = directory with source file
rem -- %3 = source file name without extension
rem -- %4 = COUNT/NOCOUNT indicator. COUNT is the default.
if not exist %2\%3.DAT goto :sub_nodata
set /A datambr = %datambr% + 1
echo %2\%3.DAT found >>%2\%3.ERR
goto :sub_data_end
:sub_nodata
if 12 GTR %NIST_RC% set NIST_RC=12
set /A dataerr = %dataerr% + 1
echo %2\%3.DAT not found >>%2\%3.ERR
:sub_data_end
type %2\%3.ERR
type %2\%3.ERR >>%nistdir%\z390\#all.err 2>nul
goto :EOF
