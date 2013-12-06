PRTABLEA CSECT
* PRTABLE  VERSION 2.0  BY CLYDE THOMAS ZUBER                         *
***********************************************************************
*                                                                     *
* ATTR:  RENT,REUS,REFR,AMODE(31),RMODE(ANY)                          *
*                                                                     *
* PROGRAM DESCRIPTION:                                                *
*                                                                     *
* THIS SUBROUTINE TRANSLATES THE BYTES OF A STRING PARAMETER TO ONLY  *
* PRINTABLE CHARACTERS.  ALL NONPRINTABLE CHARACTERS ARE TRANSLATED   *
* TO PERIODS AS IN DUMPS.                                             *
*                                                                     *
* THIS ROUTINE HAS TWO ENTRY POINTS.  PRTABLEA IS FOR REGULAR OS/370  *
* LINKAGE FOR ASSEMBLER PROGRAMS.  PRTABLE IS FOR PL/I PROGRAMS USING *
* PL/I OPTIMIZER R3.1, R4.0 AND R5.0 CONVENTIONS.                     *
*                                                                     *
* ENTRY PRTABLEA:                                                     *
* STRING IS ASSUMED TO BE VARYING LENGTH (AS PL/I) OR                 *
* ALTERNATELY, TWO ARGUMENTS MAY BE PASSED AND THEN THE LAST ONE IS A *
* HALFWORD SPECIFING THE LENGTH OF THE STRING.                        *
* FOR VARYING LENGTH SET UP THE CALL AND VARIABLES LIKE THIS:         *
*               CALL  PRTABLEA,(STR),VL                               *
*      STR      DC    H'50'   THE LENGTH OF THE STRING                *
*               DS    CL50    THE STRING ITSELF                       *
*                                                                     *
* ENTRY PRTABLE:                                                      *
* THE STRING DESCRIPTOR BLOCK IS PASSED AS A PARAMETER.  THIS MEANS   *
* THAT THE STRING MAY BE EITHER FIXED OR VARYING LENGTH. THE CONTROL  *
* BLOCK FORMAT IS AS FOLLOWS:                                         *
*  0         1         2         3          4                         *
*  ------------------------------------------                         *
*  | BYTE ADDR OF CHAR STRING               |                         *
*  ------------------------------------------                         *
*  | DCL LENGTH        |X| UNUSED|          |                         *
*  ------------------------------------------                         *
*                       0=FIXED                                       *
*                       1=VARYING                                     *
*                                                                     *
* WHEN USING THE PRTABLE ENTRY FROM PL/I IT SHOULD BE DECLARED AS A   *
* PL/I PROCEDURE AS FOLLOWS:                                          *
*      DECLARE  PRTABLE  ENTRY;                                       *
* THE PARAMETER THEN SHOULD BE CHAR, EITHER FIXED OR VARYING.         *
*                                                                     *
* NOTE:  PL/I ERROR MSG OFFSETS ARE RELATIVE TO REAL ENTRY POINT      *
*        R11 - PROCEDURE BASE                                         *
*        R12 - RESERVED                                               *
*        R13 - ADDRESS OF DYNAMIC STORAGE AREA                        *
*                                                                     *
***********************************************************************
         EJECT
PRTABLEA AMODE 31
PRTABLEA RMODE ANY
***********************************************************************
*** ASSEMBLER ENTRY POINT *********************************************
***********************************************************************
         USING *,15                IDENTIFY BASE REGISTER
         B     START               SKIP IDENTIFICATION SECTION
         DC    AL1(7)              PROGRAM IDENTIFIER
         DC    C'PRTABLE V2.0  BY CLYDE THOMAS ZUBER'
START    STM   14,12,12(13)        STORE REGISTERS
         LR    2,1                 ADDRESS OF PARM ADDR LIST
         GETMAIN R,LV=STOREND-STORAGE
         L     15,16(13)           RESTORE R15 (BASE REG)
         ST    13,4(1)             CHAIN SAVE AREAS
         ST    1,8(13)             ..
         MVI   0(1),X'00'          CLEAR FLAG (WILL DO FREEMAIN)
         LR    13,1                POINT TO DSA
         USING STORAGE,13          ..
         L     9,0(2)              GET PARM ADDR
         LTR   9,9                 IS THERE ANOTHER ARGUMENT?
         BM    PARM1               NO, ONLY ONE
         L     8,4(2)              GET SECOND PARM ADDR
         LR    2,9
         LH    3,0(8)
         B     GOTPARMS            SKIP OTHER ENTRY CODE
PARM1    EQU   *
         LA    2,2(9)              ADDR OF STR
         LH    3,0(9)              LENGTH OF STR
         B     GOTPARMS            SKIP OTHER ENTRY CODE
         EJECT
***********************************************************************
*** PL/I REAL ENTRY - PROLOGUE CODE ***********************************
***********************************************************************
         ENTRY PRTABLE
         DC    C'PRTABLE'          PROGRAM IDENTIFIER
         DC    AL1(7)              ..
PRTABLE  DS    0H
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
         L     9,0(2)              GET PARM ADDR
         L     2,0(9)              GET ADDR OF STR (MAYBE)
         TM    6(9),X'80'          IS IT VARYING?
         BZ    FIXSTR
         LH    3,0(2)              VARYING LENGTH OF STR
         LA    2,2(2)              REAL ADDR OF STR
         B     GOTPARMS
FIXSTR   LH    3,4(9)
         EJECT
***********************************************************************
*** PROCEDURE BASE ****************************************************
***********************************************************************
GOTPARMS EQU   *
         BALR  11,0                RESET BASE ADDRESS
         USING *,11                IDENTIFY BASE REGISTER
         BCTR  3,0                 DECREMENT FOR EX
         EX    3,TRANS             TR  0(0,2),TABLE
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
TRANS    TR    0(0,2),TABLE
TABLE    DC    64C'.'              INSERT A '.' EVERYWHERE
         DC    C' '                EXCEPT FOR BLANK
         DC    9C'.'
         DC    C'›.<(+|&&'         AND  ›.<(+|&
         DC    9C'.'
         DC    C'!$*);ª-/'         AND  !$*);ª-/
         DC    8C'.'
         DC    C'³,%_>?'           AND  ³,%_>?
         DC    9C'.'
         DC    C'`:#@''="'         AND  `:#@'="
         DC    C'.abcdefghi'       AND  LOWER CASE LETTERS
         DC    7C'.'
         DC    C'jklmnopqr'        ...
         DC    7C'.'
         DC    C'~'
         DC    C'stuvwxyz'         ...
         DC    22C'.'
         DC    C'{'
         DC    C'ABCDEFGHI'        AND  UPPER CASE LETTERS
         DC    6C'.'
         DC    C'}'
         DC    C'JKLMNOPQR'        ...
         DC    6C'.'
         DC    C'\'
         DC    C'.STUVWXYZ'        ...
         DC    6C'.'
         DC    C'0123456789'       AND  DIGITS 0-9
         DC    6C'.'
***********************************************************************
*** DYNAMIC STORAGE AREA **********************************************
***********************************************************************
STORAGE  DSECT
SAVEAREA DS    22F
STOREND  DS    0D
         END
