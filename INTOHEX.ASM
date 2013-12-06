INTOHEXA CSECT
* INTOHEX  VERSION 2.0  BY CLYDE THOMAS ZUBER                         *
***********************************************************************
*                                                                     *
* ATTR:  RENT,REUS,REFR,AMODE(31),RMODE(ANY)                          *
*                                                                     *
* PROGRAM DESCRIPTION:                                                *
*                                                                     *
* THIS SUBROUTINE CHANGES A CHARACTER STRING INTO A STRING IN HEX     *
* FORMAT.  THE HEX FORMAT IS MADE UP OF THE CHARACTERS (0-9,A-F) AS   *
* IN DUMPS, THEREFORE THE RESULT IS TWICE AS LONG AS THE INPUT.       *
* IF THE RECIEVING STRING IS TOO SHORT THE RESULT WILL BE TRUNCATED.  *
* THIS ROUTINE HAS TWO ENTRY POINTS.  INTOHEXA IS FOR REGULAR OS/370  *
* LINKAGE FOR ASSEMBLER PROGRAMS.  INTOHEX IS FOR PL/I PROGRAMS USING *
* PL/I OPTIMIZER R3.1, R4.0 AND R5.0 CONVENTIONS.                     *
*                                                                     *
***********************************************************************
*                                                                     *
* ENTRY INTOHEXA:                                                     *
*                                                                     *
* STRING AND RESULT ARE ASSUMED TO BE VARYING LENGTH (AS PL/I) OR     *
* ALTERNATELY, FOUR ARGUMENTS MAY BE PASSED AND THEN THE LAST TWO ARE *
* HALFWORDS SPECIFING THE LENGTH OF THE STRING AND RESULT FIELDS      *
* RESPECTIVELY.                                                       *
*                                                                     *
* BE SURE AND MAKE THE RESULT STRING LENGTH THE ACTUAL LENGTH OF THE  *
* STORAGE AREA FOR THE STRING.  THIS WILL BE CHANGED TO THE ACTUAL    *
* RESULT LENGTH ON RETURN FOR VARYING LENGTH FORMAT AND PADDED WITH   *
* BLANKS FOR THE FOUR PARAMETER FIXED LENGTH FORMAT.                  *
*                                                                     *
* FOR VARYING LENGTH SET UP THE CALL AND VARIABLES LIKE THIS:         *
*               CALL  INTOHEXA,(STR,RESULT),VL                        *
*      STR      DC    H'50'   THE LENGTH OF THE STRING                *
*               DS    CL50    THE STRING ITSELF                       *
*      RESULT   DC    H'100'  THE LENGTH OF THE STRING                *
*               DS    CL100   THE STRING ITSELF                       *
*                                                                     *
***********************************************************************
*                                                                     *
* ENTRY INTOHEX:                                                      *
*                                                                     *
* THE STRING DESCRIPTOR BLOCKS ARE PASSED AS PARAMETERS.  THIS MEANS  *
* THAT THE STRINGS MAY BE EITHER FIXED OR VARYING LENGTH. THE CONTROL *
* BLOCK FORMAT IS AS FOLLOWS:                                         *
*  0         1         2         3          4                         *
*  ------------------------------------------                         *
*  | BYTE ADDR OF CHAR STRING               |                         *
*  ------------------------------------------                         *
*  | DCL LENGTH        |X| UNUSED|          |                         *
*  ------------------------------------------                         *
*                   X:  0=FIXED (1=VARYING)                           *
*                                                                     *
* WHEN USING THE INTOHEX ENTRY FROM PL/I IT SHOULD BE DECLARED AS A   *
* PL/I PROCEDURE AS FOLLOWS:                                          *
*      DECLARE  INTOHEX  ENTRY;  /* REALLY ASM */                     *
*                                                                     *
* THE PARAMETERS THEN SHOULD BE CHAR, EITHER FIXED OR VARYING.        *
* THE FIRST PARAMETER IS THE INPUT STRING AND THE SECOND PARAMETER IS *
* THE HEX RESULT.  IF THE RESULT IS A VARYING LENGTH STRING THE       *
* MAXIMUM LENGTH USED WILL BE THE DECLARED LENGTH NOT THE LENGTH AT   *
* THE TIME OF INVOCATION.  AS FOR THE ASSEMBLER ENTRY POINT A FIXED   *
* LENGTH RESULT WILL BE PADDED WITH BLANKS IF NECESSARY AND THE       *
* VARYING LENGTH RESULT WILL BE SET WITH THE CORRECT LENGTH UP TO THE *
* MAXIMUM.                                                            *
*                                                                     *
***********************************************************************
*                                                                     *
* NOTE:  PL/I ERROR MSG OFFSETS ARE RELATIVE TO REAL ENTRY POINT      *
*        R11 - PROCEDURE BASE                                         *
*        R12 - RESERVED                                               *
*        R13 - ADDRESS OF DYNAMIC STORAGE AREA                        *
*                                                                     *
***********************************************************************
         EJECT
INTOHEXA AMODE 31
INTOHEXA RMODE ANY
***********************************************************************
*** ASSEMBLER ENTRY POINT *********************************************
***********************************************************************
         USING *,15                IDENTIFY BASE REGISTER
         B     START               SKIP IDENTIFICATION SECTION
         DC    AL1(7)              PROGRAM IDENTIFIER
         DC    C'INTOHEX V2.0  BY CLYDE THOMAS ZUBER'
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
         LM    2,3,8(2)            GET ADDRESS OF 3RD & 4TH ARGUMENTS
         LH    4,0(2)              LENGTH OF STR
         LH    5,0(3)              LENGTH OF RESULT
         LR    2,8                 COPY BEGIN ADDR OF STR
         LR    3,9                 COPY BEGIN ADDR OF RESULT
         LA    6,0                 PAD FOR FIXED LENGTH FORMAT RESULT
         B     SAVEPARM            SKIP OTHER PARMS (AND ENTRY POINT)
PARM2    EQU   *
         LA    2,2(8)              ADDR OF STR
         LA    3,2(9)              ADDR OF RESULT
         LH    4,0(8)              LENGTH OF STR
         LH    5,0(9)              LENGTH OF RESULT
         LR    6,9                 ADDR OF WHERE CHANGE RESULT LENGTH
         B     SAVEPARM            SKIP OTHER ENTRY POINT
         EJECT
***********************************************************************
*** PL/I REAL ENTRY - PROLOGUE CODE ***********************************
***********************************************************************
         ENTRY INTOHEX
         DC    C'INTOHEX'          PROGRAM IDENTIFIER
         DC    AL1(7)              ..
INTOHEX  DS    0H
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
         L     2,0(8)              ADDR OF STR FROM DESCRIPTOR
         L     3,0(9)              ADDR OF RESULT FROM DESCRIPTOR
         TM    6(8),X'80'          IS IT VARYING?
         BZ    FIXSTR              NO, FIXED LENGTH STRING
         LH    4,0(2)              VARYING LENGTH OF STR
         LA    2,2(2)              REAL ADDR OF STR
         B     DONESTR
FIXSTR   LH    4,4(8)              FIXED LENGTH OF STRING
DONESTR  EQU   *
         LH    5,4(9)              MAX LENGTH OF RES (VARYING OR FIXED)
         TM    6(9),X'80'          IS IT VARYING?
         BZ    FIXRES              NO, FIXED LENGTH RESULT
         LR    6,3                 ADDR OF WHERE TO CHANGE RESULT LEN
         LA    3,2(3)              REAL ADDR OF STR
         B     SAVEPARM
FIXRES   LA    6,0                 PAD FOR FIXED LENGTH RESULT
         EJECT
***********************************************************************
*** PROCEDURE BASE ****************************************************
***********************************************************************
SAVEPARM EQU   *
         BALR  11,0                RESET BASE ADDRESS
         USING *,11                IDENTIFY BASE REGISTER
         LTR   5,5                 IS RESULT MAX LENGTH ZERO?
         BZ    RETURN              YES, BYE BYE
         LA    8,0                 INITIALIZE RESLEFT
         ST    8,RESLEFT           ..
         ST    3,RESADDR           SAVE REGISTER 3 ADDR OF RESULT
         ST    5,RESMAX            SAVE REGISTER 5 MAX RESULT LENGTH
         ST    6,ADDRLEN           SAVE REGISTER 6 FOR TERMINATION
         LA    8,4                 BXLE LOOP INCREMENT
         LR    9,2                 COMPUTE END ADDR FOR STR
         AR    9,4                 ..
         BCTR  9,0                 ..
         LA    6,8                 BXH  LOOP INCREMENT
         LR    7,3                 COMPUTE END ADDR FOR RESULT + 1
         AR    7,5                 ..
         LR    4,3                 COPY START ADDR OF RESULT
         B     INITPT              JUMP INTO THE MIDDLE OF THE LOOP
LOOP     EQU   *
         BXH   4,6,REMAINS         IS THERE MORE ROOM LEFT IN RESULT?
         MVC   0(8,3),HEXFIELD     MOVE IN ANOTHER 8
         SR    5,6                 KEEP TRACK OF HOW MUCH ROOM LEFT
         BNP   FINISH              ZERO LENGTH => NO MOVE
         LR    3,4                 MOVE POSITION UP IN RESULT
INITPT   EQU   *
         UNPK  HEXFIELD(9),0(5,2)  HEXIFY ANOTHER 4 BYTES
         BXLE  2,8,LOOP            ARE WE AT THE END OF OUR STRING?
REMAINS  EQU   *
         SR    2,8                 BACK UP FOR MVCL PROCESSING
         LR    4,3                 CURRENT POS IN RESULT (R5 READY)
         LA    6,HEXFIELD          ADDR TO MOVE FROM
         LR    7,9                 END POS OF STR
         LA    7,1(7)              LENGTH OF STR LEFT TO BE MOVED
         SR    7,2                 ..
         SLL   7,1                 ..
         LR    2,5                 GET LENGTH OF RESULT FIELD NOT USED
         SR    2,7                 ..
         BNP   SKIPSAVE            GOING TO USE IT ALL
         ST    2,RESLEFT           SAVE FOR FINISH
SKIPSAVE ICM   7,B'1000',=C' '     PADDING BYTE
         MVCL  4,6                 FINAL TOUCH
FINISH   EQU   *
         L     3,RESMAX            COMPUTE TOTAL LENGTH
         L     4,RESLEFT           ..
         SR    3,4                 ..
         BNP   NOTRANS
         L     5,RESADDR           ADDR OF RESULT HEX STRING
         BCTR  3,0                 LESS ONE FOR TRANSLATE LENGTH
         EX    3,TRANS             TR  0(0,5),TABLE
NOTRANS  L     2,ADDRLEN           DO WE NEED TO CHANGE THE LENGTH?
         LTR   2,2                 ..
         BZ    RETURN              NO
         LA    3,1(3)              ADD ONE TO TRANSLATE LENGTH
         STH   3,0(2)              SET IT FOR CALLER
***********************************************************************
*** EPILOGUE CODE *****************************************************
***********************************************************************
RETURN   DS    0H
         LR    1,13                COPY R13
         L     13,4(13)            RESTORE R13
*********ST****15,16(13)***********SAVE*RETURN*CODE********************
         TM    0(1),X'80'          IS DSA FROM PL/I?
         BO    REALRTN             YES, NO FREEMAIN REQUIRED
         LA    0,STOREND-STORAGE   GET LENGTH
         FREEMAIN R,LV=(0),A=(1)   FREE DSA
REALRTN  LM    14,12,12(13)        RESTORE CALLER'S REGISTERS
         BR    14                  RETURN
***********************************************************************
*** STATIC STORAGE AREA ***********************************************
***********************************************************************
TRANS    TR    0(0,5),TABLE
* TABLE USED TO TRANSLATE FA-FF TO C1-C6 (IE. 10-15 TO CHARS A-F)
TABLE    EQU   *-180
         DS    60X
         DC    C'0123456789ABCDEF'
***********************************************************************
*** DYNAMIC STORAGE AREA **********************************************
***********************************************************************
STORAGE  DSECT
SAVEAREA DS    22F
RESMAX   DS    F
RESADDR  DS    F
RESLEFT  DS    F
ADDRLEN  DS    F
HEXFIELD DS    10C
STOREND  DS    0D
         END
