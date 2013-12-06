TSOIDA   CSECT
* TSOID    VERSION 2.0  BY CLYDE THOMAS ZUBER                         *
***********************************************************************
*                                                                     *
* ATTR:  RENT,REUS,REFR,AMODE(31),RMODE(ANY)                          *
*                                                                     *
* PROGRAM DESCRIPTION:                                                *
*                                                                     *
* THIS ROUTINE HAS TWO ENTRY POINTS.  TSOIDA IS FOR REGULAR OS/370    *
* LINKAGE FOR ASSEMBLER PROGRAMS.  TSOID IS FOR PL/I PROGRAMS USING   *
* PL/I OPTIMIZER R3.1, R4.0 AND R5.0 CONVENTIONS.                     *
*                                                                     *
* THIS SUBROUTINE FINDS THE USERID AND OPTIONALLY THE PREFIX OF THE   *
* TSO SESSION INVOKING THE PROGRAM WHICH CALLS THIS ROUTINE.  THE     *
* ARGUMENTS ARE ASSUMED TO BE VARYING LENGTH (AS PL/I).               *
*                                                                     *
* ENTRY TSOIDA:                                                       *
* FOR VARYING LENGTH SET UP THE CALL AND VARIABLES LIKE THIS:         *
*               CALL  TSOIDA,(USERID,PREFIX),VL                       *
*               CALL  TSOIDA,(USERID),VL                              *
*      USERID   DS    H       THE LENGTH OF THE USERID                *
*               DS    CL7     THE USERID ITSELF                       *
*      PREFIX   DS    H       THE LENGTH OF THE PREFIX                *
*               DS    CL7     THE PREFIX ITSELF                       *
*                                                                     *
* ENTRY TSOID:                                                        *
* THIS ROUTINE MAY BE DECLARED IN PL/I AS FOLLOWS:                    *
*      DECLARE  USERID CHAR(7) VARYING;                               *
*      DECLARE  PREFIX CHAR(7) VARYING;                               *
*                                                                     *
*      DECLARE  TSOID  ENTRY(CHAR(*) VARYING, CHAR(*) VARYING)        *
*                      OPTIONS(ASM, INTER);                           *
*      CALL TSOID(USERID, PREFIX);                                    *
*                                                                     *
*      DECLARE  TSOID  ENTRY(CHAR(*) VARYING) OPTIONS(ASM, INTER);    *
*      CALL TSOID(USERID);                                            *
*                                                                     *
* NOTE:  PL/I ERROR MSG OFFSETS ARE RELATIVE TO REAL ENTRY POINT      *
*        R11 - PROCEDURE BASE                                         *
*        R12 - RESERVED                                               *
*        R13 - ADDRESS OF DYNAMIC STORAGE AREA                        *
*                                                                     *
***********************************************************************
         EJECT
TSOIDA   AMODE 31
TSOIDA   RMODE ANY
***********************************************************************
*** ASSEMBLER ENTRY POINT *********************************************
***********************************************************************
         USING *,15                IDENTIFY BASE REGISTER
         B     START               SKIP IDENTIFICATION SECTION
         DC    AL1(5)              PROGRAM IDENTIFIER
         DC    C'TSOID V2.0  BY CLYDE THOMAS ZUBER'
START    STM   14,12,12(13)        STORE REGISTERS
         LR    2,1                 ADDRESS OF PARM ADDR LIST
         GETMAIN R,LV=STOREND-STORAGE
         L     15,16(13)           RESTORE R15 (BASE REG)
         ST    13,4(1)             CHAIN SAVE AREAS
         ST    1,8(13)             ..
         MVI   0(1),X'00'          CLEAR FLAG (WILL DO FREEMAIN)
         LR    13,1                POINT TO DSA
         USING STORAGE,13          ..
         B     TSOIDPRC            SKIP OTHER ENTRY CODE
         EJECT
***********************************************************************
*** PL/I REAL ENTRY - PROLOGUE CODE ***********************************
***********************************************************************
         ENTRY TSOID
         DC    C'TSOID'       IDENTIFICATION SECTION
         DC    AL1(5)         ..
TSOID    DS    0H
         USING *,15                IDENTIFY BASE REGISTER
         STM   14,12,12(13)        SAVE REGISTERS
         LR    2,1                 SAVE PARAMETER LIST ADDRESS
         LA    0,STOREND-STORAGE   PUT THE LENGTH OF THE NEW DSA IN R0
         L     1,76(13)            PTR NEXT AVAIL BYTE AFTER LAST DSA
         ALR   0,1                 ADD THEM TOGETHER
         CL    0,12(12)            COMPARE WITH LAST AVAILABLE BYTE
         BNH   SPCAVAIL            IT WILL FIT
         L     15,116(12)          OBTAIN MORE STORAGE (PL/I TSOID)
         BALR  14,15               ..
SPCAVAIL L     14,72(13)           GET ADDR OF LSW FROM OLD DSA
         LR    15,0                COPY R0 (NAB AFTER NEW DSA)
         STM   14,0,72(1)          SAVE LSW AND NAB IN NEW DSA
         L     15,16(13)           RESTORE R15 (BASE REG)
         ST    13,4(1)             ADDR OF LAST DSA IN NEW DSA
         ST    1,8(13)             CHAIN SAVE AREA (NOT DONE BY PL/I)
         MVI   0(1),X'80'          SET FLAGS IN DSA TO PRESERVE PL/I
         MVI   1(1),X'00'              ERROR HANDLING IN THIS TSOID
         MVI   86(1),X'91'         ..
         MVI   87(1),X'C0'         ..
         LR    13,1                POINT TO NEW DSA
         USING STORAGE,13          ..
         EJECT
***********************************************************************
*** PROCEDURE BASE ****************************************************
***********************************************************************
TSOIDPRC EQU   *
         BALR  11,0                RESET BASE ADDRESS
         USING *,11                IDENTIFY BASE REGISTER
         L     4,0(2)              GET ADDRESS OF FIRST ARGUMENT
         LA    3,16                ADDR OF CVT PTR
         L     3,0(3)              CVT PTR
         L     3,0(3)              V(IEATCBP)
         L     3,12(3)             ADDR OF CURRENT ASCB
         L     3,108(3)            PTR TO ADDR SP EXTENSION (ASXB)
         L     3,4(3)              PTR TO FIRST TCB OF TCB QUEUE
         L     3,116(3)            ADDR OF NEXT TCB OF LOWER PRIORITY
         L     3,116(3)            ..
         L     3,116(3)            ..
         L     3,180(3)            ADDRESS OF JSCB
         L     3,264(3)            PTR TO PSCB
         MVC   2(7,4),0(3)         MOVE CHARACTER PORTION OF USERID
         MVI   0(4),X'00'          NULL OUT HIGH ORDER BYTE
         MVC   1(1,4),7(3)         MOVE LENGTH OF USERID
         LTR   4,4                 IS THERE A SECOND ARGUMENT?
         BM    FINISH              NO, ONLY WANTS USERID
         L     4,4(2)              GET ADDRESS OF SECOND ARGUMENT
         L     3,52(3)             PTR TO UPT
         MVC   2(7,4),16(3)        MOVE CHARACTER PORTION OF PREFIX
* FIND POSITION OF BLANK CHARACTER TO DETERMINE PREFIX LENGTH
         LA    7,2(4)              GET ADDR OF STR
         LA    8,1                 SET INCREMENT VALUE
         LA    9,6                 LENGTH OF STR-1
         AR    9,7                 ADDR OF END OF STR
INDEX    CLI   0(7),C' '           IS IT A BLANK?
         BE    FOUND               YES IT IS
         BXLE  7,8,INDEX           NO TRY NEXT ONE
FOUND    LA    9,2(4)              GET ADDR OF STR
         SR    7,9                 LENGTH OF STR BEFORE BLANK
         STH   7,0(4)              STORE LENGTH
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
         EJECT
***********************************************************************
*** DYNAMIC STORAGE AREA **********************************************
***********************************************************************
STORAGE  DSECT
SAVEAREA DS    22F
STOREND  DS    0D
         END
