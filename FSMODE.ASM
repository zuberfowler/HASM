FSMODEA  CSECT
* FSMODE  VERSION 2.0  BY CLYDE THOMAS ZUBER                          *
***********************************************************************
*                                                                     *
* ATTR:  RENT,REUS,REFR,AMODE(24),RMODE(24)                           *
*                                                                     *
* PROGRAM DESCRIPTION:
*                                                                     *
* THIS ROUTINE IS FOR PROGRAMS USING FULL SCREEN TPUTS UNDER VTAM     *
* WHEN FULL SCREEN MODE IS ON ANY NON-FULL SCREEN TPUTS WILL CLEAR    *
* THE SCREEN AND BE FOLLOWED BY ***.  THE PROGRAM MUST TEST FOR A     *
* PA2 BEING RETURNED BY THE TPUT ROUTINE.  THIS INDICATES THAT THE    *
* TPUT MUST BE REISSUED BECAUSE OF AN INTERRUPTION BY A NON-FULL      *
* SCREEN TPUT.  TURNING OFF THE FULL SCREEN MODE ALSO CLEARS THE      *
* SCREEN.  THIS IS THE MOST EFFICIENT WAY TO CLEAR THE SCREEN UNDER   *
* VTAM.  THE MACROS/SVCS EMPLOYED TO PERFORM THESE FUNCTIONS ARE      *
* NOOPS IN A NON-VTAM ENVIRONMENT.                                    *
*                                                                     *
* THIS ROUTINE HAS TWO ENTRY POINTS.  FSMODEA IS FOR REGULAR OS/370   *
* LINKAGE.  FSMODE IS FOR PL/I PROGRAMS USING PL/I OPTIMIZER R3.1,    *
* R4.0, AND R5.0 CONVENTIONS.                                         *
*                                                                     *
* THIS ROUTINE MAY BE DECLARED IN PL/I AS FOLLOWS:                    *
*      DECLARE  FSMODE  ENTRY(CHAR(*)) OPTIONS(ASM, INTER);           *
* PARAMETER VALUES:                                                   *
*     ON        - TURN FULL SCREEN MODE ON                            *
*     OFF       - TURN FULL SCREEN MODE OFF AND CLEAR SCREEN          *
*     CLR/CLEAR - TURN FULL SCREEN MODE OFF AND CLEAR SCREEN          *
*     IF AN INVALID PARAMETER IS PASSED A USER ABEND 4055 OCCURS      *
*                                                                     *
* NOTE:  PL/I ERROR MSG OFFSETS ARE RELATIVE TO REAL ENTRY POINT      *
*        R11 - PROCEDURE BASE                                         *
*        R12 - RESERVED                                               *
*        R13 - ADDRESS OF DYNAMIC STORAGE AREA                        *
*                                                                     *
***********************************************************************
         EJECT
FSMODEA  AMODE 24
FSMODEA  RMODE 24
***********************************************************************
*** REGULAR OS ENTRY POINT ********************************************
***********************************************************************
         USING *,15                IDENTIFY BASE REGISTER
         B     START               SKIP IDENTIFICATION SECTION
         DC    AL1(6)              IDENTIFCATION SECTION
         DC    C'FSMODE V2.0  BY CLYDE THOMAS ZUBER'
START    STM   14,12,12(13)        STORE REGISTERS
         LR    2,1                 ADDRESS OF PARM ADDR LIST
         GETMAIN R,LV=STOREND-STORAGE
         L     15,16(13)           RESTORE R15 (BASE REG)
         ST    13,4(1)             CHAIN SAVE AREAS
         ST    1,8(13)             ..
         MVI   0(1),X'00'          CLEAR FLAG (WILL DO FREEMAIN)
         LR    13,1                POINT TO DSA
         USING STORAGE,13          ..
         B     FSMPROC             SKIP OTHER ENTRY CODE
         EJECT
***********************************************************************
*** PL/I REAL ENTRY - PROLOGUE CODE ***********************************
***********************************************************************
         ENTRY FSMODE
         DC    C' FSMODE'     PROGRAM IDENTIFIER
         DC    AL1(6)         ..
FSMODE   DS    0H
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
FSMPROC  BALR  11,0                RESET BASE ADDRESS
         USING *,11                IDENTIFY BASE REGISTER
         L     7,0(2)              ADDRESS OF ARGUMENT
         CLI   1(7),C'N'           FULL SCREEN MODE ON?
         BNE   CHECKOFF            NO, SEE IF TURN OFF
         STFSMODE ON,INITIAL=YES   TURN FULL SCREEN MODE ON
         B     FINISH              FINISH
CHECKOFF CLI   1(7),C'F'           FULL SCREEN MODE OFF?
         BE    STLINE              YES
         CLI   0(7),C'C'           CLEAR SCREEN?
         BNE   ERROR               NO, ABEND
STLINE   STLINENO LINE=1           TURN FULL SCREEN OFF/CLEAR SCREEN
         B     FINISH              FINISH
ERROR    ABEND 4055                ABEND
***********************************************************************
*** EPILOGUE CODE *****************************************************
***********************************************************************
FINISH   LR    1,13                COPY R13
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