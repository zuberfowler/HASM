SYSINFOA CSECT
* SYSINFO  VERSION 4.0  BY CLYDE THOMAS ZUBER                         *
***********************************************************************
*                                                                     *
* ATTR:  RENT,REUS,REFR,AMODE(31),RMODE(ANY)                          *
*                                                                     *
* PROGRAM DESCRIPTION:                                                *
*                                                                     *
* THIS ROUTINE HAS TWO ENTRY POINTS.  SYSINFOA IS FOR REGULAR OS/370  *
* LINKAGE FOR ASSEMBLER PROGRAMS.  SYSINFO IS FOR PL/I PROGRAMS USING *
* PL/I OPTIMIZER R3.1, R4.0 AND R5.0 CONVENTIONS.                     *
*                                                                     *
* WHEN USING THE SYSINFO ENTRY FROM PL/I IT SHOULD BE DECLARED AS:    *
*      DECLARE  SYSINFO  ENTRY OPTIONS(ASM, INTER);                   *
* ONE USES CALL TO INVOKE IT WITH ONE ARGUMENT.                       *
*      CALL SYSINFO(SYSTEM_INFO);                                     *
*                                                                     *
* SYSTEM_INFO IS AN AREA DECLARED AS FOLLOWS:                         *
*      DECLARE                                                        *
*          1  SYSTEM_INFO,                                            *
*             2  VIRT_MEMORY  FIXED BINARY(31),                       *
*             2  REAL_MEMORY  FIXED BINARY(31),                       *
*             2  EXTD_MEMORY  FIXED BINARY(31),                       *
*             2  BEGIN_PRIV   FIXED BINARY(31),                       *
*             2  BEGIN_CSA    FIXED BINARY(31),                       *
*             2  AVAIL_MEM    FIXED BINARY(31),                       *
*             2  MVS_NAME     CHAR(8),                                *
*             2  MVS_FMID     CHAR(8),                                *
*             2  USER_INFO    CHAR(16),                               *
*             2  MVS_RELEASE  CHAR(4),                                *
*             2  SMF_SID      CHAR(4),                                *
*             2  JES_NAME     CHAR(4),                                *
*             2  JES3_ID      CHAR(8),                                *
*             2  FLAG_BITS,                                           *
*                3  JES3      BIT(1),                                 *
*                3  GLOBAL    BIT(1),                                 *
*                3  XA_SYS    BIT(1),                                 *
*                3  FILLER    BIT(5),                                 *
*             2  CUR_DATE     FIXED DECIMAL(5,3),                     *
*             2  IPL_TIME     FIXED DECIMAL(5,2),                     *
*             2  IPL_DATE     FIXED DECIMAL(5,3),                     *
*             2  IPL_VOLSER   CHAR(6),                                *
*             2  IPL_NUC      CHAR(1),                                *
*             2  FILLER       CHAR(1),                                *
*             2  #CPU_ONLINE  FIXED BINARY,                           *
*             2  CPUS(16),  /* (N REFER(#CPU_ONLINE)) */              *
*                3  CPU_SERNUM  CHAR(6),                              *
*                3  CPU_MODEL   CHAR(4);                              *
*                                                                     *
* NOTE:  PL/I ERROR MSG OFFSETS ARE RELATIVE TO REAL ENTRY POINT      *
*        R11 - PROCEDURE BASE                                         *
*        R12 - RESERVED                                               *
*        R13 - ADDRESS OF STORAGE AREA                                *
*                                                                     *
***********************************************************************
         EJECT
SYSINFOA AMODE 31
SYSINFOA RMODE ANY
***********************************************************************
*** ASSEMBLER ENTRY POINT *********************************************
***********************************************************************
         USING *,15                IDENTIFY BASE REGISTER
         B     START               SKIP IDENTIFICATION SECTION
         DC    AL1(7)              PROGRAM IDENTIFIER
         DC    C'SYSINFO V4.1  BY CLYDE THOMAS ZUBER'
START    STM   14,12,12(13)        STORE REGISTERS
         LR    2,1                 ADDRESS OF PARM ADDR LIST
         GETMAIN R,LV=STOREND-STORAGE
         L     15,16(13)           RESTORE R15 (BASE REG)
         ST    13,4(1)             CHAIN SAVE AREAS
         ST    1,8(13)             ..
         MVI   0(1),X'00'          CLEAR FLAG (WILL DO FREEMAIN)
         LR    13,1                POINT TO DSA
         USING STORAGE,13          ..
         B     SETBASE             SKIP OTHER ENTRY CODE
         EJECT
***********************************************************************
*** PL/I REAL ENTRY - PROLOGUE CODE ***********************************
***********************************************************************
         ENTRY SYSINFO
         DC    C'SYSINFO'          PROGRAM IDENTIFIER
         DC    AL1(7)              ..
SYSINFO  DS    0H
         USING *,15                IDENTIFY BASE REGISTER
         STM   14,12,12(13)        SAVE REGISTERS
         LR    2,1                 SAVE PARAMETER LIST ADDRESS
         LA    0,STOREND-STORAGE   PUT THE LENGTH OF THE NEW DSA IN R0
         L     1,76(13)            PTR NEXT AVAIL BYTE AFTER LAST DSA
         ALR   0,1                 ADD THEM TOGETHER
         CL    0,12(12)            COMPARE WITH LAST AVAILABLE BYTE
         BNH   SPCAVAIL            IT WILL FIT
         L     15,116(12)          OBTAIN MORE STORAGE (PL/I ROUTINE)
         BALR  14,15               ..
SPCAVAIL L     14,72(13)           GET ADDR OF LSW FROM OLD DSA
         LR    15,0                COPY R0 (NAB AFTER NEW DSA)
         STM   14,0,72(1)          SAVE LSW AND NAB IN NEW DSA
         L     15,16(13)           RESTORE R15 (BASE REG)
         ST    13,4(1)             ADDR OF LAST DSA IN NEW DSA
         ST    1,8(13)             CHAIN SAVE AREA (NOT DONE BY PL/I)
         MVI   0(1),X'80'          SET FLAGS IN DSA TO PRESERVE PL/I
         MVI   1(1),X'00'              ERROR HANDLING IN THIS ROUTINE
         MVI   86(1),X'91'         ..
         MVI   87(1),X'C0'         ..
         LA    13,0(1)             POINT TO NEW DSA, CLEAR HIGH BYTE
         USING STORAGE,13          ..
         EJECT
***********************************************************************
*** PROCEDURE BASE ****************************************************
***********************************************************************
SETBASE  EQU   *
         BALR  11,0                RESET BASE ADDRESS
         USING *,11                IDENTIFY BASE REGISTER
         LA    11,0(11)            CLEAR HIGH ORDER BYTE OF BASE REG
         L     10,0(2)             GET ADDRESS OF ARGUMENT
* INITIALIZE DATA AREAS AS NECESSARY
         USING SINFO,10            MAP PARAMETER
         MVI   FLGBITS,X'00'       INITIALIZE FLAGS
         MVC   IPLTIME,ITIME       INITIALIZE PACKED IPL TIME FIELD
         MVI   CPU,C' '            INITIALIZE CPU TYPE/SERIAL AREA
         MVC   CPU+1(159),CPU      ..
* SET ADDRESSING MODE TO 31 IF XA, SAVE CURRENT ADDRESS MODE
         L     2,16                GET ADDRESS OF CVT
         TM    X'74'(2),X'80'      ARE WE ON XA?
         BNO   S370                NO, SKIP XA STUFF
         LA    3,FINISH            WHERE TO GO WHEN RESTORING
         L     1,HIGHBIT           NOW SET 31 BIT ADDRESSING
         BSM   3,1                 AND GET CURRENT ADDR MODE
HIGHBIT  DC    A(MODE+X'80000000') ..
MODE     ST    3,MODESET           SAVE FOR RESTORING LATER
* GET SYSTEM INFORMATION
S370     LA    3,X'28'             GO BACK X'28' INTO PREFIX
         SR    2,3                 ..
         MVC   MVSDATA,0(2)        GET MVS CONTIGUOUS DATA INFO
         MVC   MVSREL,X'24'(2)     GET MVS RELEASE NUMBER
         LA    2,X'28'(2)          BACK TO CVT BEGINNING
         L     3,X'30'(2)          ADDR OF UCB ENTRY FOR IPL VOL
         MVC   IPLVOL,28(3)        GET IPL VOLSER
         MVC   CURDATE,X'39'(2)    GET CURRENT DATE
         TM    X'74'(2),X'80'      IS THIS MVS/XA
         BNO   NOTXA               NO, NOT XA
         OI    FLGBITS,X'20'       FLAG AS XA
         L     3,X'490'(2)         GET CVTRCEP
         LA    3,X'F8'(3)          ADD LENGTH OF RCE TO GET TO RIT
         LM    4,6,X'374'(3)       FIRST EIME, LAST EIME, INCREMENT
         SR    5,4                 GET NUMBER OF EIME'S (EACH 1 BYTE)
         LA    5,1(5)              ..
         MR    4,6                 MULTIPLY BY INCREMENT
         SLA   5,12                MULTIPLY BY 4096 (4K PAGE)
         ST    5,EXTDMEM           SAVE AMOUNT OF EXTENDED MEMORY
         LA    3,2048              GET PSA LENGTH
         AR    3,3                 ..
         B     WASXA               FOLLOWING RESERVED IN XA
NOTXA    LA    3,0                 NO EXTENDED MEMORY IN 370
         ST    3,EXTDMEM           ..
         L     3,X'80'(2)          GET FIRST AVAILABLE ADDR
WASXA    ST    3,BEGPRIV           ..
         MVC   VIRTMEM,X'A4'(2)    SIZE OF VIRTUAL STORAGE
         MVC   REALMEM,X'138'(2)   SIZE OF POTENTIAL REAL STORAGE
         L     4,X'1A0'(2)         ADDRESS OF THE BEGINNING OF CSA
         ST    4,BEGCSA            ..
         SR    4,3                 AVAILABLE MEMORY
         ST    4,AVAILMEM          ..
         L     3,X'148'(2)         GET CVTEXT2
         MVC   IPLNUC,4(3)         NUCLEUS ID FROM IPL
         L     3,X'294'(2)         ADDR OF CSD
         LH    4,X'A'(3)           NUMBER OF CPU'S ONLINE
         STH   4,CPUON             .. (REG4 IS LOOP COUNTER)
         L     3,X'2FC'(2)         PTR PHYS CONFIG COMM AREA VECTOR TAB
         LA    6,0                 INITIALIZE PCCA VECTOR TABLE OFFSET
         LA    7,CPU               ADDRESS TO MOVE DATA TO
CPULOOP  L     5,0(6,3)            GET ADDR OF A PCCA
         LA    6,4(6)              NEXT POSITION IN PCCA VECTOR TABLE
         LTR   5,5                 SKIP NULL ENTRIES
         BZ    CPULOOP             ..
         MVC   0(10,7),6(5)        GET CPU SERIAL NUMBER AND MODEL
         LA    7,10(7)             NEXT ADDRESS TO MOVE DATA TO
         BCT   4,CPULOOP           LOOP
         L     3,X'C4'(2)          GET ADDRESS OF SMCA
         MVC   SMFSID,X'10'(3)     GET SMF SYSTEM ID
         L     1,X'150'(3)         GET IPL TIME
         SLR   0,0                 ..
         D     0,=F'360000'        ..
         CVD   1,DWORK             ..
         MVN   IPLTIME(1),DWORK+6  ..
         MVZ   IPLTIME+1(1),DWORK+7 ..
         LR    1,0                 ..
         SLR   0,0                 ..
         D     0,=F'6000'          ..
         CVD   1,DWORK             ..
         MVN   IPLTIME+1(1),DWORK+6 ..
         MVZ   IPLTIME+2(1),DWORK+7 ..
         MVC   IPLDATE,X'155'(3)   GET IPL DATE
         L     3,X'128'(2)         POINT TO THE JESCT
         MVC   JESNAME,X'1C'(3)    NAME OF PRIMARY JOB ENTRY SUBSYSTEM
         CLC   JESNAME,=C'JES3'    IS IT JES3?
         BNE   RESET               NO, WE'RE DONE
         OI    FLGBITS,X'80'       FLAG AS JES3
         L     3,X'18'(3)          ADDR OF 1ST SUBSYSTEM COMMUN. TABLE
JES3LOOP CLC   8(4,3),=C'JES3'     IS THIS THE SSCT FOR JES3?
         BE    GOTSSCVT            YES, CONTINUE
         L     3,4(3)              POINT TO NEXT SSCT
         LTR   3,3                 IS THIS THE END OF THE CHAIN?
         BZ    RESET               YES, THIS SHOULD NEVER HAPPEN
         B     JES3LOOP            GO CHECK NEXT SSCT
GOTSSCVT L     3,X'10'(3)          POINT TO THE SSVT FOR JES3
* MAPPING FOR SSVT IS IN JES3 MACRO IATYSVT (SVTFLAG1 EQU SVTGLOBL)
* MAPPING FOR SVTMPACT IS IN JES3 MACRO IATYMPE IN IATYMPC
         CLC   X'224'(7,3),=C'IATSSVT' IS THIS LITERAL WHERE EXPECTED?
         BNE   UNKNOWN             NO, NEW/OLD UNKNOWN VERSION
V134     CLC   X'22C'(6,3),=C'SP R34' V1.3.4?
         BNE   V215                SEE IF V215
         TM    X'409'(3),X'40'     SVTFLAG1 (V1.3.4)
         L     3,X'2A0'(3)         SVTMPACT (ACTIVE MPC ADDR, V1.3.4)
         BNO   GETID               ZERO, ONLY A LOCAL
         B     GLOBAL              GO FLAG AS GLOBAL
V215     CLC   X'22C'(6,3),=C'SP215 ' V2.1.5?
         BNE   V221                SEE IF V221
         TM    X'419'(3),X'40'     SVTFLAG1 (V2.1.5)
         L     3,X'2AC'(3)         SVTMPACT (ACTIVE MPC ADDR, V2.1.5)
         BNO   GETID               ZERO, ONLY A LOCAL
         B     GLOBAL              GO FLAG AS GLOBAL
V221     CLC   X'22C'(6,3),=C'SP220 ' V2.2.1?
         BNE   UNKNOWN             NO, NEW/OLD UNKNOWN VERSION
         TM    X'471'(3),X'40'     SVTFLAG1 (V2.2.1)
         L     3,X'2AC'(3)         SVTMPACT (ACTIVE MPC ADDR, V2.2.1)
         BNO   GETID               ZERO, ONLY A LOCAL
         B     GLOBAL              GO FLAG AS GLOBAL
* THE FOLLOWING IS SUPPOSITIONAL AND UNTESTED
*V131     CLC   X'22C'(6,3),=C'SP R31' V1.3.1?
*         BNE   UNKNOWN             NO, NEW/OLD UNKNOWN VERSION
*         TM    X'3BC'(3),X'40'     SVTFLAG1 (V1.3.1)
*         L     3,X'2A0'(3)         SVTMPACT (ACTIVE MPC ADDR, V1.3.4)
*         BNO   GETID               ZERO, ONLY A LOCAL
GLOBAL   OI    FLGBITS,X'40'       FLAG AS GLOBAL
GETID    MVC   JES3ID,X'350'(3)    GET MPNAME (JES MAIN NAME) V1 & V2
         B     RESET               SKIP UNKNOWN BLANK OUT
UNKNOWN  MVI   JES3ID,C' '         BLANK OUT SINCE NOT EQUIPED TO FIND
         MVC   JES3ID+1(7),JES3ID  ..
* RESTORE ADDRESSING MODE
RESET    L     2,16                GET ADDRESS OF CVT
         TM    X'74'(2),X'80'      ARE WE ON XA?
         BNO   FINISH              NO, SKIP XA STUFF
         L     1,MODESET           RESTORE ADDR MODE, BRANCH TO FINISH
         BSM   0,1                 ..
***********************************************************************
*** EPILOGUE CODE *****************************************************
***********************************************************************
FINISH   DS    0H
         LR    1,13                COPY R13
         L     13,4(13)            RESTORE R13
*********ST****15,16(13)***********SAVE*RETURN*CODE********************
         TM    0(1),X'80'          IS DSA FROM PL/I?
         BO    RETURN              YES, NO FREEMAIN REQUIRED
         LA    0,STOREND-STORAGE   GET LENGTH
         FREEMAIN R,LV=(0),A=(1)   FREE DSA
RETURN   LM    14,12,12(13)        RESTORE CALLER'S REGISTERS
         BR    14                  RETURN
***********************************************************************
*** STATIC STORAGE AREA ***********************************************
***********************************************************************
         LTORG
ITIME    DC    PL3'0'
***********************************************************************
*** DYNAMIC STORAGE AREA **********************************************
***********************************************************************
STORAGE  DSECT
SAVEAREA DS    22F
DWORK    DS    D
MODESET  DS    F
STOREND  DS    0D
***********************************************************************
*** PARAMETER DEFINITION **********************************************
***********************************************************************
SINFO    DSECT
VIRTMEM  DS    CL4
REALMEM  DS    CL4
EXTDMEM  DS    CL4
BEGPRIV  DS    CL4
BEGCSA   DS    CL4
AVAILMEM DS    CL4
MVSDATA  DS    CL32
MVSREL   DS    CL4
SMFSID   DS    CL4
JESNAME  DS    CL4
JES3ID   DS    CL8
FLGBITS  DC    X'00'
CURDATE  DS    CL3
IPLTIME  DC    PL3'0'
IPLDATE  DS    CL3
IPLVOL   DS    CL6
IPLNUC   DS    CL1
FILLER   DS    CL1
CPUON    DS    CL2
CPU      DC    CL160' '
         END
