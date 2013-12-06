* PLIR12  VERSION 2.0  BY CLYDE THOMAS ZUBER                          *
PLIR12A  CSECT
***********************************************************************
*                                                                     *
* ATTR:  RENT,REUS,REFR,AMODE(31),RMODE(ANY)                          *
*                                                                     *
* PROGRAM DESCRIPTION:                                                *
*                                                                     *
* THIS SUBPROGRAM IS FOR USE WITH GETDCB, A PL/I PROCEDURE WHICH WILL *
* DETERMINE A DATA SET'S DCB ATTRIBUTES.  THE PURPOSE OF THIS ROUTINE *
* IS TO RETURN REGISTER TWELVE.  ALTHOUGH THIS COULD BE ACCOMPLIHED   *
* WITH THREE INSTRUCTIONS IT WAS DECIDED TO ADHERE TO CONVENTIONS.    *
* REGISTER TWELVE OF THE PL/I PROGRAM IS USED TO ADDRESS A PL/I       *
* PSEUDO REGISTER WHICH ENABLES GETDCB TO FIND THE DATA SET'S DCB.    *
*                                                                     *
* NOTE:  PL/I ERROR MSG OFFSETS ARE RELATIVE TO REAL ENTRY POINT      *
*        R2  - PARAMETER LIST ADDRESS COPIED FROM R1, WORK REGISTER   *
*        R11 - PROCEDURE BASE                                         *
*        R12 - RESERVED                                               *
*        R13 - ADDRESS OF DYNAMIC STORAGE AREA                        *
*                                                                     *
***********************************************************************
         EJECT
***********************************************************************
*** IDENTIFICATION SECTION ********************************************
***********************************************************************
PLIR12A  AMODE 31
PLIR12A  RMODE ANY
         ENTRY PLIR12
         DC    AL1(6)              IDENTIFCATION SECTION
         DC    C'PLIR12 V2.0  BY CLYDE THOMAS ZUBER '
         DS    0H
         DC    C' PLIR12'          IDENTIFCATION SECTION
         DC    AL1(6)              ..
***********************************************************************
*** REAL ENTRY - PROLOGUE CODE ****************************************
***********************************************************************
PLIR12   DS    0H
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
         L     2,0(2)              GET ADDRESS OF PARM
         ST    12,0(2)             STORE R12 IN PARM
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