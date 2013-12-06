VERIFYA  CSECT
* VERIFY   VERSION 4.0  BY CLYDE THOMAS ZUBER                         *
***********************************************************************
*                                                                     *
* ATTR:  RENT,REUS,REFR,AMODE(31),RMODE(ANY)                          *
*                                                                     *
* PROGRAM DESCRIPTION:                                                *
*                                                                     *
* THIS SUBROUTINE FINDS THE POSITION OF FIRST CHARACTER IN A STRING   *
* WHICH DOES NOT OCCUR IN A SECOND STRING.   THE FIRST ARGUMENT IS    *
* THE STRING TO BE SEARCHED.  THE SECOND IS THE LIST OF VALID         *
* CHARACTERS TO TEST THE FIRST STRING BY.  IF ALL THE CHARACTERS IN   *
* THE FIRST STRING ARE FOUND IN THE SECOND A VALUE OF ZERO IS         *
* RETURNED IN THE THIRD ARGUMENT.  IF AN INVALID CHARACTER IS FOUND   *
* ITS POSITION IS RETURNED.                                           *
*                                                                     *
* THIS ROUTINE HAS TWO ENTRY POINTS.  VERIFYA IS FOR REGULAR OS/370   *
* LINKAGE FOR ASSEMBLER PROGRAMS.  VERIFY IS FOR PL/I PROGRAMS USING  *
* PL/I OPTIMIZER R3.1, R4.0 AND R5.0 CONVENTIONS.                     *
*                                                                     *
* ENTRY VERIFYA:                                                      *
* STRING AND LIST ARE ASSUMED TO BE VARYING LENGTH (AS PL/I) OR       *
* ALTERNATELY, FIVE ARGUMENTS MAY BE PASSED AND THEN THE LAST TWO ARE *
* HALFWORDS SPECIFING THE LENGTH OF THE STRING AND LIST RESPECTIVELY. *
* FOR VARYING LENGTH SET UP THE CALL AND VARIABLES LIKE THIS:         *
*               CALL  VERIFYA,(STR,LIST,ANSWER),VL                    *
*      ANSWER   DS    F       THE RETURN VALUE                        *
*      STR      DC    H'50'   THE LENGTH OF THE STRING                *
*               DS    CL50    THE STRING ITSELF                       *
*      LIST     DC    H'10'   THE LENGTH OF THE STRING                *
*               DS    CL10    THE STRING ITSELF                       *
*                                                                     *
* ENTRY VERIFY:                                                       *
* THE STRING DESCRIPTOR BLOCKS ARE PASSED AS PARAMETERS.  THIS MEANS  *
* THAT THE STRINGS MAY BE EITHER FIXED OR VARYING LENGTH. THE CONTROL *
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
* WHEN USING THE VERIFY ENTRY FROM PL/I IT SHOULD BE DECLARED AS A    *
* PL/I PROCEDURE AS FOLLOWS:                                          *
*      DECLARE  VERIFY ENTRY RETURNS(FIXED BINARY(31));               *
* THE TWO PARAMETERS THEN SHOULD BE CHAR, EITHER FIXED OR VARYING.    *
* THE RETURNS(FIXED BINARY(31)) WORKS BECAUSE PL/I CREATES A THIRD    *
* ARGUMENT TO OBTAIN ITS RETURN VALUE.                                *
*                                                                     *
* NOTE:  PL/I ERROR MSG OFFSETS ARE RELATIVE TO REAL ENTRY POINT      *
*        R11 - PROCEDURE BASE                                         *
*        R12 - RESERVED                                               *
*        R13 - ADDRESS OF DYNAMIC STORAGE AREA                        *
*                                                                     *
***********************************************************************
         EJECT
VERIFYA  AMODE 31
VERIFYA  RMODE ANY
***********************************************************************
*** ASSEMBLER ENTRY POINT *********************************************
***********************************************************************
         USING *,15                IDENTIFY BASE REGISTER
         B     START               SKIP IDENTIFICATION SECTION
         DC    AL1(6)              PROGRAM IDENTIFIER
         DC    C'VERIFY V4.0  BY CLYDE THOMAS ZUBER'
START    STM   14,12,12(13)        STORE REGISTERS
         LR    2,1                 ADDRESS OF PARM ADDR LIST
         GETMAIN R,LV=STOREND-STORAGE
         L     15,16(13)           RESTORE R15 (BASE REG)
         ST    13,4(1)             CHAIN SAVE AREAS
         ST    1,8(13)             ..
         MVI   0(1),X'00'          CLEAR FLAG (WILL DO FREEMAIN)
         LR    13,1                POINT TO DSA
         USING STORAGE,13          ..
         LM    7,9,0(2)            ADDRESS OF FIRST - THIRD ARGUMENTS
         LTR   9,9                 ARE THERE MORE ARGUMENTS?
         BM    PARM3               NO, ONLY THREE
         LM    2,3,12(2)           GET ADDRESS OF 4TH - 5TH ARGUMENT
         LH    4,0(2)              LENGTH OF STR
         LH    5,0(3)              LENGTH OF LIST
         LR    2,7                 COPY BEGIN ADDR OF STR
         LR    3,8                 COPY BEGIN ADDR OF LIST
         B     SAVEPARM            SKIP OTHER OTHER PARMS(+ENTRY POINT)
PARM3    LA    2,2(7)              ADDR OF STR
         LA    3,2(8)              ADDR OF LIST
         LH    4,0(7)              LENGTH OF STR
         LH    5,0(8)              LENGTH OF LIST
         B     SAVEPARM            SKIP OTHER ENTRY POINT
         EJECT
***********************************************************************
*** PL/I REAL ENTRY - PROLOGUE CODE ***********************************
***********************************************************************
         ENTRY VERIFY
         DC    C' VERIFY'          PROGRAM IDENTIFIER
         DC    AL1(6)              ..
VERIFY   DS    0H
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
         LM    7,9,0(2)            ADDRESS OF ARGUMENTS
         L     2,0(7)              ADDR OF STR
         L     3,0(8)              ADDR OF LIST
         TM    6(7),X'80'          IS IT VARYING?
         BZ    FIXSTR              NO, FIXED LENGTH STR
         LH    4,0(2)              VARYING LENGTH OF STR
         LA    2,2(2)              REAL ADDR OF STR
         B     DONESTR
FIXSTR   LH    4,4(7)              FIXED LENGTH OF STR
DONESTR  TM    6(8),X'80'          IS IT VARYING?
         BZ    FIXLIST             NO, FIXED LENGTH LIST
         LH    5,0(3)              VARYING LENGTH OF LIST
         LA    3,2(3)              REAL ADDR OF LIST
         B     SAVEPARM
FIXLIST  LH    5,4(8)              FIXED LENGTH OF LIST
         EJECT
***********************************************************************
*** PROCEDURE BASE ****************************************************
***********************************************************************
SAVEPARM EQU   *
         BALR  11,0                RESET BASE ADDRESS
         USING *,11                IDENTIFY BASE REGISTER
         ST    2,STRADDR           SAVE PARAMETERS
         ST    3,LSTADDR           ..
         LA    6,0                 ZERO
         ST    6,0(9)              INITIALIZE ANSWER
         LTR   4,4                 IS STR LENGTH ZERO?
         BZ    RETURN              YES, BYE
         LTR   5,5                 IS LIST LENGTH ZERO?
         BZ    RETURN              YES, BYE BYE
         AR    5,3                 COMPUTE END ADDRESS OF LIST
         BCTR  5,0                 ..
         AR    4,2                 COMPUTE END ADDRESS OF STR
         BCTR  4,0                 ..
         LR    7,4
         LA    4,1                 CONSTANT INCREMENT
         LA    6,1                 CONSTANT INCREMENT
SEARCH   L     3,LSTADDR           SET UP FOR SEARCH THROUGH LIST
INDEX    CLC   0(1,3),0(2)         REG2 POINTS TO A CHAR IN STR
         BE    FOUND               IF IT IS IN LIST THEN QUIT LOOKING
         BXLE  3,4,INDEX           GET NEXT POSITION IN LIST
         B     EXCEPT              NEVER FOUND SO RETURN ITS POSITION
FOUND    BXLE  2,6,SEARCH          GET POSITION OF NEXT CHAR IN STR
         LA    2,0                 RETURN ZERO, THEY WERE ALL GOOD
         B     FINISH              ..
EXCEPT   S     2,STRADDR           GET OFFSET FROM BEGINNING
         LA    2,1(2)              GET POSITION FROM OFFSET
FINISH   ST    2,0(9)              SAVE ANSWER FOR CALLING PROGRAM
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
*** DYNAMIC STORAGE AREA **********************************************
***********************************************************************
STORAGE  DSECT
SAVEAREA DS    22F
LSTADDR  DS    F
STRADDR  DS    F
STOREND  DS    0D
         END
