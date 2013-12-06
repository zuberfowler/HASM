COPYMEMA CSECT
* COPYMEM  VERSION 2.1  BY CLYDE THOMAS ZUBER                         *
***********************************************************************
*                                                                     *
* ATTR:  RENT,REUS,REFR,AMODE(31),RMODE(ANY)                          *
*                                                                     *
* PROGRAM DESCRIPTION:                                                *
*                                                                     *
* THIS ROUTINE HAS TWO ENTRY POINTS.  COPYMEMA IS FOR REGULAR OS/370  *
* LINKAGE FOR ASSEMBLER PROGRAMS.  COPYMEM IS FOR PL/I PROGRAMS USING *
* PL/I OPTIMIZER R5.0 CONVENTIONS.  IT WILL RUN ON BOTH 370 AND XA.   *
*                                                                     *
* COPYMEM IS A ROUTINE WHICH WILL MOVE FROM A SPECIFIED STORAGE       *
* LOCATION TO A SPECIFIED STRING AREA.  THE REQUIRED PARAMETERS ARE   *
* THE ADDRESS FROM WHICH TO COPY AND THE STRING WHERE THE COPY IS TO  *
* GO.  IF THE ROUTINE IS UNSUCCESSFUL IN OBTAINING THE ADDRESS THE    *
* STRING WILL EQUAL '--- UNABLE TO OBTAIN ADDRESS ---' (OR AT LEAST   *
* THE BEGINNING OF IT IF THE STRING IS SHORTER).  IF AN EXCEPTION IS  *
* ENCOUNTERED NO ATTEMPT IS MADE TO RESTART AFTER THE POINT OF ERROR. *
*                                                                     *
* ENTRY COPYMEMA:                                                     *
* THE FIRST PARAMETER IS A FULLWORD ADDRESS FROM WHICH IS THE STORAGE *
* LOCATION.  THE SECOND PARAMETER IS THE STR WHERE THE COPY WILL GO.  *
* THE STRING PARAMETER IS ASSUMED TO BE VARYING LENGTH (AS PL/I) OR   *
* ALTERNATELY, AN EXTRA THIRD ARGUMENT MAY BE PASSED.  THIS THIRD     *
* ARGUMENT IS A HALFWORD SPECIFING THE LENGTH OF THE STRING.          *
* FOR VARYING LENGTH SET UP THE CALL AND VARIABLES LIKE THIS:         *
*               CALL  COPYMEMA,(ADDR,STR),VL                          *
*      ADDR     DS    A       AN INITIALIZED FULLWORD ADDRESS         *
*      STR      DC    H'10'   THE LENGTH OF THE STRING                *
*               DS    CL10    THE STRING ITSELF                       *
* SINCE THE STRING IS THE OUTPUT THE LENGTH FIELD MUST SPECIFY THE    *
* MAXIMUM LENGTH THE STRING CAN BE REGARDLESS OF WHETHER TWO OR THREE *
* ARGUMENTS ARE PASSED.                                               *
*                                                                     *
* ENTRY COPYMEM:                                                      *
* THE STRING DESCRIPTOR BLOCK IS PASSED AS A PARAMETER.  THIS MEANS   *
* THAT THE STRING MAY BE EITHER FIXED OR VARYING LENGTH.  THE CONTROL *
* BLOCK FORMAT IS AS FOLLOWS:                                         *
*  0         1         2         3          4                         *
*  ------------------------------------------                         *
*  | BYTE ADDR OF CHAR STRING               |                         *
*  ------------------------------------------                         *
*  | DCL LENGTH        |X| UNUSED|          |                         *
*  ------------------------------------------                         *
*                       0=FIXED                                       *
*                       1=VARYING                                     *
* WHEN USING THE COPYMEM ENTRY FROM PL/I IT SHOULD BE DECLARED AS A   *
* PL/I PROCEDURE AS FOLLOWS:                                          *
*      DECLARE  COPYMEM  ENTRY;                                       *
* THE FIRST PARAMETER IS OF TYPE PTR OR FIXED BINARY(31). THE SECOND  *
* PARAMETER CAN THEN BE CHAR, EITHER FIXED OR VARYING.  THE STRING    *
* DESCRIPTOR INDICATES THE MAXIMUM LENGTH OF THE STRING.              *
*                                                                     *
* NOTE:  PL/I ERROR MSG OFFSETS ARE RELATIVE TO REAL ENTRY POINT      *
*        R11 - PROCEDURE BASE                                         *
*        R12 - RESERVED                                               *
*        R13 - ADDRESS OF DYNAMIC STORAGE AREA                        *
*                                                                     *
***********************************************************************
         EJECT
COPYMEMA AMODE 31
COPYMEMA RMODE ANY
***********************************************************************
*** ASSEMBLER ENTRY POINT *********************************************
***********************************************************************
         USING *,15                IDENTIFY BASE REGISTER
         B     START               SKIP IDENTIFICATION SECTION
         DC    AL1(7)              PROGRAM IDENTIFIER
         DC    C'COPYMEM V2.1  BY CLYDE THOMAS ZUBER'
START    STM   14,12,12(13)        STORE REGISTERS
         LR    2,1                 ADDRESS OF PARM ADDR LIST
         GETMAIN R,LV=STOREND-STORAGE
         L     15,16(13)           RESTORE R15 (BASE REG)
         ST    13,4(1)             CHAIN SAVE AREAS
         ST    1,8(13)             ..
         MVI   0(1),X'00'          CLEAR FLAG (WILL DO FREEMAIN)
         LR    13,1                POINT TO DSA
         USING STORAGE,13          ..
         LM    8,9,0(2)            ADDRESS OF FIRST & SECOND ARGUMENTS
         LTR   9,9                 ARE THERE MORE ARGUMENTS?
         BM    PARM2               NO, ONLY TWO
         L     2,8(2)              GET ADDRESS OF 3RD ARGUMENT
         LH    3,0(2)              LENGTH OF STR
         LR    2,9                 COPY BEGIN ADDR OF STR
         B     SETBASE             SKIP OTHER EXCLUSIVE PROCESSING
PARM2    EQU   *
         LA    2,2(9)              ADDR OF STR
         LH    3,0(9)              LENGTH OF STR
         B     SETBASE             SKIP OTHER ENTRY CODE
         EJECT
***********************************************************************
*** PL/I REAL ENTRY - PROLOGUE CODE ***********************************
***********************************************************************
         ENTRY COPYMEM
         DC    C'COPYMEM'          PROGRAM IDENTIFIER
         DC    AL1(7)              ..
COPYMEM  DS    0H
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
         LR    13,1                POINT TO NEW DSA
         USING STORAGE,13          ..
         LM    8,9,0(2)            ADDRESS OF ARGUMENTS
         L     2,0(9)              GET ADDR OF STR FROM DESCRIPTOR
         LH    3,4(9)              DCL LENGTH OF STR
         TM    6(9),X'80'          IS IT VARYING?
         BZ    SETBASE             NO, FIXED LENGTH STRING
         STH   3,0(2)              SET LENGTH TO MAX
         LA    2,2(2)              REAL ADDR OF STR
         EJECT
***********************************************************************
*** PROCEDURE BASE ****************************************************
***********************************************************************
SETBASE  EQU    *
         BALR  11,0                RESET BASE ADDRESS
         USING *,11                IDENTIFY BASE REGISTER
* CONTINUE SETUP OF PARMS
         L     4,0(8)              GET LOCATION FROM WHICH TO COPY
         LR    5,3                 COPY STRING LENGTH
* INITIALIZE DYNAMIC STORAGE AREA
         LA    7,INITEND-INITBEG   GET LENGTH OF INIT AREA
         BCTR  7,0                 SUBTRACT ONE FOR MOVE
         EX    7,INITMVC           MVC   TARGET,INITBEG
* VERIFY NON-PROTECTION OF DESTINATION
         LR    6,2                 TEST VALIDITY OF DESTINATION
         LR    7,3                 ..
         SR    8,8                 SET FROM ADDRESS TO ZERO
         SR    9,9                 SET FROM LENGTH/PAD TO ZERO
         MVCL  6,8                 CLEAR TO-STR, OC4? YES=USER ERROR
* INITIALIZE STRING WITH UNSUCCESSFUL MESSAGE
         LR    7,3                 GET THE LENGTH OF DESTINATION STR
         LA    9,32                GET THE MAX LENGTH OF MSG
         CR    7,9                 IS THE DESTINATION SMALL?
         BNH   SMALLER             YES, USE ITS LENGTH
         LR    7,9                 NO, USE THE MAX LENGTH OF MSG
SMALLER  LR    6,2                 GET DESTINATION ADDRESS
         BCTR  7,0                 SUBTRACT ONE FOR MOVE
         EX    7,MVMSG             MVC   0(0,6),INITMSG
* MAIN PROCESSING
         L     10,16               CVT ADDR
         USING CVT,10              CVT ADDRESSABILITY
         LA    6,NSI               RETURN POINT FOR SPIE/ESPIE
         TM    CVTDCB,CVTMVSE      ARE WE ON XA?
         BNO   S370                NO, SKIP XA STUFF
         BSM   6,0                 GET ADDRESSING MODE
         ST    6,FIXPSW            SAVE FOR ESPIE EXIT
         ESPIE SET,MF=(E,ESPIELST) SET UP ESPIE
         B     STOKEN              SKIP ESPIE
S370     ST    6,FIXPSW            SAVE FOR SPIE EXIT
         SPIE  MF=(E,MYSPIE)       SET UP SPIE
STOKEN   ST    1,TOKEN             SAVE OLD SPIE/ESPIE FOR LATER
         CALL  TSOSET              TSOSET
         MODESET MF=(E,ENABLE)
         TM    CVTDCB,CVTMVSE      ARE WE ON XA?
         BNO   MVCL                NO, SKIP XA STUFF
         L     1,HIGHBIT           NOW SET 31 BIT ADDRESSING
         BSM   0,1                 ..
HIGHBIT  DC    A(MVCL+X'80000000') ..
MVCL     MVCL  2,4                 MOVE INTO STR FROM LOCATION
         TM    CVTDCB,CVTMVSE      ARE WE ON XA?
         BNO   NSI                 NO
         L     1,FIXPSW            RESTORE ADDR MODE
         BSM   0,1                 ..
NSI      MODESET MF=(E,DISABLE)
         CALL  TSORST              TSORST
         TM    CVTDCB,CVTMVSE      ARE WE ON XA?
         BNO   RESSPIE             NO
         ESPIE RESET,TOKEN         RESET ESPIE
         B     FINISH              SKIP SPIE
RESSPIE  L     1,TOKEN             RESTORE SPIE ENVIRONMENT
         SPIE  MF=(E,(1))          ..
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
*** ESPIE/SPIE EXIT ROUTINE *******************************************
***********************************************************************
ESPIEXIT EQU   *
         L     3,FIXPSW            GET NEW PSW NSI
         ST    3,76(1)             SAVE IN PSW FOR RETURN
         BR    14                  RETURN
SPIEEXIT EQU   *
         L     3,FIXPSW            GET NEW PSW NSI
         ST    3,8(1)              SAVE IN PSW FOR RETURN
         BR    14                  RETURN
***********************************************************************
*** STATIC STORAGE AREA ***********************************************
***********************************************************************
INITMVC  MVC   TARGET,INITBEG      OBJECT OF EX
MVMSG    MVC   0(0,6),INITMSG      OBJECT OF EX
INITMSG  DC    C'--- UNABLE TO OBTAIN ADDRESS ---'
INITBEG  DS    0F
         ESPIE SET,ESPIEXIT,(4),MF=L
         SPIE  SPIEEXIT,(4),MF=L
         MODESET KEY=ZERO,MF=L
         MODESET KEY=NZERO,MF=L
INITEND  EQU   *
         LTORG
***********************************************************************
*** DYNAMIC STORAGE AREA **********************************************
***********************************************************************
STORAGE  DSECT
SAVEAREA DS    22F
FIXPSW   DS    F
TOKEN    DS    F
TARGET   DS    0F
ESPIELST ESPIE SET,ESPIEXIT,(4),MF=L
MYSPIE   SPIE  SPIEEXIT,(4),MF=L
ENABLE   MODESET KEY=ZERO,MF=L
DISABLE  MODESET KEY=NZERO,MF=L
STOREND  DS    0D
         CVT   DSECT=YES
         END
