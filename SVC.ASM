SVCA     CSECT
* SVC  VERSION 2.0  BY CLYDE THOMAS ZUBER                             *
***********************************************************************
*                                                                     *
* ATTR:  RENT,REUS,REFR,AMODE(31),RMODE(ANY)                          *
*                                                                     *
* PROGRAM DESCRIPTION:
*                                                                     *
* THIS SUBROUTINE IS FOR USE WITH HIGHER LEVEL LANGUAGES.  IT         *
* PROVIDES THE CAPABILITY TO PERFORM SUPERVISOR CALLS.  THERE ARE     *
* THREE REQUIRED PARAMETERS TO SVC.  THE FIRST IS A HALF WORD WITH    *
* THE SVC NUMBER IN IT.  THE SECOND IS THE VALUE FOR REGISTER ZERO    *
* AND THE THIRD IS THE VALUE FOR REGISTER ONE.  BOTH ARE FULL WORD    *
* VALUES.  A RETURN CODE IS RETURNED VIA REGISTER FIFTEEN.            *
*                                                                     *
* THIS ROUTINE HAS TWO ENTRY POINTS.  SVCA IS FOR REGULAR OS/370      *
* LINKAGE.  SVC IS FOR PL/I PROGRAMS USING PL/I OPTIMIZER R3.1, R4.0  *
* AND R5.0 CONVENTIONS.                                               *
*                                                                     *
* THIS ROUTINE SHOULD BE DECLARED IN PL/I AS FOLLOWS:                 *
*     DECLARE  SVC  ENTRY(FIXED BINARY, FIXED BINARY(31),             *
*              FIXED BINARY(31)) OPTIONS(ASM, INTER, RETCODE);        *
*                                                                     *
* NOTE:  PL/I ERROR MSG OFFSETS ARE RELATIVE TO REAL ENTRY POINT      *
*        R11 - PROCEDURE BASE                                         *
*        R12 - RESERVED                                               *
*        R13 - ADDRESS OF DYNAMIC STORAGE AREA                        *
*                                                                     *
***********************************************************************
         EJECT
SVCA     AMODE 31
SVCA     RMODE ANY
***********************************************************************
*** REGULAR OS ENTRY POINT ********************************************
***********************************************************************
         USING *,15                IDENTIFY BASE REGISTER
         B     START               SKIP IDENTIFICATION SECTION
         DC    AL1(3)              IDENTIFCATION SECTION
         DC    C'SVC V2.0  BY CLYDE THOMAS ZUBER'
START    STM   14,12,12(13)        STORE REGISTERS
         LR    2,1                 ADDRESS OF PARM ADDR LIST
         GETMAIN R,LV=STOREND-STORAGE
         L     15,16(13)           RESTORE R15 (BASE REG)
         ST    13,4(1)             CHAIN SAVE AREAS
         ST    1,8(13)             ..
         MVI   0(1),X'00'          CLEAR FLAG (WILL DO FREEMAIN)
         LR    13,1                POINT TO DSA
         USING STORAGE,13          ..
         B     SVCPROC             SKIP OTHER ENTRY CODE
         EJECT
***********************************************************************
*** PL/I REAL ENTRY - PROLOGUE CODE ***********************************
***********************************************************************
         ENTRY SVC
         DC    C'SVC'              IDENTIFCATION SECTION
         DC    AL1(3)              ..
SVC      DS    0H
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
         EJECT
***********************************************************************
*** PROCEDURE BASE ****************************************************
***********************************************************************
SVCPROC  BALR  11,0                RESET BASE ADDRESS
         USING *,11                IDENTIFY BASE REGISTER
         LM    2,4,0(2)            GET PARAMETERS' ADDRESSES
         L     0,0(3)              LOAD REGISTER ZERO
         L     1,0(4)              LOAD REGISTER ONE
         LH    2,0(2)              GET SVC NUMBER
         EX    2,SVCINST           ISSUE SVC
***********************************************************************
*** EPILOGUE CODE *****************************************************
***********************************************************************
         LR    1,13                COPY R13
         L     13,4(13)            RESTORE R13
         ST    15,16(13)           SAVE RETURN CODE
         TM    0(1),X'80'          IS DSA FROM PL/I?
         BO    RETURN              YES, NO FREEMAIN REQUIRED
         LA    0,STOREND-STORAGE   GET LENGTH
         FREEMAIN R,LV=(0),A=(1)   FREE DSA
RETURN   LM    14,12,12(13)        RESTORE CALLER'S REGISTERS
         BR    14                  RETURN
SVCINST  SVC   0                   SVC INSTRUCTION
***********************************************************************
*** DYNAMIC STORAGE AREA **********************************************
***********************************************************************
STORAGE  DSECT
SAVEAREA DS    22F
STOREND  DS    0D
         END
