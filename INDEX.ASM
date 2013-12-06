INDEXA   CSECT
* INDEX    VERSION 4.0  BY CLYDE THOMAS ZUBER                         *
***********************************************************************
*                                                                     *
* ATTR:  RENT,REUS,REFR,AMODE(31),RMODE(ANY)                          *
*                                                                     *
* PROGRAM DESCRIPTION:                                                *
*                                                                     *
* THIS SUBROUTINE FINDS THE POSITION OF ONE STRING WITHIN ANOTHER.    *
* THE FIRST ARGUMENT IS THE STRING TO BE SEARCHED.  THE SECOND        *
* ARGUMENT IS THE PATTERN TO BE FOUND.  THE THIRD ARGUMENT IS THE     *
* LOCATION IN WHICH TO RETURN THE POSITION.  IF IT IS NOT FOUND A     *
* VALUE OF ZERO IS RETURNED.  FIVE ARGUMENTS MAY ALSO BE USED AND     *
* PL/I CHAR STRINGS WITH RETURN MAY BE SPECIFIED AS DESCRIBED BELOW.  *
*                                                                     *
* THIS ROUTINE HAS TWO ENTRY POINTS.  INDEXA IS FOR REGULAR OS/370    *
* LINKAGE FOR ASSEMBLER PROGRAMS.  INDEX IS FOR PL/I PROGRAMS USING   *
* PL/I OPTIMIZER R3.1, R4.0 AND R5.0 CONVENTIONS.                     *
*                                                                     *
* ENTRY INDEXA:                                                       *
* STRING AND PATTERN ARE ASSUMED TO BE VARYING LENGTH (AS PL/I) OR    *
* ALTERNATELY, FIVE ARGUMENTS MAY BE PASSED AND THEN THE LAST TWO ARE *
* HALFWORDS SPECIFING THE LENGTH OF THE STRING AND PATTERN            *
* RESPECTIVELY.                                                       *
* FOR VARYING LENGTH SET UP THE CALL AND VARIABLES LIKE THIS:         *
*               CALL  INDEXA,(STR,PATTERN,ANSWER),VL                  *
*      ANSWER   DS    F       THE RETURN VALUE                        *
*      STR      DC    H'50'   THE LENGTH OF THE STRING                *
*               DS    CL50    THE STRING ITSELF                       *
*      PATTERN  DC    H'10'   THE LENGTH OF THE STRING                *
*               DS    CL10    THE STRING ITSELF                       *
*                                                                     *
* ENTRY INDEX:                                                        *
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
* WHEN USING THE INDEX ENTRY FROM PL/I IT SHOULD BE DECLARED AS A     *
* PL/I PROCEDURE AS FOLLOWS:                                          *
*      DECLARE  INDEX  ENTRY RETURNS(FIXED BINARY(31));               *
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
INDEXA   AMODE 31
INDEXA   RMODE ANY
***********************************************************************
*** ASSEMBLER ENTRY POINT *********************************************
***********************************************************************
         USING *,15                IDENTIFY BASE REGISTER
         B     START               SKIP IDENTIFICATION SECTION
         DC    AL1(5)              PROGRAM IDENTIFIER
         DC    C'INDEX V4.0  BY CLYDE THOMAS ZUBER'
START    STM   14,12,12(13)        STORE REGISTERS
         LR    2,1                 ADDRESS OF PARM ADDR LIST
         GETMAIN R,LV=STOREND-STORAGE
         L     15,16(13)           RESTORE R15 (BASE REG)
         ST    13,4(1)             CHAIN SAVE AREAS
         ST    1,8(13)             ..
         MVI   0(1),X'00'          CLEAR FLAG (WILL DO FREEMAIN)
         LR    13,1                POINT TO DSA
         USING STORAGE,13          ..
         LM    7,9,0(2)            ADDRESS OF FIRST THREE ARGUMENTS
         LTR   9,9                 ARE THERE MORE ARGUMENTS?
         BM    PARM3               NO, ONLY THREE
         LM    2,3,12(2)           GET ADDRESS OF 4TH AND 5TH ARGUMENTS
         LH    4,0(2)              LENGTH OF STR
         LH    5,0(3)              LENGTH OF PATTERN
         LR    2,7                 COPY BEGIN ADDR OF STR
         LR    3,8                 COPY BEGIN ADDR OF PATTERN
         B     SAVEPARM            SKIP OTHER PARM PASSING
PARM3    EQU   *
         LA    2,2(7)              ADDR OF STR
         LA    3,2(8)              ADDR OF PATTERN
         LH    4,0(7)              LENGTH OF STR
         LH    5,0(8)              LENGTH OF PATTERN
         B     SAVEPARM            SKIP OTHER ENTRY CODE
         EJECT
***********************************************************************
*** PL/I REAL ENTRY - PROLOGUE CODE ***********************************
***********************************************************************
         ENTRY INDEX
         DC    C'INDEX'            PROGRAM IDENTIFIER
         DC    AL1(5)              ..
INDEX    DS    0H
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
         L     3,0(8)              ADDR OF PATTERN
         TM    6(7),X'80'          IS IT VARYING?
         BZ    FIXSTR              NO, FIXED LENGTH STRING
         LH    4,0(2)              VARYING LENGTH OF STR
         LA    2,2(2)              REAL ADDR OF STR
         B     DONESTR
FIXSTR   LH    4,4(7)              FIXED LENGTH OF STRING
DONESTR  EQU   *
         TM    6(8),X'80'          IS IT VARYING?
         BZ    FIXLIST             NO, FIXED LENGTH STRING
         LH    5,0(3)              VARYING LENGTH OF STR
         LA    3,2(3)              REAL ADDR OF STR
         B     SAVEPARM
FIXLIST  LH    5,4(8)              FIXED LENGTH OF STRING
         EJECT
***********************************************************************
*** PROCEDURE BASE ****************************************************
***********************************************************************
SAVEPARM EQU   *
         BALR  11,0                RESET BASE ADDRESS
         USING *,11                IDENTIFY BASE REGISTER
         ST    2,STRADDR           SAVE PARAMETERS
         ST    3,PATADDR           ..
         ST    4,STRLENTH          ..
         ST    5,PATLENTH          ..
         ST    9,ANSADDR           ..
         LA    6,0                 ZERO
         ST    6,0(9)              INITIALIZE ANSWER
         LTR   4,4                 IS STR LENGTH ZERO?
         BZ    RETURN              YES, RETURN
         LTR   5,5                 IS PATTERN LENGTH ZERO?
         BZ    RETURN              YES, RETURN
         CR    4,5                 IS PATTERN LARGER THAN STR?
         BM    RETURN              YES, RETURN
         LA    6,1                 ONE
         CR    5,6                 IS PATTERN ONE CHARACTER?
         BE    SINGLE              DO SIMPLE SEARCH
***********************************************************************
* COMPUTE FAIL FUNCTION ***********************************************
***********************************************************************
         L     0,PATLENTH          ARRAY LENGTH FOR GETMAIN
         SLL   0,2                 MULTIPLY BY 4
*------- OBTAIN VARIABLE DATA AREA (VDA)
         TM    0(13),X'80'         IS DSA FROM PL/I?
         BO    PLISTOR             YES, NO GETMAIN REQUIRED
         GETMAIN R,LV=(0)
         B     GOTSTOR             SKIP PL/I STUFF
PLISTOR  EQU   *
         LR    1,0                 MAKE VDA A MULTIPLE OF 8
         LA    0,7(1)              ..
         N     0,DBOUND            ..
         L     1,76(13)            PTR NEXT AVAIL BYTE AFTER LAST DSA
         ALR   0,1                 ADD THEM TOGETHER
         CL    0,12(12)            COMPARE WITH LAST AVAILABLE BYTE
         BNH   GOTSTOR             IT WILL FIT
         L     15,72(12)           OBTAIN MORE STORAGE (PL/I ROUTINE)
         BALR  14,15               ..
GOTSTOR  EQU   *
         ST    0,76(13)            PUT NAB IN DSA (GARBAGE IF NOT PL/I)
*------- END OBTAIN VARIABLE DATA AREA
         LR    7,1                 REG7 -> TO WORK AREA FOR F
         USING WORK,7              ..
         SR    2,2                 ZERO
         ST    2,F(2)              FIRST POSITION IS ZERO
         LA    2,1                 LOOP INITIALIZATION
         ST    2,J                 ..
ASSIGNF  EQU   *
         L     2,J                 DO J = 2 TO LENGTH(PATTERN);
         LA    2,1(2)              ..
         ST    2,J                 ..
         C     2,PATLENTH          ..
         BP    FAILEND             ..
         BCTR  2,0                 I = F(J-1);
         BCTR  2,0                 ..
         SLA   2,2                 ..
         L     3,F(2)              ..
         ST    3,I                 ..
WHILE    EQU   *
         L     5,I                 DO WHILE((I > 0) &
         LTR   5,5                   ..
         BNP   ENDWHILE              ..
         L     2,PATADDR             (SUBSTR(PATTERN, J, 1) ª=
         L     3,J                    SUBSTR(PATTERN, I+1, 1)));
         BCTR  3,0                     ..
         AR    3,2                     ..
         AR    5,2                     ..
         CLC   0(1,3),0(5)             ..
         BE    ENDWHILE                ..
         L     4,I                     I = F(I);
         BCTR  4,0                     ..
         SLA   4,2                     ..
         L     2,F(4)                  ..
         ST    2,I                     ..
         B     WHILE                   ..
ENDWHILE EQU   *                       END;
         L     2,PATADDR           IF SUBSTR(PATTERN, J, 1) =
         L     3,J                    SUBSTR(PATTERN, I+1, 1)
         BCTR  3,0                     THEN DO;
         AR    3,2                          ..
         L     5,I                          ..
         AR    5,2                          ..
         CLC   0(1,3),0(5)                  ..
         BNE   ELSE                         ..
         L     2,I                          F(J) = I + 1;
         LA    2,1(2)                       ..
         L     4,J                          ..
         BCTR  4,0                          ..
         SLA   4,2                          ..
         ST    2,F(4)                       ..
         BCTR  4,0                          IF F(J) > F(J-1)
         BCTR  4,0                              THEN
         BCTR  4,0                                ..
         BCTR  4,0                                ..
         C     2,F(4)                             ..
         BNP   ENDIF                              ..
         LA    2,0                                   F(J-1) = 0;
         ST    2,F(4)                                ..
         B     ENDIF                        END;
ELSE     EQU   *                       ELSE
         L     4,J                          F(J) = 0;
         BCTR  4,0                          ..
         SLA   4,2                          ..
         LA    2,0                          ..
         ST    2,F(4)                       ..
ENDIF    EQU   *                   ..
         B     ASSIGNF             END;
FAILEND  EQU   *                   ..
         L     2,STRADDR           SETUP FOR CLCL
         L     3,STRLENTH          ..
         L     4,PATADDR           ..
         L     5,PATLENTH          ..
FIND     EQU   *
         CLCL  2,4                 COMPARE FOR PATTERN
         LTR   3,3                 IS STR ALL CHECKED?
         BZ    CKALIKE             SEE IF THEY ARE EXACTLY EQUAL
         LTR   5,5                 IS PATTERN ALL MATCHED?
         BZ    FOUND               FOUND PATTERN
         C     4,PATADDR           DID WE MISS ON FIRST LETTER?
         BE    SAME                WE WILL ADJUST AND TRY AGAIN
         L     6,PATADDR           REG6 HAS BEGIN ADDR OF PATTERN
         SR    4,6                 J-1
         BCTR  4,0                 FOR CONVERSION TO INDEX
         SLA   4,2                 GET PROPER INDEX VALUE
         L     4,F(4)              F(J-1)
         L     5,PATLENTH          REG5 = PATLENTH - F(J-1);
         SR    5,4                 ..
         AR    4,6                 REG4 = ADDR(PATTERN) + F(J-1);
         B     FIND                ..
CKALIKE  EQU   *
         LTR   5,5                 IS THE PATTERN ALL MATCHED TOO?
         BZ    FOUND               FOUND PATTERN AFTER ALL
         B     FINISH              NOPE, STR ALL CHECKED
SAME     EQU   *
         LA    2,1(2)              GET NEXT POSITION IN STR
         BCTR  3,0                 LENGTH LESS ONE
         B     FIND                ..
FOUND    EQU   *
         S     2,PATLENTH          GO BACK TO BEGINNING OF MATCH
         S     2,STRADDR           FIND OFFSET OF MATCH
         LA    2,1(2)              INCREMENT FOR ACTUAL POSITION
         L     3,ANSADDR           STORE THE ANSWER
         ST    2,0(3)              ..
         B     FINISH              ALL DONE, AND FOUND IT!
         EJECT
***********************************************************************
* PATTERN OF LENGTH ONE ***********************************************
***********************************************************************
SINGLE   EQU   *
         L     7,STRADDR           INITIALIZE FOR CLC AND BXLE
         L     3,PATADDR           ..
         LA    8,1                 ..
         L     9,STRLENTH          ..
         BCTR  9,0                 ..
         AR    9,7                 ..
SFIND    EQU   *
         CLC   0(1,7),0(3)         IS THIS THE CHAR?
         BE    SFOUND              YES IT IS
         BXLE  7,8,SFIND           NO TRY NEXT ONE
         L     7,STRADDR           BEGIN OF DISPLACEMENT
         BCTR  7,0                 ADJUST SO ANSWER WILL BE ZERO
SFOUND   EQU   *
         S     7,STRADDR           GET DISPLACEMENT
         LA    7,1(7)              ACTUAL POSITION
         L     3,ANSADDR           WHERE WE PUT ANSWER
         ST    7,0(3)              SAVE ANSWER
         B     RETURN              ALL DONE
         EJECT
***********************************************************************
* FINAL PROCESSING ****************************************************
***********************************************************************
FINISH   EQU   *
         TM    0(13),X'80'         IS DSA FROM PL/I?
         BO    RETURN              YES, NO FREEMAIN REQUIRED
         L     0,PATLENTH          ARRAY LENGTH FOR FREEMAIN
         SLL   0,2                 MULTIPLY BY 4
         FREEMAIN R,LV=(0),A=(7)   FREE THE FAIL FUNCTION
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
         DS    0F
DBOUND   DS    X'FFFFFFF8'
         LTORG
***********************************************************************
*** DYNAMIC STORAGE AREA **********************************************
***********************************************************************
STORAGE  DSECT
SAVEAREA DS    22F
ANSADDR  DS    F
I        DS    F
J        DS    F
PATADDR  DS    F
PATLENTH DS    F
STRADDR  DS    F
STRLENTH DS    F
STOREND  DS    0D
WORK     DSECT
F        DS    F
         END
