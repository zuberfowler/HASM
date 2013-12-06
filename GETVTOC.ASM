READVTC  CSECT
         DC    C' GETVTOC V2.0  BY CLYDE THOMAS ZUBER '
***********************************************************************
*                                                                     *
* THIS ROUTINE DOES A SEQUENTIAL READ THROUGH A VTOC FOR A HIGHER     *
* LEVEL LANGUAGE.  AFTER DOING AT LEAST ONE SEQUENTIAL READ, A        *
* PARAMETER MAY BE USED TO REQUEST A READ BY CCHHR DIRECT AGAINST THE *
* VTOC.  THIS ROUTINE PROCESSES ONLY ONE VTOC AT A TIME AS DESIGNATED *
* BY A DDNAME.                                                        *
*                                                                     *
* THIS ROUTINE MAY BE DECLARED IN PL/I AS FOLLOWS:                    *
*    DECLARE  GETVTOC  ENTRY(CHAR(8), CHAR(140)) OPTIONS(ASM, INTER); *
*                                                                     *
* THE FIRST PARAMETER IS A PASSAREA WHICH IS USED FOR COMMUNICATION   *
* BETWEEN THE CALLING PROGRAM AND THIS ROUTINE.  THE CALLING ROUTINE  *
* MUST PLACE THE DDNAME OF A DD STMT WHICH REFERENCES THE DESIRED     *
* PACK IN THIS AREA FOR THE INITIAL CALL.  IF NO ERRORS ARE DETECTED  *
* THE VOLUME SERIAL OF THE PACK IS RETURNED.  AFTER THAT THE CONTENTS *
* WILL BE CHANGED BY THIS ROUTINE ONLY IN EXCEPTIONAL CONDITIONS.     *
* THESE CONDITIONS AND THEIR INDICATORS FOLLOW:                       *
*                                                                     *
* CALLING ROUTINE TALKING TO GETVTOC                                  *
*    00000000  REQUEST GETVTOC TO CLOSE THIS VTOC SO A NEW DDNAME CAN *
*              BE SUPPLIED ON NEXT CALL (FORCES EOF)                  *
*    111CCHHR  DO DIRECT READ                                         *
*                                                                     *
* GETVTOC TALKING TO CALLING ROUTINE                                  *
*    BADSEEK   CCHHR PTR PASSED BUT UNABLE TO COMPLETE REQUESTED SEEK *
*    DUMP      ABNORMAL END, REQUEST CALLER TO TAKE DUMP OR IGNORE IT *
*    EOF       END OF FILE, THE ENTIRE VTOC HAS BEEN READ             *
*    NOTDA     DEVICE FOR GIVEN DDNAME WAS NOT DIRECT ACCESS          *
*    NOTOPEN   TRIED DIRECT READ BUT HAD NOT DONE SEQUENTIAL READ     *
*              PREVIOUSLY                                             *
*    OPENFAIL  OPEN ON VTOC WAS NOT SUCCESSFUL                        *
*                                                                     *
* WHEN DOING THE CCHHR DIRECT READ THE FIRST PARAMETER CONTAINS THE   *
* CCHHR ADDRESS.  THIS IS USEFUL WHEN FOLLOWING POINTERS FROM ONE     *
* DSCB TO ANOTHER.                                                    *
*                                                                     *
* THE SECOND PARAMETER IS WHERE THE DSCB IS PLACED BY GETVTOC.        *
*                                                                     *
*     R0     SYSTEM USE                                               *
*     R1     PARAMETER LIST PTR / SYSTEM USE                          *
*     R2     WORK                                                     *
*     R3     WORK                                                     *
*     R4     WORK                                                     *
*     R5     WORK                                                     *
*     R6     WORK                                                     *
*     R7     WORK / USED BY SEEK ROUTINE TO POINT TO CCHHR            *
*     R8     PTR TO VTOCDCB                                           *
*     R9     PTR TO PASSAREA                                          *
*     R10    PTR TO BUFFER AREA                                       *
*     R11    BASE REGISTER                                            *
*     R12    RESERVED FOR PL/I                                        *
*     R13    PTR TO SAVE AREA                                         *
*     R14    RETURN ADDR                                              *
*     R15    ENTRY ADDR                                               *
*                                                                     *
***********************************************************************
         ENTRY GETVTOC             IDENTIFY ENTRY POINT
         DC    C'GETVTOC'          PROGRAM ID
         DC    AL1(7)              ..
GETVTOC  STM   14,12,12(13)        SAVE REGISTERS FOR CALLER
         BALR  11,0                GET BASE ADDRESS
         USING *,11                IDENTIFY BASE ADDRESS
         LA    4,SAVEAREA          CHAIN SAVE AREAS
         ST    13,SAVEAREA+4       ..
         ST    4,8(13)             ..
         LR    13,4                ..
         LM    9,10,0(1)           GET PARM LIST
         USING PARM1,9             NAME PARAMETER AREA
         USING PARM2,10            NAME PARM BUFFER AREA
         LA    8,VTOCDCB           GET ADDR FOR SYMBOLIC ADDRESSING
         USING IHADCB,8            NAME DCB AREA
         CLC   PASSAREA(3),=C'000' DOES HE WANT TO CLOSE THIS VTOC?
         BE    VTOCEOD             GO CLOSE IT AND RETURN
         CLC   PASSAREA(3),=C'111' DOES HE WANT TO DO AN OBTAIN?
         BE    SEEKER              YES, GO DO AN OBTAIN FOR HIM
         CLC   DCBDDNAM,=C'XXXXXXXX' IS THE DCB ALREADY OPEN?
         BNE   OPENED              ALREADY OPEN
         MVC   DCBDDNAM,PASSAREA   MOVE IN THE DDNAME FROM THE PASSAREA
         RDJFCB MF=(E,OPENLIST)    COPY THE JFCB IN
         TM    JFCBTSDM,X'20'      IS IT DIRECT ACCESS?
         BO    NOTDA               NO, GIVE ERROR MSG
         MVI   JFCBDSNM,X'04'      PUT NAME OF FORMAT 4 IN DSN
         MVC   JFCBDSNM+1(43),JFCBDSNM ..
         OI    JFCBTSDM,X'08'      FLAG NOT TO PUT IT BACK
         OPEN  TYPE=J,MF=(E,OPENLIST) OPEN DCB
         TM    DCBOFLGS,DCBOFOPN   DID IT OPEN?
         BZ    OPENFAIL            BAD OPEN
         MVI   PASSAREA+6,C' '     BLANK OUT END OF PASSAREA
         MVI   PASSAREA+7,C' '     ..
         L     2,DCBDEBAD          GET ADDR OF DEB
         L     2,32(2)             GET ADDR OF UCB
         USING UCB,2               IDENTIFY UCB
         MVC   PASSAREA(6),UCBVOLI GET VOLUME SERIAL NUMBER TO RETURN
         MVC   VOLSER,UCBVOLI      GET VOLUME SERIAL NUMBER FOR OBTAINS
         DROP  2                   DON'T NEED UCB ANY LONGER
         READ  VTOCDECB,SF,VTOCDCB,READAREA,MF=E READ A BLOCK
OPENED   CHECK VTOCDECB            DID IT READ?
         BAL   14,SYNADCHK         CHECK FLAG, MAY NOT RETURN
         MVC   BUF,READAREA        RETURN RECORD READ
         READ  VTOCDECB,SF,VTOCDCB,READAREA,MF=E READ A BLOCK
         B     RETURN              GO BACK TO CALLER
NOTDA    MVC   PASSAREA,=C'NOTDA   ' TELL HIM TO GET IT RIGHT
         B     RETURN              GO BACK TO CALLER
OPENFAIL MVC   PASSAREA,=C'OPENFAIL' TELL HIM IT DIDN'T OPEN
         B     RETURN              GO BACK TO CALLER
SYNADXIT SYNADAF ACSMETH=BSAM      ERROR ANALYSIS ROUTINE
         MVC   BUF(78),50(1)       GET ERROR MSG
         SYNADRLS                  RESTORE ENVIRONMENT
         MVI   SYNADFLG,1          SET BAD READ FLAG
         BR    14                  RETURN TO SYSTEM
SYNADCHK CLI   SYNADFLG,0          CHECK FLAG SET BY SYNAD ROUTINE
         BER   14                  IF ITS OK THEN RETURN
         MVC   PASSAREA,=C'DUMP    ' TELL HIM TO DUMP
         CLOSE (VTOCDCB)           CLOSE DCB
         MVC   DCBDDNAM,=C'XXXXXXXX' RETURN DCB TO ORIGINAL STATE
         B     RETURN              GO BACK TO CALLER
SEEKER   CLC   DCBDDNAM,=C'XXXXXXXX' HAS THE DCB BEEN OPENED?
         BNE   GOTSER              IF IT HAS WE KNOW VOLSER FOR OBTAIN
         MVC   PASSAREA,=C'NOTOPEN ' TELL HIM OUR PROBLEM
         B     RETURN
GOTSER   MVC   CCHHR,PASSAREA+3    GET CCHHR PART OF PARAMETER
         OBTAIN CAMLIST
         LTR   15,15               CHECK RETURN CODE
         BZ    FOUND               SUCCESSFUL OBTAIN
         MVC   PASSAREA,=C'BADSEEK ' ERROR ON OBTAIN
         B     RETURN              END IT
FOUND    MVC   BUF,SEEKAREA        MOVE DSCB TO HIS BUFFER AREA
         B     RETURN              END IT
VTOCEOD  CLOSE (VTOCDCB)           CLOSE DCB
         MVC   DCBDDNAM,=C'XXXXXXXX' RETURN DCB TO ORIGINAL STATE
         MVC   PASSAREA,=C'EOF     ' TELL HIM WE'RE THROUGH
RETURN   L     13,4(13)            RESTORE REGISTERS
         LM    14,11,12(13)        12 NEVER SHOULD BE CHANGED FOR PL/I
         BR    14                  RETURN
         LTORG
SYNADFLG DC    X'00'               SET TO 1 IF THERE IS A SYNAD ERROR
SAVEAREA DC    20F'0'
CCHHR    DS    CL5                 RELATIVE ADDR FOR SEEK
VOLSER   DS    CL6                 VOLUME SERIAL NUMBER FOR SEEK
READAREA DS    CL140               READ AREA FOR SEQUENTIAL READ ONLY
         READ  VTOCDECB,SF,VTOCDCB,READAREA,MF=L
SEEKAREA DS    CL140               READ AREA FOR SEEK ONLY
         DS    CL8                 MUST FOLLOW SEEKAREA, USED BY CAMLST
CAMLIST  CAMLST SEEK,CCHHR,VOLSER,SEEKAREA
VTOCDCB  DCB   DDNAME=XXXXXXXX,DSORG=PS,MACRF=(R),RECFM=FS,KEYLEN=44,  X
               BLKSIZE=96,EXLST=JFCBAD,EODAD=VTOCEOD,SYNAD=SYNADXIT
OPENLIST OPEN  (VTOCDCB,(INPUT)),MF=L
JFCBAD   DC    X'87',AL3(JFCB)
         IEFJFCBN
JFCB     EQU   INFMJFCB
PARM1    DSECT
PASSAREA DS    CL8
PARM2    DSECT
BUF      DS    CL140
UCB      DSECT
         IEFUCBOB
         DCBD  DSORG=BS,DEVD=DA
         END
