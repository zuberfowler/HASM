PDSPROCA CSECT
* PDSPROC  VERSION 2.1  BY CLYDE THOMAS ZUBER                         *
***********************************************************************
*                                                                     *
* ATTR:  RENT,REUS,REFR,AMODE(24),RMODE(24)                           *
*                                                                     *
* PROGRAM DESCRIPTION:                                                *
*                                                                     *
* THIS MODULE IS AN SET OF ROUTINES TO PROVIDE ACCESS TO PARTITIONED  *
* DATA SETS FOR A HIGHER LEVEL LANGUAGE.  EXAMPLES ARE FOR PL/I BUT   *
* PDSPROC MAY ALSO BE CALLED FROM OTHER LANGUAGES USING STANDARD OS   *
* LINKAGE.  THIS ROUTINE REQUIRES TWO PARAMETERS.  THE FIRST PARA-    *
* METER IS A CHARACTER FIELD CONTAINING THE NAME OF THE ROUTINE       *
* WHICH THE CALLER WANTS TO PERFORM.  THE CHARACTER STRING MUST BE    *
* AT LEAST FOUR CHARACTERS BUT AND MAY BE AS LONG AS DESIRED.  IN NO  *
* CASE IS IT REQUIRED TO BE OVER FIVE CHARACTERS, HOWEVER.  THE       *
* SECOND PARAMETER IS MAPPED BELOW AND ALL FLAGS AND FIELDS REFERED   *
* TO IN THE FOLLOWING COMMENTS ARE CONTAINED THEREIN.                 *
*                                                                     *
* CONCATENATED PARTITIONED DATA SETS ARE SUPPORTED.                   *
*                                                                     *
* THIS ROUTINE HAS TWO ENTRY POINTS.  PDSPROCA IS FOR REGULAR OS/370  *
* LINKAGE FOR ASSEMBLER PROGRAMS.  PDSPROC IS FOR PL/I PROGRAMS USING *
* PL/I OPTIMIZER R3.1, R4.0 AND R5.0 CONVENTIONS.                     *
*                                                                     *
* NOTE:  PL/I ERROR MSG OFFSETS ARE RELATIVE TO REAL ENTRY POINT      *
*        R10 - PARM DSECT BASE                                        *
*        R11 - PROCEDURE BASE                                         *
*        R12 - RESERVED (PL/I PSEUDO REGISTER POINTER)                *
*        R13 - ADDRESS OF DYNAMIC STORAGE AREA                        *
*                                                                     *
***********************************************************************
         EJECT
PDSPROCA AMODE 24
PDSPROCA RMODE 24
***********************************************************************
*** ASSEMBLER ENTRY POINT *****************************************2.0*
***********************************************************************
         USING *,15                IDENTIFY BASE REGISTER
         B     START               SKIP IDENTIFICATION SECTION
         DC    AL1(7)              PROGRAM IDENTIFIER
         DC    C'PDSPROC V2.1  BY CLYDE THOMAS ZUBER'
START    STM   14,12,12(13)        STORE REGISTERS
         LR    2,1                 ADDRESS OF PARM ADDR LIST
         GETMAIN R,LV=STOREND-STORAGE
         L     15,16(13)           RESTORE R15 (BASE REG)
         ST    13,4(1)             CHAIN SAVE AREAS
         ST    1,8(13)             ..
         MVI   0(1),X'00'          CLEAR FLAG (WILL DO FREEMAIN)
         LR    13,1                POINT TO DSA
         USING STORAGE,13          ..
         B     SAVEPARM            SKIP OTHER ENTRY CODE
         EJECT
***********************************************************************
*** PL/I REAL ENTRY - PROLOGUE CODE *******************************2.0*
***********************************************************************
         ENTRY PDSPROC
         DC    C'PDSPROC'          PROGRAM IDENTIFIER
         DC    AL1(7)              ..
PDSPROC  DS    0H
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
*                                                                     *
*     ROUTINE   NOTES AND EXPLANATIONS                                *
*     =======   ======================                                *
*     OPEN      BEFORE USING THE OPEN ROUTINE THE DDNAME MUST BE      *
*               SUPPLIED BY THE CALLING PROGRAM IN THE SECOND         *
*               PARAMETER.  IN ADITION THE INFLAG MUST BE SET TO      *
*               EITHER X'00' FOR OUTPUT OR X'80' FOR INPUT.  ALL      *
*               OTHER FIELDS ARE INITIALIZED BY OPEN.  OPEN CAN OPEN  *
*               ONLY ONE DDNAME AT A TIME BUT MAY BE CALLED           *
*               REPEATEDLY IN A LOOP FOR AN ARRAY OF PDS PARMS.       *
*               (AS OF V1.1 REC IS NO LONGER INITIALIZED BECAUSE      *
*               SOME APPLICATIONS DO NOT REQUIRE THIS AREA).          *
*                                                                     *
*     BLDL      FOR A PDS OPENED FOR INPUT THIS ROUTINE BUILDS A      *
*               COPY OF THE PDS DIRECTORY FOR THE CALLING PROGRAM.    *
*               THE MAP OF THE AREA BUILT FOLLOWS BELOW.  THE TTR     *
*               FIELD OF THIS AREA MAY BE MOVED TO THE FINDTTR FIELD  *
*               OF THE SECOND PARAMETER IN ORDER TO SET UP FOR A READ *
*               OF ANY PARTICULAR MEMBER.  THIS ROUTINE SAVES         *
*               CONSIDERABLE OVERHEAD WHEN MANY MEMBERS MUST BE       *
*               PROCESSED.  IT IS A MUST WHEN THE MEMBER NAME(S) TO   *
*               BE PROCESSED ARE NOT KNOWN AHEAD OF TIME.  WHEN FEW   *
*               MEMBERS ARE TO BE PROCESSED AND THEY ARE KNOWN AHEAD  *
*               OF TIME THE FINDMEM ROUTINE MAY BE USED INSTEAD OF    *
*               THE FINDTTR ROUTINE.  FOR CONCATENATED DATA SETS THE  *
*               FINDMEM ROUTINE MUST BE USED RATHER THAN FINDTTR.     *
*               BLDL MAY STILL BE USED TO GET THE MEMBER NAMES.       *
*                                                                     *
*     FINDTTR   ONE OF THE FIND ROUTINES IS NECESSARY BEFORE DOING    *
*               A READ FOR A PARTICULAR MEMBER OF A PDS.  THE FINDTTR *
*               ROUTINE IS FOR USE WHEN THE TTR OF THE MEMBER IS      *
*               KNOWN, USUALLY FROM EXECUTING THE BLDL ROUTINE.  FOR  *
*               INFORMATION ON WHICH TO USE SEE THE BLDL EXPLANATION. *
*               THE TTR MUST BE PLACED IN THE FINDTTR FIELD OF THE    *
*               SECOND PARAMETER BY THE CALLER.                       *
*                                                                     *
*     FINDMEM   THIS ROUTINE DOES A FIND BY MEMBER NAME RATHER THAN   *
*               BY TTR.  THE MEMBER NAME MUST BE PLACED IN THE        *
*               MEMNAME FIELD OF THE SECOND PARAMETER BY THE CALLER.  *
*                                                                     *
*     CLOSE     THIS ROUTINE CLOSES THE DCB FOR PDS AND FREES ALL     *
*               THE BUFFER AREAS OBTAINED BY THE OPEN AND POSSIBLY    *
*               THE BLDL ROUTINES.  AFTER CLOSE THE PDS MAY BE        *
*               REOPENED FOR THE OPOSITE TYPE PROCESSING (IE. INPUT   *
*               VS. OUTPUT).                                          *
         EJECT
*     STOW      ONE OF THE STOW ROUTINES IS REQUIRED AFTER WRITING    *
*               A NEW MEMBER TO THE PDS.  IT PLACES THE DIRECTORY     *
*               INFORMATION PROVIDED BY THE CALLER INTO THE DIRECTORY *
*               OF THE PDS.  STOW OR STOWADD SPECIFIES THAT AN ENTRY  *
*               IS TO BE ADDED TO THE DIRECTORY.  TO USE STOW TO ADD  *
*               OR REPLACE A DIRECTORY ENTRY BLDLPTR SHOULD POINT TO  *
*               THE DIRECTORY ENTRY BUILT BY THE CALLER.              *
*                                                                     *
*     STOWCHAN  SPECIFIES THAT THE NAME OF AN EXISTING MEMBER OR      *
*               ALIAS IS TO BE CHANGED.  BLDLPTR SHOULD POINT TO A    *
*               SIXTEEN BYTE FIELD, THE OLD NAME FOLLOWED BY THE NEW  *
*               NAME.                                                 *
*                                                                     *
*     STOWDEL   SPECIFIES THAT AN EXISTING ENTRY IS TO BE DELETED.    *
*               BLDLPTR SHOULD POINT TO THE EIGHT BYTE MEMBER NAME.   *
*                                                                     *
*     STOWREPL  SPECIFIES THAT AN EXISTING DIRECTORY ENTRY IS TO BE   *
*               REPLACED BY A NEW DIRECTORY ENTRY.  IF THIS IS        *
*               SELECTED BUT THE OLD ENTRY IS NOT FOUND, THE NEW      *
*               ENTRY IS ADDED TO THE DIRECTORY BUT A COMPLETION CODE *
*               OF 8 IS RETURNED WITH A MESSAGE TO THE EFFECT THAT    *
*               IT WAS NOT FOUND.                                     *
*                                                                     *
*     READ      ROUTINE WHICH RETURNS A LOGICAL RECORD TO THE CALLER. *
*                                                                     *
*     WRITE     ROUTINE WHICH WRITES A PHYSICAL BLOCK FOR THE CALLER. *
*               IF BLOCKING IS DESIRED IT MUST BE DONE BY THE CALLER. *
*               FIXED LENGTH RECORDS ARE CONCATENATED UNTO REC UNTIL  *
*               LENGTH(REC) = BLKSIZE OR SMALLER.  UNDEFINED FORMAT   *
*               RECORDS CAN BE ANY LENGTH <= BLKSIZE. VARYING FORMAT  *
*               RECORDS HAVE A FULLWORD (4 BYTES, FIXED BINARY(31))   *
*               LENGTH FIELD BEFORE EACH LOGICAL RECORD.  HOWEVER,    *
*               ONLY THE FIRST TWO BYTES CONTAIN THE LENGTH, THE      *
*               LAST TWO BYTES MUST CONTAIN X'0000'.  THE TOTAL       *
*               LENGTH OF REC MUST BE <= BLKSIZE-4.  IN ALL CASES THE *
*               BLOCK LENGTH IS DETERMINED BY THE ACCESS METHOD AND   *
*               IS NOT THE RESPONSIBILITY OF THE CALLER.              *
*                                                                     *
*     NOTE      THE NOTE ROUTINE CAUSE THE SYSTEM TO RETURN THE TTR   *
*               OF THE LAST BLOCK READ FROM OR WRITTEN INTO A DATA    *
*               SET.  THE TTR IS STORED IN THE FINDTTR FIELD OF THE   *
*               SECOND PARAMETER.                                     *
         EJECT
* THIS IS THE SECOND PARAMETER TO THE PDSPROC ROUTINES.  ONE MAY      *
* DESIRE TO MAKE IT AN ARRAY IN ORDER TO PROCESS SEVERAL PDS DATA     *
* SETS.  IN THIS CASE THE CALL STATEMENT WOULD SPECIFY THE CORRECT    *
* SUBSCRIPT.                                                          *
*                                                                     *
*     DECLARE                                                         *
*         1  PARM,                                                    *
*            2  DCBPTR    PTR,                                        *
*            2  DECBPTR   PTR,                                        *
*            2  BLDLPTR   PTR,                                        *
*            2  BUFADDR   PTR,                                        *
*            2  BUFPOS    PTR,                                        *
*            2  BUFEND    PTR,  /* BLKSIZE WHEN OPEN FOR OUTPUT */    *
*            2  ERRPTR    PTR,                                        *
*            2  DDNAME    CHAR(8),                                    *
*            2  FINDTTR   CHAR(3),                                    *
*            2  TTRKPAD   CHAR(1),                                    *
*            2  MEMNAME   CHAR(8),                                    *
*            2  CHECKIT   BIT(8),                                     *
*            2  INFLAG,                                               *
*               3  OPEN_FOR_INPUT  BIT(1),                            *
*               3  FILLER          BIT(6),                            *
*               3  END_OF_FILE     BIT(1),                            *
*            2  DSNAME    CHAR(44),                                   *
*            2  VOLUME    CHAR(6),                                    *
*            2  REC       CHAR(32760) VARYING;                        *
*                                                                     *
* THE FOLLOWING FIELDS OF THE ABOVE PARM ARE MODIFIED BY THE CALLER:  *
*     BLDLPTR (BEFORE STOW),                                          *
*     DDNAME  (BEFORE OPEN),                                          *
*     FINDTTR (BEFORE FINDTTR),                                       *
*     MEMNAME (BEFORE FINDMEM),                                       *
*     INFLAG  (BEFORE OPEN),                                          *
*     REC     (BEFORE WRITE).                                         *
*                                                                     *
* THE FOLLOWING FIELDS OF THE ABOVE PARM PROVIDE INFORMATION TO THE   *
* CALLER:                                                             *
*     DCBPTR  (AFTER OPEN WHEN CALLER PROVIDES PROPER MAPPING),       *
*     INFLAG  (BIT SET ON END OF FILE FOR INPUT MEMBER),              *
*     DSNAME  (AFTER OPEN)                                            *
*     VOLUME  (AFTER OPEN)                                            *
*     REC     (AFTER READ)                                            *
         EJECT
* THIS MODULE SHOULD BE DECLARED IN PL/I AS FOLLOWS:                  *
*                                                                     *
*     DECLARE  PDSPROC  ENTRY OPTIONS(ASM, INTER, RETCODE);           *
*                                                                     *
*                                                                     *
* WHEN USING THE BLDL ROUTINE THE FOLLOWING STRUCTURE MAPS THE        *
* DIRECTORY INFORMATION OBTAINED.  NOTE THAT THE USER DATA AREA       *
* CONTAINS VALID INFORMATION FOR ONLY THE NUMBER OF HALF WORDS        *
* INDICATED IN THE LAST FIVE BITS OF THE C FIELD.                     *
*                                                                     *
*     DECLARE                                                         *
*         1  DIRECTORY  BASED(BLDLPTR),                               *
*            2  NUMBER_ENTRIES  FIXED BINARY,                         *
*            2  MEMBER_ENTRY(MAX_EXT REFER(NUMBER_ENTRIES)),          *
*               3  MEMBER_NAME  CHAR(8),                              *
*               3  TTR          CHAR(3),                              *
*               3  C_FIELD,                                           *
*                  4  ALIAS           BIT(1),                         *
*                  4  NUM_TTRN        BIT(2),                         *
*                  4  USER_HALFWORDS  BIT(5),                         *
*               3  USER_DATA    CHAR(62);                             *
*                                                                     *
* A DIRECTORY ENTRY MUST BE CREATED FOR STOW TO WORK.  THE FOLLOWING  *
* DECLARATION SIMILAR TO THAT FOR THE BLDL ROUTINE WILL WORK.  BEFORE *
* CALLING STOW SET BLDLPTR = ADDR(STOW_MEMBER_ENTRY);                 *
*                                                                     *
*     DECLARE                                                         *
*       1  STOW_MEMBER_ENTRY,                                         *
*          2  STOW_MEMBER_NAME  CHAR(8),                              *
*          2  STOW_TTR          CHAR(3),                              *
*          2  STOW_C_FIELD,                                           *
*             3  STOW_ALIAS           BIT(1),                         *
*             3  STOW_NUM_TTRN        BIT(2),                         *
*             3  STOW_USER_HALFWORDS  BIT(5),                         *
*          2  STOW_USER_DATA    CHAR(62);                             *
*                                                                     *
* THE FOLLOWING DECLARATION CAN BE USED TO OBTAIN AN ERROR MESSAGE    *
* PROVIDED BY A ROUTINE WHEN THE RETURN CODE (PLIRETV) IS NOT ZERO.   *
*                                                                     *
*     DECLARE  ERRMSG  BASED(ERRPTR) CHAR(32760) VARYING;             *
         EJECT
*   RETURN CODES SUPPLIED BY PDSPROC                                  *
*                                                                     *
*    0 - FUNCTION COMPLETED NORMALLY                                  *
*                                                                     *
*    4 - INFORMATIONAL MESSAGE; FURTHER PROCESSING WILL BE LIMITED    *
*        IN SOME MANNER                                               *
*                                                                     *
*    8 - INCORRECT FUNCTIONAL CALL, USER LOGICAL ERROR; FURTHER       *
*        PROCESSING MAY OR MAY NOT BE AFFECTED                        *
*                                                                     *
*   12 - ABORT ERROR, FUNCTION COULD NOT BE COMPLETED; FURTHER        *
*        PROCESSING PROBABLY WILL BE AFFECTED                         *
*                                                                     *
*   16 - CRITICAL ERROR; NO FURTHER PROCESSING WILL BE POSSIBLE       *
*                                                                     *
*                                                                     *
***********************************************************************
         EJECT
***********************************************************************
*** PROCEDURE BASE ****************************************************
***********************************************************************
SAVEPARM EQU   *
         BALR  11,0                RESET BASE ADDRESS              2.0
         USING *,11                IDENTIFY BASE REGISTER          2.0
* INITIALIZATION CODE
         LM    9,10,0(2)           GET PARMS ADDRESSES
         USING PARM,10             MAP THE BIG ONE
         LA    2,0                 INITIALIZE UNIVERSAL OPENLST    2.0
         ICM   2,B'1000',=X'80'    ..                              2.0
         ST    2,OPENLST           ..                              2.0
         CLC   0(4,9),=C'OPEN'     SEE WHAT ACTION TO TAKE
         BE    OPENDCB             GO TO THE DESIRED ROUTINE
         CLC   0(4,9),=C'BLDL'     ..
         BE    BLDLBLK             ..
         CLC   0(5,9),=C'FINDT'    ..
         BE    FINDT               ..
         CLC   0(5,9),=C'FINDM'    ..
         BE    FINDMEM             ..
         CLC   0(5,9),=C'CLOSE'    ..
         BE    CLOSEDCB            ..
         CLC   0(5,9),=C'STOWC'    ..
         BE    STOWCHAN            ..
         CLC   0(5,9),=C'STOWD'    ..
         BE    STOWDELE            ..
         CLC   0(5,9),=C'STOWR'    ..
         BE    STOWREPL            ..
         CLC   0(4,9),=C'STOW'     ..
         BE    STOWADD             ..
         CLC   0(4,9),=C'READ'     ..
         BE    READBLK             ..
         CLC   0(5,9),=C'WRITE'    ..
         BE    WRITEBLK            ..
         CLC   0(4,9),=C'NOTE'     ..
         BE    NOTEPOS             ..
         LA    2,INVCMD            OTHERWISE IT IS INVALID
         ST    2,ERRPTR            ..
         LA    15,8                RETURN CODE
         B     FINISH              GET OUT
* END INITIALIZATION CODE
         EJECT
* BLDL ROUTINE
BLDLBLK  EQU   *
         TM    INFLAG,X'80'        CHECK THAT IT'S OPEN FOR INPUT
         BNZ   OFIN                YES, IT'S OPEN FOR INPUT
         LA    3,NOTINP            NO, GIVE HIM AN ERROR MESSAGE
         ST    3,ERRPTR            ..
         LA    15,8                ..
         B     FINISH              ..
OFIN     EQU   *
         LA    2,DIRECT-MVBLK      GET THE DIRECTORY DCB ADDRESS
         A     2,DCBPTR            ..
         USING IHADCB,2            MAP IT
         MVC   DCBDDNAM(8),DDNAME  MOVE THE DDNAME INTO IT
         OPEN  ((2),INPUT),MF=(E,OPENLST)  OPEN IT
         TM    DCBOFLGS,X'10'      DID IT OPEN OK?
         BNZ   DOOK                YES, THE DIRECTORY OPENED OK
         LA    3,DIROFAIL          NO, GIVE HIM AN ERROR MESSAGE
         ST    3,ERRPTR            ..
         LA    15,12               1ST=12  2ND=16
         B     FINISH              ..
         EJECT
DOOK     EQU   *
         LA    8,DIRDECB-MVBLK
         A     8,DCBPTR
         READ  (8),SF,(2),DIRKEY,264,MF=E DO FIRST READ
         MVI   PREVBLK,X'00'       INITIALIZE FLAG
         LA    5,0                 INITIALIZE COUNT
         MVC   BLDLFF(2),=X'0001'  INITIALIZE FOR REAL BLDL        1.7
         MVC   BLDLLL(2),=X'000E'  ..                              1.7
         MVI   CONCAT#,X'00'       INITIALIZE CONCATENATION COUNT  1.8
CHECKDIR EQU   *
         CHECK (8)                 WAIT FOR READ TO FINISH
         MVC   PROCKEY(8),DIRKEY   MOVE OUT OF WAY FOR READ        1.8
         MVC   PROCBLK(256),DIRBLK ..                              1.8
         READ  (8),SF,(2),DIRKEY,264,MF=E START ANOTHER READ
         LA    3,PROCBLK           GET THE STARTING ADDR OF THE BLK
         LH    4,0(3)              LOAD THE LENGTH FIELD
         LA    4,0(4,3)            COMPUTE THE ENDING ADDRESS
         LA    3,2(3)              MOVE PAST THE LENGTH FIELD
         CLI   PROCKEY,X'FF'       IS THE KEY "LAST"?              1.8
         BE    CHKMEM              YES, ALWAYS BR FOR SIMPLICITY   1.8
         CLI   CONCAT#,X'00'       IS THIS THE FIRST DATA SET?     1.8
         BE    NEXTMEM             YES, NO NEED TO CHECK MEMBER    1.8
         EJECT
CHKMEM   EQU   *
         CLR   3,4                 ARE WE AT THE END OF THIS BLK?  1.8
         BNL   CHECKDIR            YES, GO WAIT ON NEXT READ       1.8
         MVC   BLDLNAME(8),0(3)    COPY IN THE 1ST MEMBER NAME     1.8
         L     1,DCBPTR            GET DCB ADDRESS FOR BLDL        1.8
         BLDL  (1),BLDLLST         DO REAL BLDL, SEE IF MEM THERE  1.8
         LTR   15,15               CHECK RETURN CODE               1.8
         BNZ   CHECKDIR            NOT THERE, CONT WITH NEXT BLK   1.8
         CLC   CONCAT#(1),BLDLK    IS IT THE RIGHT DATA SET?       1.8
         BNE   CHECKDIR            NO, WRONG DATA SET              1.8
         CLI   PROCKEY,X'FF'       ARE WE CHANGING DATA SETS?      1.8
         BNE   NEXTMEM             NO, JUST GO PROCESS BLK         1.8
         SLR   9,9                 ZERO OUT REGISTER               1.8
         IC    9,CONCAT#           ADD ONE TO DATA SET COUNT       1.8
         LA    9,1(9)              ..                              1.8
         STC   9,CONCAT#           ..                              1.8
NEXTMEM  EQU   *
         CLR   3,4                 ARE WE AT THE END OF THIS BLOCK?
         BNL   CHECKDIR            YES, GO WAIT ON NEXT READ
         CLI   0(3),X'FF'          IS THIS THE LAST ENTRY?
         BE    CHECKDIR            YES, SEE IF PDS CONCATENATED
         LA    5,1(5)              COUNT THIS ENTRY
         LA    3,11(3)             GET THE USER HALFWORD DATA COUNT
         IC    6,0(3)              ..
         SLL   6,27                ..
         SRL   6,26                ..
         LA    3,1(6,3)            MOVE OVER USER DATA
         B     NEXTMEM             SEE IF WE ARE AT THE END OF THE BLK
         EJECT
CLOSEDIR EQU   *
         LR    3,5                 COPY COUNT OF MEMBER ENTRIES
         CLOSE ((2)),MF=(E,OPENLST)  CLOSE THE DIRECTORY
         LA    6,74                EACH ENTRY GETS 74 BYTES
         MR    4,6                 ..
         LA    5,2(5)              ADD TWO FOR COUNT FIELD
         LR    0,5                 DO GETMAIN FOR BLDL AREA
         GETMAIN R,LV=(0)          ..
         ST    1,BLDLPTR           SAVE ADDRESS
         LR    6,1                 ..
         STH   3,0(6)              STORE COUNT IN BLDL TABLE
         LA    6,2(6)              MOVE PAST COUNT AREA
         MVC   DCBEODA(3),=AL3(MEMBUILT) PREPARE FOR NEXT TIME THROUGH
         MVC   DCBDDNAM(8),DDNAME  ..
         OPEN  ((2),INPUT),MF=(E,OPENLST)  OPEN IT AGAIN
         TM    DCBOFLGS,X'10'      DID IT OPEN OK?
         BNZ   DOOK2               YES, GO AHEAD AND PROCESS
         LA    3,DIROFAIL          NO, GIVE ERROR MESSAGE
         ST    3,ERRPTR            ..
         LA    15,16               1ST=12  2ND=16
         B     FINISH              ..
         EJECT
DOOK2    EQU   *
         READ  (8),SF,(2),DIRKEY,264,MF=E READ FIRST BLOCK
         MVI   CONCAT#,X'00'       INIT CONCATENATION COUNT        1.8
CHECK2   EQU   *
         CHECK (8)
         MVC   PROCKEY(8),DIRKEY   MOVE OUT OF WAY FOR READ        1.8
         MVC   PROCBLK(256),DIRBLK ..                              1.8
         READ  (8),SF,(2),DIRKEY,264,MF=E READ FOR NEXT TIME AROUND
         LA    3,PROCBLK           GET STARTING ADDRESS
         LH    4,0(3)              GET BLOCK LENGTH
         LA    4,0(4,3)            COMPUTE ENDING ADDRESS
         LA    3,2(3)              MOVE PAST BLOCK LENGTH FIELD
         CLI   PROCKEY,X'FF'       IS THE KEY "LAST"?              1.8
         BE    CHKMEM2             YES, ALWAYS BR FOR SIMPLICITY   1.8
         CLI   CONCAT#,X'00'       IS THIS THE 1ST DATA SET?       1.8
         BE    NEXTMEM2            YES, NO NEED TO CHECK MEMBER    1.8
         EJECT
CHKMEM2  EQU   *
         CLR   3,4                 ARE WE AT THE END OF THIS BLK?  1.8
         BNL   CHECK2              YES, GO WAIT ON NEXT READ       1.8
         MVC   BLDLNAME(8),0(3)    COPY IN THE 1ST MEMBER NAME     1.8
         L     1,DCBPTR            GET DCB ADDRESS FOR BLDL        1.8
         BLDL  (1),BLDLLST         DO REAL BLDL, SEE IF MEM THERE  1.8
         LTR   15,15               CHECK RETURN CODE               1.8
         BNZ   CHECK2              NOT THERE, CONT WITH NEXT BLK   1.8
         CLC   CONCAT#(1),BLDLK    IS IT THE RIGHT DATA SET?       1.8
         BNE   CHECK2              NO, WRONG DATA SET              1.8
         CLI   PROCKEY,X'FF'       ARE WE CHANGING DATA SETS?      1.8
         BNE   NEXTMEM2            NO, JUST GO PROCESS BLK         1.8
         SLR   9,9                 ZERO OUT REGISTER               1.8
         IC    9,CONCAT#           ADD ONE TO DATA SET COUNT       1.8
         LA    9,1(9)              ..                              1.8
         STC   9,CONCAT#           ..                              1.8
NEXTMEM2 EQU   *
         CLR   3,4                 ARE WE AT THE END OF THIS BLOCK?
         BNL   CHECK2              YES, WAIT ON PENDING READ
         CLI   0(3),X'FF'          IS THIS THE LAST ENTRY?
         BE    CHECK2              YES, SEE IF PDS CONCATENATED
         MVC   0(74,6),0(3)        MOVE IN THE DIRECTORY ENTRY
         LA    6,74(6)             POINT TO NEXT POSITION IN TABLE
         LA    3,11(3)             FIND BEGINNING OF NEXT ENTRY
         IC    7,0(3)              ..
         SLL   7,27                ..
         SRL   7,26                ..
         LA    3,1(7,3)            ..
         B     NEXTMEM2            SEE IF WE ARE AT THE END OF THIS BLK
MEMBUILT EQU   *
         CLOSE ((2)),MF=(E,OPENLST)  CLOSE THE DIRECTORY
         MVC   DCBEODA(3),=AL3(CLOSEDIR) PREPARE FOR NEXT TIME THROUGH
         LA    15,0                GOOD RETURN CODE
         B     FINISH
* END BLDL ROUTINE
         EJECT
* FIND BY TTR ROUTINE
FINDT    EQU   *
         TM    CHECKIT,X'80'       IS THERE IS A CHECK OUTSTANDING?
         BZ    CHKDONE             NO, CHECKS PENDING
         L     2,DECBPTR           YES, WE HAVE TO CHECK FIRST
         CHECK (2)                 CHECK IT
         NI    CHECKIT,X'00'       CLEAR PENDING CHECK
CHKDONE  EQU   *
         NI    INFLAG,X'80'        RESET EOF FLAG
         L     1,DCBPTR            SET UP FOR FIND
         LA    0,FINDTTR           ..
         FIND  (1),(0),C           DO FIND BY TTR
         B     FMRT(15)            CHECK RETURN CODE
* END FIND BY TTR ROUTINE
         EJECT
* FIND BY MEMBER NAME ROUTINE
FINDMEM  EQU   *
         TM    CHECKIT,X'80'       IS THERE IS A CHECK OUTSTANDING?
         BZ    CHECDONE            NO, CHECKS PENDING
         L     2,DECBPTR           YES, WE HAVE TO CHECK FIRST
         CHECK (2)                 CHECK IT
         NI    CHECKIT,X'00'       CLEAR PENDING CHECK
CHECDONE EQU   *
         NI    INFLAG,X'80'        RESET EOF FLAG
         L     1,DCBPTR            SET UP FOR FIND
         LA    0,MEMNAME           ..
         FIND  (1),(0),D           DO FIND BY MEMBER NAME
         B     FMRT(15)            CHECK RETURN CODE
FMRT     EQU   *
         B     GOODONE             GOOD RETURN CODE
         B     NOTFOUND            NAME NOT FOUND
         B     PERMVIRT            PERMANENT I/O ERROR OR
*                                  NOT ENOUGH VIRTUAL STORAGE
GOODONE  EQU   *
         L     2,DCBPTR            SET UP FOR READONE
         L     4,BUFADDR           ..
         B     READONE             DO PRIMER READ
NOTFOUND EQU   *
         LA    2,NONAME            GIVE AN ERROR MESSAGE
         B     ENDERRT             ..
PERMVIRT EQU   *
         LA    2,PEVIERR           GIVE AN ERROR MESSAGE
         LA    15,12               CHANGE RETURN CODE
ENDERRT  EQU   *
         ST    2,ERRPTR            SAVE POINTER FOR MESSAGE
         B     FINISH              RETURN TO CALLER
* END FIND BY MEMBER NAME ROUTINE
         EJECT
* CLOSE ROUTINE
CLOSEDCB EQU   *
         L     2,DCBPTR            POINT TO DCB
         CLOSE ((2)),MF=(E,OPENLST)  CLOSE DCB
         L     1,BUFADDR           FREE THE BUFFER AREA
         LH    0,DCBBLKSI          ..
         LTR   0,0                 CHECK FOR ZERO BLKSIZE
         BZ    NOBUFF              ..
         FREEMAIN R,LV=(0),A=(1)   ..
NOBUFF   EQU   *
         L     1,DCBPTR            FREE THE CONTROL BLOCKS' AREA
         LA    0,MVEND-MVBLK       ..
         FREEMAIN R,LV=(0),A=(1)   ..
         LA    2,0                 ZERO IN R2
         TM    INFLAG,X'80'        WAS IT OPENED FOR OUTPUT?
         BZ    NOBLDLPT            YES, NO BLDL LIST
         C     2,BLDLPTR           NO, DID WE HAVE A BLDL LIST?
         BE    NOBLDLPT            NO, SO WE DON'T NEED TO FREE IT
         L     1,BLDLPTR           YES, FREE THE BLDL AREA
         LH    5,0(1)              ..
         LA    3,74                ..
         MR    4,3                 ..
         LR    0,5                 ..
         LA    0,2(0)              ..
         FREEMAIN R,LV=(0),A=(1)   ..
         ST    2,BLDLPTR           REINIT PTRS SO HE WON'T USE THEM
NOBLDLPT EQU   *
         ST    2,DCBPTR            ..
         ST    2,DECBPTR           ..
         ST    2,BUFADDR           ..
         ST    2,BUFPOS            ..
         LA    15,0                RETURN CODE (ALWAYS GOOD)
         B     FINISH              RETURN TO CALLER
* END CLOSE ROUTINE
         EJECT
* STOW ROUTINES
* STOW ADD ROUTINE
STOWADD  EQU   *
         L     1,DCBPTR            SET UP FOR STOW
         L     0,BLDLPTR           ..
         STOW  (1),(0)             STOW THE MEMBER INTO THE DIRECTORY
         B     STOWRC(15)          BRANCH TO COMMON RETURN CODE SECTION
* END STOW ADD ROUTINE
* STOW CHANGE ROUTINE
STOWCHAN EQU   *
         L     1,DCBPTR            SET UP FOR STOW
         L     0,BLDLPTR           ..
         STOW  (1),(0),C           STOW THE MEMBER INTO THE DIRECTORY
         B     STOWRC(15)          BRANCH TO COMMON RETURN CODE SECTION
* END STOW CHANGE ROUTINE
* STOW REPLACE ROUTINE
STOWREPL EQU   *
         L     1,DCBPTR            SET UP FOR STOW
         L     0,BLDLPTR           ..
         STOW  (1),(0),R           STOW THE MEMBER INTO THE DIRECTORY
         B     STOWRC(15)          BRANCH TO COMMON RETURN CODE SECTION
* END STOW REPLACE ROUTINE
         EJECT
* STOW DELETE ROUTINE
STOWDELE EQU   *
         L     1,DCBPTR            SET UP FOR STOW
         L     0,BLDLPTR           ..
         STOW  (1),(0),D           STOW THE MEMBER IN THE DIRECTORY
         B     STOWRC(15)          BRANCH TO COMMON RETURN CODE SECTION
* END STOW DELETE ROUTINE
* STOW RETURN CODE ROUTINE
STOWRC   EQU   *
         B     FINISH              GOOD RETURN CODE
         B     ALRDYHR             ALREADY PRESENT IN DIRECTORY
         B     NMNTFD              NAME NOT FOUND IN DIRECTORY
         B     NOSPDIR             NO SPACE LEFT IN DIRECTORY
         B     PERMIO              PERMANANT IO ERROR ON DIRECTORY
         B     STNOTOPN            NOT OPEN OR OPEN FOR INPUT
         B     STNOVIRT            NOT ENOUGH VIRTUAL STORAGE
ALRDYHR  EQU   *
         LA    2,NOTNEWNM          GIVE MESSAGE
         B     STOWRCE             ..
NMNTFD   EQU   *
         LA    2,ISNEWNM           GIVE MESSAGE
         LA    15,4                CHANGE RETURN CODE
         B     STOWRCE             ..
NOSPDIR  EQU   *
         LA    2,DIRFULL           GIVE MESSAGE
         B     STOWRCE             ..
PERMIO   EQU   *
         LA    2,STIOERR           GIVE MESSAGE
         LA    15,12               CHANGE RETURN CODE
         B     STOWRCE             ..
STNOTOPN EQU   *
         LA    2,STOPENBD          GIVE MESSAGE
         LA    15,8                CHANGE RETURN CODE
         B     STOWRCE             ..
STNOVIRT EQU   *
         LA    2,STNOSTOR          GIVE MESSAGE
         LA    15,12               CHANGE RETURN CODE
STOWRCE  EQU   *
         ST    2,ERRPTR            NOT NECESSARILY AN ERROR BUT A MSG
         B     FINISH              RETURN TO CALLER
* END STOW RETURN CODE ROUTINE
* END STOW ROUTINES
         EJECT
* READ ROUTINES
READBLK  EQU   *
         L     2,DCBPTR            SET UP FOR READS
         USING IHADCB,2            MAP DCB
         TM    INFLAG,X'80'        IS IT OPEN FOR INPUT?
         BNZ   INOKRD              YES, IT'S OPEN FOR READ
         LA    2,INOLYRD           NO, GIVE HIM A MESSAGE
         ST    2,ERRPTR            ..
         LA    15,8                ..
         B     FINISH              ..
INOKRD   EQU   *
         L     4,BUFADDR           SET UP FOR READONE ROUTINE
         TM    CHECKIT,X'80'       IS THERE A CHECK OUTSTANDING?
         BZ    NOCHCK              NO CHECK IS NECESSARY
         L     3,DECBPTR           SET UP FOR CHECK
         CHECK (3)                 DO CHECK
         NI    CHECKIT,X'00'       ZERO OUT FLAG FIELD
         L     7,16(3)             POINT TO IOB
         LH    8,14(7)             LOAD RESIDUAL COUNT
         LH    7,DCBBLKSI          LOAD OFFICIAL BLOCKSIZE
         SR    7,8                 CALCULATE # BYTES IN THIS BLOCK
         LA    6,0(7,4)            CALCULATE THE ENDING ADDRESS
         ST    6,BUFEND            SAVE FOR LATER
         TM    DCBRECFM,X'C0'      WHAT KIND OF RECFM IS THIS?
         BO    NOCHCK              RECFM=U
         BZ    NOCHCK              RECFM=
         TM    DCBRECFM,X'80'      WHAT RECFM IS LEFT?
         BO    NOCHCK              RECFM=F
         L     8,BUFPOS            RECFM=V
         LA    8,4(8)              GO PAST LENGTH FIELD
         ST    8,BUFPOS            SAVE IT FOR LATER
         EJECT
NOCHCK   EQU   *
         L     8,BUFPOS            SET UP FOR MVCL
         TM    DCBRECFM,X'C0'      DO WE NEED TO DEBLOCK?
         BZ    GETREC              RECFM=
         BO    GETREC              RECFM=U
         TM    DCBRECFM,X'80'      WHATS LEFT?
         BO    FFORMAT             RECFM=F
         LH    7,0(8)              GET LENGTH FIELD FOR RECFM=V
         SH    7,=H'4'             SUBTRACT 4 FOR LENGTH FIELD
         LA    8,4(8)              MOVE PAST LENGTH FIELD
         B     GETREC              RECFM=V
FFORMAT  EQU   *
         LH    7,DCBLRECL          USE LOGICAL RECORD LENGTH
GETREC   EQU   *
         STH   7,RECLEN            SAVE LENGTH FOR VARYING STR
         LA    6,REC               SET UP FOR MVCL
         LR    9,7                 SET UP FOR MVCL
         MVCL  6,8                 MOVE LOGICAL REC SO HE CAN GET IT
         ST    8,BUFPOS            SAVE PRESENT POSITION IN BUFFER
         C     8,BUFEND            ARE WE THROUGH WITH THIS READ?
         LA    15,0
         BL    FINISH              NO, JUST RETURN THIS LOGICAL RECORD
         B     READONE             SET UP READ FOR NEXT TIME
READONE  EQU   *
* USED FROM FIND AND READ ROUTINES
* ASSUMES R2=DCB R4=BUFADDR
         ST    14,RTRNADDR         SAVE RETURN ADDRESS
         L     3,DECBPTR           SET UP FOR READ
         READ  (3),SF,(2),(4),'S',MF=E  READ A BLOCK
         OI    CHECKIT,X'80'       SET CHECK FLAG
         ST    4,BUFPOS            RESET CURRENT BUFFER POSITION
         L     14,RTRNADDR         GET RETURN ADDRESS
         LA    15,0                GOOD RETURN CODE
         B     FINISH              RETURN TO CALLER
EODAD    EQU   *
         NI    CHECKIT,X'00'       RESET CHECK PENDING FLAG
         OI    INFLAG,X'01'        SET FLAG FOR EOF
         LA    15,0                GOOD RETURN CODE
         B     FINISH              RETURN TO CALLER
* END READ ROUTINES
         EJECT
* WRITE ROUTINE
WRITEBLK EQU   *
         LH    3,RECLEN            GET THE LENGTH HE WANTS TO WRITE
         C     3,BLKSIZE           IS IT SMALLER THAN THE BLKSIZE?
         BNH   CHECKLOW            YES, IT'S OK TO WRITE IT
         LA    3,TOOLONG           NO, GIVE HIM AN ERROR MESSAGE
         ST    3,ERRPTR            ..
         LA    15,8                ..
         B     FINISH              ..
CHECKLOW EQU   *
         C     3,=F'0'             IS IT ZERO?
         BH    LENTHOK             YES, IT'S OK TO WRITE IT
         LA    3,TOOSHORT          NO, GIVE HIM AN ERROR MESSAGE
         ST    3,ERRPTR            ..
         LA    15,8                ..
         B     FINISH              ..
LENTHOK  EQU   *
         L     6,DECBPTR           GET DECBPTR FOR CHECK & WRITE
         TM    CHECKIT,X'80'       IS THERE A CHECK WAITING?
         BZ    NOPECK              NO CHECK WAITING
         CHECK (6)                 DO CHECK
         NI    CHECKIT,X'00'       ZERO OUT FLAG FOR CHECK
         EJECT
NOPECK   EQU   *
         TM    INFLAG,X'80'        IS HE OPEN FOR INPUT?
         BZ    OOUTIND             NO, HE'S OK FOR OUTPUT
         LA    3,NOTOUTPT          YES, TELL HIM ABOUT IT
         ST    3,ERRPTR            ..
         LA    15,8                ..
         B     FINISH              ..
OOUTIND  EQU   *
         L     2,BUFADDR           MOVE REC TO BUFFER
         LA    4,REC               ..
         LR    5,3                 GET LENGTH
         MVCL  2,4                 MOVE REC
         LH    3,RECLEN            REINIT LENGTH
         L     4,DCBPTR            GET READY FOR WRITE
         L     5,BUFADDR           ..
         USING IHADCB,4            MAP DCB
         STH   3,DCBBLKSI          MOVE IN BLKSIZE
         OI    CHECKIT,X'80'       SET FLAG TO INDICATE NEED CHECK
         TM    DCBRECFM,X'C0'      WHAT IS THE RECFM
         BO    UFORMAT             RECFM=U
         WRITE (6),SF,(4),(5),MF=E WRITE OUT BLOCK
         LA    15,0                GOOD RETURN CODE
         B     FINISH              ALL DONE
UFORMAT  EQU   *
         WRITE (6),SF,(4),(5),'S',MF=E WRITE OUT BLOCK
         DROP  4                   DONE WITH DCB
         LA    15,0                GOOD RETURN CODE
         B     FINISH              ALL DONE
* END WRITE ROUTINE
         EJECT
* NOTE ROUTINE
NOTEPOS  EQU   *
         TM    CHECKIT,X'80'       IS THERE IS A CHECK OUTSTANDING?
         BZ    CKDONE              NO, CHECKS PENDING
         L     2,DECBPTR           YES, WE HAVE TO CHECK FIRST
         CHECK (2)                 CHECK IT
         NI    CHECKIT,X'00'       CLEAR PENDING CHECK
CKDONE   EQU   *
         L     1,DCBPTR            SET UP FOR NOTE
         NOTE  (1)                 DO NOTE
         ST    1,FINDTTR           SAVE THE TTR FOR THE CALLER
         LA    15,0                GOOD RETURN CODE
         B     FINISH              RETURN TO CALLER
* END NOTE ROUTINE
         EJECT
* OPEN ROUTINE
OPENDCB  EQU   *
         LA    3,JFCBAREA          SET JFCBLST
         ICM   3,B'1000',=X'07'    ..
         ST    3,JFCBLST           ..
         LA    3,MVEND-MVBLK       GET A UNIQUE SET OF CONTROL BLKS
         GETMAIN R,LV=(3)          ..
         ST    1,DCBPTR            SAVE THE DCB ADDRESS
         LA    2,PODECB-MVBLK      FIGURE OUT THE DECB ADDRESS
         AR    2,1                 ..
         ST    2,DECBPTR           SAVE THE DECB ADDRESS
         LR    5,3                 SET UP FOR MOVING BLK INTO NEW AREA
         LR    2,1                 ..
         LA    4,MVBLK             ..
         MVCL  2,4                 MOVE A COPY OF THE CONTROL BLOCKS
         LR    2,1                 RESET THE DCB ADDRESS
         USING IHADCB,2            MAP THE NEW DCB
         MVC   DCBDDNAM(8),DDNAME  MOVE IN THE DDNAME
         LA    7,JFCBLST           PUT IN JFCBLST ADDR IN DCB EXIT LIST
         ST    7,DCBEXLST          ..
         LA    7,0                 INITIALIZE THE BIG PARM
         ST    7,ERRPTR            ..
         STC   7,CHECKIT           ..
         ST    7,BLDLPTR           ..
         ST    7,BUFEND            ..
         ST    7,FINDTTR           ..
         ST    7,MEMNAME           ..
         ST    7,MEMNAME+4         ..
*        RDJFCB ((2)),MF=(E,RDJLST) GET THE DSN AND VOLUME         2.1
         LA    1,RDJLST            LOAD PARAMETER REG 1            2.1
         ST    2,0(1)              STORE INTO LIST                 2.1
         LA    14,128              INITIALIZE OPTION BYTE          2.1
         STC   14,0(1)             ..                              2.1
         SVC   64                  ISSUE RDJFCB SVC                2.1
         LTR   15,15               GOOD RETURN CODE?
         BZ    DSNOK               YES
         LA    3,NORDJ             NO, GIVE AN ERROR MESSAGE
         ST    3,ERRPTR            ..
         B     FINISH              ..
         EJECT
DSNOK    EQU   *
         MVC   DSNAME,JFCBDSN      MOVE DSN INTO PARM
         MVC   VOLUME,JFCBVOL      MOVE VOL INTO PARM
         ST    7,DCBEXLST          ZERO DCBEXLST                   2.0
         TM    INFLAG,X'80'        DOES HE WANT OPENED FOR INPUT?
         BZ    OOUT                NO, OPEN FOR OUTPUT
         OPEN  ((2),INPUT),MF=(E,OPENLST)  YES, OPEN FOR INPUT
         B     CKOPEN              GO SEE IF IT OPENED
OOUT     EQU   *
         OPEN  ((2),OUTPUT),MF=(E,OPENLST)  OPEN FOR OUTPUT
CKOPEN   EQU   *
         TM    DCBOFLGS,X'10'      DID IT OPEN OK?
         BNZ   OOK                 YES, IT'S NOW OPEN
         LA    3,OERRMSG           NO, GIVE AN ERROR MESSAGE
         ST    3,ERRPTR            ..
         LA    15,16               ..
         B     FINISH              ..
OOK      EQU   *
         LH    0,DCBBLKSI          GET THE BLOCK SIZE
         LTR   0,0                 IS THE BLKSIZE ZERO?
         BNZ   GETBUFF             NO, GET A BUFFER                2.0
         LA    3,BBLKMSG           ZERO BLKSIZE - INFORM THE USER
         ST    3,ERRPTR            ..
         LA    15,4                ..
         B     FINISH              ..
GETBUFF  EQU   *
         ST    0,BLKSIZE           SAVE IT FOR WRITE ROUTINE
         GETMAIN R,LV=(0)          GET THE BUFFER AREA
         ST    1,BUFADDR           SAVE ITS ADDRESS
         ST    1,BUFPOS            ..
         LA    15,0                NO, NORMAL PROCESSING
         B     FINISH              RETURN TO CALLER
* END OPEN ROUTINE
         EJECT
***********************************************************************
*** EPILOGUE CODE *************************************************2.0*
***********************************************************************
FINISH   DS    0H
         LR    1,13                COPY R13
         L     13,4(13)            RESTORE R13
         ST    15,16(13)           SAVE RETURN CODE
         TM    0(1),X'80'          IS DSA FROM PL/I?
         BO    RETURN              YES, NO FREEMAIN REQUIRED
         LA    0,STOREND-STORAGE   GET LENGTH
         FREEMAIN R,LV=(0),A=(1)   FREE DSA
RETURN   LM    14,12,12(13)        RESTORE CALLER'S REGISTERS
         BR    14                  RETURN
* END EPILOGUE CODE
         EJECT
***********************************************************************
*** STATIC STORAGE AREA ***********************************************
***********************************************************************
         LTORG
         EJECT
* DATA AREA FOR INITIALIZATION CODE
         DS    0H
INVCMD   DS    0CL176
         DC    H'174'
         DC    C'FIRST PARAMETER INVALID; VALUE MUST BE ONE OF THE '
         DC    C'FOLLOWING:  OPEN, BLDL, FINDT(TR), FINDM(EM), CLOSE,'
         DC    C'STOWC(HANGE), STOWD(ELETE), STOWR(EPLACE), STOW(ADD),'
         DC    C'READ, WRITE, NOTE'
* END DATA AREA FOR INITIALIZATION CODE
* DATA AREA FOR FIND ROUTINES
         DS    0H
NONAME   DS    0CL16
         DC    H'14'
         DC    C'NAME NOT FOUND'
         DS    0H
PEVIERR  DS    0CL87
         DC    H'85'
         DC    C'PERMANENT I/O ERROR DURING DIRECTORY SEARCH OR '
         DC    C'INSUFFICIENT VIRTUAL STORAGE AVAILABLE'
* END DATA AREA FOR FIND ROUTINES
* DATA AREA FOR STOW ROUTINES
         DS    0H
NOTNEWNM DS    0CL47
         DC    H'45'
         DC    C'DIRECTORY ALREADY CONTAINS THE SPECIFIED NAME'
         DS    0H
ISNEWNM  DS    0CL35
         DC    H'33'
         DC    C'SPECIFIED NAME COULD NOT BE FOUND'
         DS    0H
DIRFULL  DS    0CL28
         DC    H'26'
         DC    C'NO SPACE LEFT IN DIRECTORY'
         DS    0H
STIOERR  DS    0CL51
         DC    H'49'
         DC    C'PERMANENT I/O ERROR OCCURED DURING DIRECTORY STOW'
         DS    0H
STOPENBD DS    0CL52
         DC    H'50'
         DC    C'DATA SET NOT OPENED OR IS OPENED FOR INPUT ON STOW'
STNOSTOR DS    0CL49
         DC    H'47'
         DC    C'INSUFFICIENT VIRTUAL STORAGE AVAILABLE FOR STOW'
* END DATA AREA FOR STOW ROUTINES
         EJECT
* DATA AREA FOR WRITE ROUTINE
         DS    0H
TOOLONG  DS    0CL51
         DC    H'49'
         DC    C'THE BLOCK/RECORD SUPPLIED EXCEEDS THE DCB BLKSIZE'
         DS    0H
TOOSHORT DS    0CL55
         DC    H'53'
         DC    C'THE BLOCK/RECORD SUPPLIED HAS LENGTH OF ZERO'
         DS    0H
NOTOUTPT DS    0CL39
         DC    H'37'
         DC    C'ATTEMPT TO WRITE PDS OPENED FOR INPUT'
* END DATA AREA FOR WRITE ROUTINE
* DATA AREA FOR READ ROUTINE
         DS    0H
INOLYRD  DS    0CL42
         DC    H'40'
         DC    C'READ ONLY VALID FOR PDS OPENED FOR INPUT'
* END DATA AREA FOR READ ROUTINE
* DATA AREA FOR BLDL ROUTINE
         DS    0H
DIROFAIL DS    0CL24
         DC    H'22'
         DC    C'DIRECTORY OPEN FAILED '
         DS    0H
NOTINP   DS    0CL32
         DC    H'30'
         DC    C'ONLY INPUT FILE VALID FOR BLDL'
* END DATA AREA FOR BLDL ROUTINE
         EJECT
* DATA AREA FOR OPEN ROUTINE
         DS    0H
OERRMSG  DS    0CL25
         DC    H'23'
         DC    C'OPEN WAS NOT SUCCESSFUL'
         DS    0H
BBLKMSG  DS    0CL34
         DC    H'32'
         DC    C'DATA SET OPENED HAS ZERO BLKSIZE'
         DS    0H
NORDJ    DS    0CL15
         DC    H'13'
         DC    C'RDJFCB FAILED'
* END DATA AREA FOR OPEN ROUTINE
         EJECT
* DATA AREA FOR DCBS, DECBS
MVBLK    DCB   DSORG=PO,MACRF=(R,W),EODAD=EODAD
*              SYNAD=PDSSYNAD
         READ  PODECB,SF,MF=L
         READ  DIRDECB,SF,MF=L
DIRECT   DCB   DSORG=PS,MACRF=(R),DEVD=DA,BLKSIZE=256,KEYLEN=8,        X
               RECFM=F,EODAD=CLOSEDIR
*              SYNAD=DIRSYNAD
MVEND    EQU   *
* END DATA AREA FOR DCBS, DECBS
         EJECT
***********************************************************************
*** DYNAMIC STORAGE AREA **********************************************
***********************************************************************
STORAGE  DSECT
SAVEAREA DS    22F                                                 2.0
RTRNADDR DS    F
DIRKEY   DS    8C
DIRBLK   DS    256C
PROCKEY  DS    8C                                                  1.8
PROCBLK  DS    256C
PREVBLK  DS    XL1
JFCBAREA DS    0F
JFCBDSN  DS    CL44
         DS    74X
JFCBVOL  DS    CL6
         DS    52X
JFCBLST  DS    0F
         DC    X'07'
         DC    AL3(JFCBAREA)
BLDLLST  DS    0F                                                  1.7
BLDLFF   DC    X'0001'                                             1.7
BLDLLL   DC    X'000E'                                             1.7
BLDLNAME DS    CL8                                                 1.7
         DS    3X                                                  1.8
BLDLK    DS    X                                                   1.8
         DS    2X                                                  1.8
CONCAT#  DS    X                                                   1.8
OPENLST  OPEN  (),MF=L                                             2.0
RDJLST   RDJFCB (),MF=L                                            2.1
STOREND  DS    0D
* END DYNAMIC STORAGE DSECT
         EJECT
* COMMON PARM DSECT
PARM     DSECT
DCBPTR   DS    F
DECBPTR  DS    F
BLDLPTR  DS    F
BUFADDR  DS    F
BUFPOS   DS    F
BLKSIZE  DS    0F
BUFEND   DS    F
ERRPTR   DS    F
DDNAME   DS    CL8
FINDTTR  DS    F
MEMNAME  DS    CL8
CHECKIT  DS    X
INFLAG   DS    X
DSNAME   DS    CL44
VOLUME   DS    CL6
RECAREA  DS    0CL32762
RECLEN   DS    H
REC      DS    CL32760
* END COMMON PARM DSECT
         EJECT
* IHADCB DSECT (DCB MAP)
         DCBD DSORG=PO,DEVD=DA
* END IHADCB DSECT (DCB MAP)
         END
