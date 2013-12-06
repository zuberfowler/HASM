LOADADA  CSECT
* LOADAD   VERSION 2.0  BY CLYDE THOMAS ZUBER                         *
***********************************************************************
*                                                                     *
* ATTR:  RENT,REUS,REFR,AMODE(31),RMODE(ANY)                          *
*                                                                     *
* PROGRAM DESCRIPTION:                                                *
*                                                                     *
* THIS SUBROUTINE IS TO ENABLE HIGH LEVEL LANGUAGES TO USE AN         *
* ASSEMBLER LOAD ADDRESS INSTRUCTION.                                 *
*                                                                     *
* THIS ROUTINE HAS TWO ENTRY POINTS.  LOADADA IS FOR REGULAR OS/370   *
* LINKAGE AND LOADAD IS SPECIFICALLY FOR PL/I PROGRAMS USING PL/I     *
* OPTIMIZER R3.1, R4.0 AND R5.0 CONVENTIONS.                          *
*                                                                     *
* ENTRY LOADADA:                                                      *
*    THREE ARGUMENTS ARE PASSED AS PARAMETERS WHICH ARE FULL WORD     *
* VALUES.  REGULAR OS LINKAGE IS PERFORMED.                           *
*                                                                     *
* ENTRY LOADAD:                                                       *
*    IN PL/I IF THE CALL FORMAT IS USED IT HAS THREE ARGUMENTS WHICH  *
* CAN BE EITHER FIXED BINARY(31) OR PTR (POINTER) OR ANY MIXTURE      *
* THEREOF.  IF USED WITH CALL DECLARE IT AS FOLLOWS:                  *
*     DECLARE  LOADAD  ENTRY OPITONS(ASM, INTER);                     *
*     CALL LOADAD(OFFSET, ADDRESS, NEW_ADDR);                         *
*                                                                     *
* NORMALLY, HOWEVER, IT IS MORE USEFUL TO USE AS A MOCK PL/I FUNCTION.*
* THE DECLARE MUST SPECIFY SPECIFICALLY WHICH DATA TYPE IT WILL       *
* EXPECT TO BE RETURNED EVEN THOUGH INTERNALLY THEY ARE THE SAME:     *
*     DECLARE  LOADAD  ENTRY RETURNS(PTR); /* REALLY ASM */           *
* OR                                                                  *
*     DECLARE  LOADAD ENTRY  RETURNS(FIXED BINARY(31));               *
*                                                                     *
*     NEW_ADDR = LOADAD(OFFSET, ADDRESS);                             *
* WITH THIS FORM IT APPROXIMATES THE ASSEMBLER EVEN IN ORDER.         *
*     LA     2,35(3)                                                  *
*                                                                     *
* THE RETURNS(FIXED BINARY(31)) OR RETURNS(PTR) WORKS BECAUSE PL/I    *
* CREATES A THIRD ARGUMENT TO OBTAIN ITS RETURN VALUE.                *
*                                                                     *
* NOTE:  PL/I ERROR MSG OFFSETS ARE RELATIVE TO REAL ENTRY POINT      *
*        R11 - PROCEDURE BASE                                         *
*        R12 - RESERVED                                               *
*        R13 - ADDRESS OF DYNAMIC STORAGE AREA                        *
*                                                                     *
***********************************************************************
         EJECT
LOADADA  AMODE 31
LOADADA  RMODE ANY
***********************************************************************
*** REGULAR OS ENTRY POINT ********************************************
***********************************************************************
         USING *,15                IDENTIFY BASE REGISTER
         B     START               SKIP IDENTIFICATION SECTION
         DC    AL1(6)              PROGRAM IDENTIFIER
         DC    C'LOADAD V2.0  BY CLYDE THOMAS ZUBER'
START    STM   14,12,12(13)        STORE REGISTERS
         LR    2,1                 ADDRESS OF PARM ADDR LIST
         GETMAIN R,LV=STOREND-STORAGE
         L     15,16(13)           RESTORE R15 (BASE REG)
         ST    13,4(1)             CHAIN SAVE AREAS
         ST    1,8(13)             ..
         MVI   0(1),X'00'          CLEAR FLAG (WILL DO FREEMAIN)
         LR    13,1                POINT TO DSA
         USING STORAGE,13          ..
         B     LDADPROC            SKIP OTHER ENTRY CODE
         EJECT
***********************************************************************
*** PL/I REAL ENTRY - PROLOGUE CODE ***********************************
***********************************************************************
         ENTRY LOADAD
         DC    C' LOADAD'          PROGRAM IDENTIFIER
         DC    AL1(6)              ..
LOADAD   DS    0H
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
LDADPROC EQU   *
         BALR  11,0                RESET BASE ADDRESS
         USING *,11                IDENTIFY BASE REGISTER
         LM    2,4,0(2)            GET ADDR OF PARAMETERS
         L     5,0(2)              GET OFFSET VALUE
         L     6,0(3)              GET BASE VALUE
         AR    5,6                 ADD BASE AND OFFSET
         ST    5,0(4)              RETURN THE SUM
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
*** DYNAMIC STORAGE AREA **********************************************
***********************************************************************
STORAGE  DSECT
SAVEAREA DS    22F
STOREND  DS    0D
         END
