MAXLENA  CSECT
* MAXLEN   VERSION 2.0  BY CLYDE THOMAS ZUBER                         *
***********************************************************************
*                                                                     *
* ATTR:  RENT,REUS,REFR,AMODE(31),RMODE(ANY)                          *
*                                                                     *
* PROGRAM DESCRIPTION:                                                *
*                                                                     *
* THIS ROUTINE RETURNS THE MAXIMUM LENGTH OF A PL/I VARYING CHARACTER *
* STRING.  IF A FIXED LENGTH STRING IS PASSED AS THE ARGUMENT IT      *
* WILL ALSO WORK BUT THE LENGTH BUILTIN FUNCTION SHOULD NORMALLY BE   *
* USED INSTEAD.                                                       *
*                                                                     *
* MAXLEN IS FOR PL/I PROGRAMS USING PL/I OPTIMIZER R3.1, R4.0 AND     *
* R5.0 CONVENTIONS.                                                   *
*                                                                     *
* ENTRY MAXLEN:                                                       *
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
* WHEN USING THE MAXLEN ENTRY FROM PL/I IT SHOULD BE DECLARED AS A    *
* PL/I PROCEDURE AS FOLLOWS:                                          *
*  DECLARE  MAXLEN(CHAR(*) VARYING) ENTRY RETURNS(FIXED BINARY(31));  *
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
***********************************************************************
*** IDENTIFICATION SECTION ********************************************
***********************************************************************
MAXLENA AMODE 31
MAXLENA RMODE ANY
         ENTRY MAXLEN
         DC    AL1(6)              PROGRAM IDENTIFIER
         DC    C'MAXLEN V2.0  BY CLYDE THOMAS ZUBER '
         DS    0H
         DC    C' MAXLEN'          PROGRAM IDENTIFIER
         DC    AL1(6)              ..
***********************************************************************
*** REAL ENTRY - PROLOGUE CODE ****************************************
***********************************************************************
MAXLEN   DS    0H
         USING *,15                INDICATE BASE
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
         BALR  11,0                SET UP NEW BASE
         USING *,11                INDICATE BASE
         LM    2,3,0(2)            ADDRESS OF ARGUMENTS
         LH    4,4(2)              FIXED LENGTH OF STR
         ST    4,0(3)              RETURN ANSWER
***********************************************************************
*** EPILOGUE CODE *****************************************************
***********************************************************************
         L     13,4(13)            FORGET CURRENT (NEW) DSA
*********ST****15,16(13)***********SAVE*RETURN*CODE********************
         LM    14,12,12(13)        RESTORE CALLER'S REGISTERS
         BR    14                  RETURN
***********************************************************************
*** DYNAMIC STORAGE AREA **********************************************
***********************************************************************
STORAGE  DSECT
SAVEAREA DS    22F
STOREND  DS    0D
         END
