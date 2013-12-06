GETSCRA CSECT
* GETSCR   VERSION 2.0  BY CLYDE THOMAS ZUBER                         *
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
         DC    C'GETSCR V2.0  BY CLYDE THOMAS ZUBER '
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
TRLOOP   C     1,=F'256'           DID WE READ MORE THAN 256 CHAR?
         BNH   LASTTR              NO..ONLY NEED ONE TR INSTRUCTION
         TR    0(256,4),TRTABLE    TRANSLATE 256 CHARACTERS
         LA    4,256(4)            PREPARE FOR NEXT 256 CHARACTERS
         S     1,=F'256'           ALLOW FOR 256 CHAR WE PROCESSED
         B     TRLOOP              NOW REPEAT
LASTTR   BCTR  1,0                 ALLOW FOR TR INST LEN
         EX    1,TRANEX            TR    0(0,4),TRTABLE
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
TRANEX   TR    0(0,4),TRTABLE      TRANSLATE REMAINDER OF SCREEN
         LTORG
         DS    0D
TRTABLE  DC    XL16'000102030405060708090A0B0C0D0E0F'
         DC    XL16'101112131415161718191A1B1C1D1E1F'
         DC    XL16'202122232425262728292A2B2C2D2E2F'
         DC    XL16'303132333435363738393A3B3C3D3E3F'
         DC    XL16'404142434445464748494A4B4C4D4E4F'
         DC    XL16'505152535455565758595A5B5C5D5E5F'
         DC    XL16'606162636465666768696A6B6C6D6E6F'
         DC    XL16'707172737475767778797A7B7C7D7E7F'
         DC    XL16'80C1C2C3C4C5C6C7C8C98A8B8C8D8E8F'
         DC    XL16'90D1D2D3D4D5D6D7D8D99A9B9C9D9E9F'
         DC    XL16'A0A1E2E3E4E5E6E7E8E9AAABACADAEAF'
         DC    XL16'B0B1B2B3B4B5B6B7B8B9BABBBCBDBEBF'
         DC    XL16'C0C1C2C3C4C5C6C7C8C9CACBCCCDCECF'
         DC    XL16'D0D1D2D3D4D5D6D7D8D9DADBDCDDDEDF'
         DC    XL16'E0E1E2E3E4E5E6E7E8E9EAEBECEDEEEF'
         DC    XL16'F0F1F2F3F4F5F6F7F8F9FAFBFCFDFEFF'
***********************************************************************
*** DYNAMIC STORAGE AREA **********************************************
***********************************************************************
STORAGE  DSECT
SAVEAREA DS    22F
STOREND  DS    0D
         END
