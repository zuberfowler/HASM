GETSCRA CSECT
* GETSCR   VERSION 3.0  BY CLYDE THOMAS ZUBER                         *
***********************************************************************
*                                                                     *
* ATTR:  RENT,REUS,REFR,AMODE(24),RMODE(24)                           *
*                                                                     *
* PROGRAM DESCRIPTION:                                                *
*                                                                     *
* THIS ROUTINE HAS TWO ENTRY POINTS.  GETSCRA IS FOR REGULAR OS/370   *
* LINKAGE FOR ASSEMBLER PROGRAMS.  GETSCR IS FOR PL/I PROGRAMS USING  *
* PL/I OPTIMIZER R3.1, R4.0 AND R5.0 CONVENTIONS.                     *
*                                                                     *
* THIS SUBROUTINE DOES A FULL SCREEN TGET FOR THE CALLING PROGRAM.    *
* THE FIRST ARGUMENT IS THE BEGINNING OF THE INPUT BUFFER.  THE       *
* SECOND IS THE END OF THE INPUT BUFFER.  THE THIRD IS A FULLWORD     *
* AREA IN WHICH THE LENGTH OF THE AREA OBTAINED BY THE TGET IS PLACED.*
*                                                                     *
* THIS ROUTINE MAY BE DECLARED IN PL/I AS FOLLOWS:                    *
*      DECLARE  GETSCR  ENTRY OPTIONS(ASM, INTER);                    *
*                                                                     *
* NOTE:  PL/I ERROR MSG OFFSETS ARE RELATIVE TO REAL ENTRY POINT      *
*        R11 - PROCEDURE BASE                                         *
*        R12 - RESERVED                                               *
*        R13 - ADDRESS OF DYNAMIC STORAGE AREA                        *
*                                                                     *
***********************************************************************
         EJECT
GETSCRA AMODE 24
GETSCRA RMODE 24
***********************************************************************
*** ASSEMBLER ENTRY POINT *********************************************
***********************************************************************
         USING *,15                IDENTIFY BASE REGISTER
         B     START               SKIP IDENTIFICATION SECTION
         DC    AL1(6)              PROGRAM IDENTIFIER
         DC    C'GETSCR V3.0  BY CLYDE THOMAS ZUBER '
START    STM   14,12,12(13)        STORE REGISTERS
         LR    2,1                 ADDRESS OF PARM ADDR LIST
         GETMAIN R,LV=STOREND-STORAGE
         L     15,16(13)           RESTORE R15 (BASE REG)
         ST    13,4(1)             CHAIN SAVE AREAS
         ST    1,8(13)             ..
         MVI   0(1),X'00'          CLEAR FLAG (WILL DO FREEMAIN)
         LR    13,1                POINT TO DSA
         USING STORAGE,13          ..
         B     GTSCRPRC            SKIP OTHER ENTRY CODE
         EJECT
***********************************************************************
*** PL/I REAL ENTRY - PROLOGUE CODE ***********************************
***********************************************************************
         ENTRY GETSCR             IDENTIFICATION SECTION
         DC    C' GETSCR'         ..
         DC    AL1(6)             ..
GETSCR   DS    0H
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
GTSCRPRC EQU   *
         BALR  11,0                RESET BASE ADDRESS
         USING *,11                IDENTIFY BASE REGISTER
         LM    1,3,0(2)            GET START/END ADDR AND LENGTH ADDR
         LR    0,2                 CALC LENGTH OF WRITE
         SLR   0,1                 COMPUTE LENGTH
         LR    4,1                 SAVE STARTING ADDRESS
         TGET  (1),(0),ASIS        READ SCREEN
         ST    1,0(3)              SAVE NUMBER OF BYTES READ FOR CALLER
         EJECT
***********************************************************************
*** EPILOGUE CODE *****************************************************
***********************************************************************
         LR    1,13                COPY R13
         L     13,4(13)            RESTORE R13
*********ST****15,16(13)***********SAVE*RETURN*CODE********************
         TM    0(1),X'80'          IS DSA FROM PL/I?
         BO    RETURN              YES, NO FREEMAIN REQUIRED
         LA    0,STOREND-STORAGE   GET LENGTH
         FREEMAIN R,LV=(0),A=(1)   FREE DSA
RETURN   LM    14,12,12(13)        RESTORE CALLER'S REGISTERS
         BR    14                  RETURN
         LTORG
***********************************************************************
*** DYNAMIC STORAGE AREA **********************************************
***********************************************************************
STORAGE  DSECT
SAVEAREA DS    22F
STOREND  DS    0D
         END
