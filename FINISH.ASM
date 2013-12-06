         MACRO
&LBL     FINISH &TYPE=,&RC=
.**********************************************************************
.*                                                                    *
.* THIS MACRO PROVIDES REENTRANT FINISHING CODE FOR THE FOLLOWING:    *
.*   1)  A REGULAR ASSEMBLER ROUTINE (EXCEPT HAS 20 WORD SAVE AREA)   *
.*   2)  AN ASSEMBLER ROUTINE TO BE CALLED FROM PL/I                  *
.*   3)  AN ASSEMBLER MAIN ROUTINE WHICH WILL CALL PL/I SUBROUTINES   *
.*                                                                    *
.*  RC IS AN ABSOLUTE RETURN CODE OR IF SET TO (15) RETURN CODE       *
.*     SHOULD EXIST IN REGISTER 15                                    *
.*                                                                    *
.* IT IS INTENDED TO BE USED WITH THE SETUP MACRO.  FURTHER           *
.* DOCUMENTATION IS CONTAINED WITH THAT MACRO.                        *
.*                                                                    *
.**********************************************************************
         AIF   ('&TYPE' EQ 'PLI').PLI
         AIF   ('&TYPE' EQ 'ASMPLI').ASMPLI
&LBL     LR    1,13
         L     13,4(13)        RESTORE REGS
         AIF   ('&RC' NE '(15)').NORC
         ST    15,16(13)       SAVE RETURN CODE IN CALLER'S SAVE AREA
.NORC    ANOP
         FREEMAIN R,LV=80,A=(1) GET RID OF SAVE AREA
         LM    14,12,12(13)    RESTORE REGS
         BR    14              RETURN TO CALLER
         MEXIT
.PLI     ANOP
&LBL     LR    1,13
         L     13,4(13)        RESTORE REGS
         AIF   ('&RC' NE '(15)').NORCP
         ST    15,16(13)       SAVE RETURN CODE IN CALLER'S SAVE AREA
.NORCP   ANOP
         FREEMAIN R,LV=80,A=(1) GET RID OF SAVE AREA
         LM    14,11,12(13)    ..
         BR    14              RETURN TO CALLER
         MEXIT
.ASMPLI  ANOP
&LBL     LR    1,13
         L     13,4(13)        RESTORE REGS
         AIF   ('&RC' NE '(15)').NORCA
         ST    15,16(13)       SAVE RETURN CODE IN CALLER'S SAVE AREA
.NORCA   ANOP
         FREEMAIN R,LV=80,A=(1) GET RID OF SAVE AREA
         LM    14,12,12(13)    ..
         LR    0,13            GET ADDR OF TERMINATING DSA
         BR    14              RETURN TO PL/I TERMINATION ROUTINES
         MEND
