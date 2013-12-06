         MACRO
&LBL     SETUP &TYPE=,&BASE=1,&CSECT=
.**********************************************************************
.*                                                                    *
.* THIS MACRO PROVIDES REENTRANT STARTING CODE FOR THE FOLLOWING:     *
.*   1)  A REGULAR ASSEMBLER ROUTINE (EXCEPT HAS 20 WORD SAVE AREA)   *
.*   2)  AN ASSEMBLER ROUTINE TO BE CALLED FROM PL/I                  *
.*   3)  AN ASSEMBLER MAIN ROUTINE WHICH WILL CALL PL/I SUBROUTINES   *
.*                                                                    *
.* TO UNDO WHAT THIS MACRO DOES USE THE FINISH MACRO.                 *
.*                                                                    *
.* THE LABEL SPECIFIED ON THE MACRO STATEMENT BECOMES THE CSECT NAME  *
.* FOR (1) AND THE ENTRY POINT FOR (2) AND (3).  THIS NAME IS ALSO    *
.* PUT INTO AN IDENTIFIER SECTION AT THE BEGINING OF THE CODE         *
.* FOLLOWED BY ITS LENGTH.                                            *
.*                                                                    *
.* THERE ARE TWO KEYWORD PARAMETERS WHICH CONTROL THE MACRO           *
.* EXPANSION.  TYPE, DETERMINES WHICH OF (1), (2) OR (3) TO GENERATE, *
.* AND BASE GIVES THE NUMBER OF BASE REGISTERS DESIRED.  FURTHER      *
.* DETAILS BY CLASS FOLLOW:                                           *
.*                                                                    *
.* TYPE=                                                              *
.*   1)  NULL OR ANYTHING OTHER THAN (2) OR (3)                       *
.*   2)  PLI                                                          *
.*   3)  ASMPLI                                                       *
.*                                                                    *
.* BASE= (DEFAULT IS 1)                                               *
.*   1)  STARTS WITH REG 12 AND WORKS DOWN                            *
.*   2)  STARTS WITH REG 11 AND WORKS DOWN                            *
.*   3)  STARTS WITH REG 11 AND WORKS DOWN                            *
.*                                                                    *
.**********************************************************************
         LCLA  &A,&B,&C,&BSNUM,&CNT,&BSPREV
         LCLC  &NAME,&BS
         AIF   (&BASE LE 9).BASEOK
         MNOTE 8,'TOO MANY BASE REGISTERS SPECIFIED'
         MEXIT
.BASEOK  ANOP
&A       SETA  K'&LBL
&C       SETA  &A
&NAME    SETC  '&LBL'
         AIF   ('&TYPE' EQ 'PLI').PLI
         AIF   ('&TYPE' EQ 'ASMPLI').ASMPLI
         AIF   (&A/2*2 NE &A).ALIGNED
&NAME    SETC  '&NAME'.' '
&C       SETA  &A+1
.ALIGNED ANOP
&B       SETA  ((&C+2)/2)*2+4
&LBL     CSECT
         B     &B.(0,15)       BRANCH AROUND PROGRAM ID
         DC    AL1(&A)         ..
         DC    CL&C'&NAME'     ..
         STM   14,12,12(13)    SAVE REGISTERS FOR CALLER
         BALR  12,0            GET BASE ADDRESS
         AIF   (&BASE LE 1).BASED
&CNT     SETA  1
&BSNUM   SETA  11
.ANOTHER ANOP
&BS      SETC  '&BS'.',&BSNUM'
&BSNUM   SETA  &BSNUM-1
&CNT     SETA  &CNT+1
         AIF   (&CNT LT &BASE).ANOTHER
.BASED   ANOP
         USING *,12&BS         IDENTIFY BASE ADDRESS
         AIF   (&BASE LE 1).FIN
&CNT     SETA  1
&BSNUM   SETA  11
&BSPREV  SETA  12
.LANOTH  ANOP
         LA    &BSNUM,4095
         LA    &BSNUM,1(&BSNUM,&BSPREV)
&BSNUM   SETA  &BSNUM-1
&BSPREV  SETA  &BSPREV-1
&CNT     SETA  &CNT+1
         AIF   (&CNT LT &BASE).LANOTH
.FIN     ANOP
         LR    2,1             SAVE PARAMETER LIST POINTER
         GETMAIN R,LV=80       GETMAIN SAVE AREA
         ST    13,4(1)         CHAIN SAVE AREAS
         ST    1,8(13)         ..
         LR    13,1            POINT TO NEW SAVE AREA
         LR    1,2             RESTORE PARAMETER ADDR LIST POINTER
         MEXIT
.PLI     ANOP
         AIF   (&A/2*2 NE &A).ALIGNEDP
&NAME    SETC  ' &NAME'
&C       SETA  &A+1
.ALIGNEDP ANOP
&B       SETA  ((&C+2)/2)*2+4
&CSECT   CSECT
         ENTRY &LBL            PROGRAM IDENTIFIER
         DC    CL&C'&NAME'     ..
         DC    AL1(&A)         ..
&LBL     STM   14,11,12(13)    STORE REGISTERS
         BALR  11,0            GET BASE ADDRESS
         AIF   (&BASE LE 1).BASEDP
&CNT     SETA  1
&BSNUM   SETA  10
.ANOTHERP ANOP
&BS      SETC  '&BS'.',&BSNUM'
&BSNUM   SETA  &BSNUM-1
&CNT     SETA  &CNT+1
         AIF   (&CNT LT &BASE).ANOTHERP
.BASEDP  ANOP
         USING *,11&BS         IDENTIFY BASE ADDRESS
         AIF   (&BASE LE 1).FINP
&CNT     SETA  1
&BSNUM   SETA  10
&BSPREV  SETA  11
.LANOTHP ANOP
         LA    &BSNUM,4095
         LA    &BSNUM,1(&BSNUM,&BSPREV)
&BSNUM   SETA  &BSNUM-1
&BSPREV  SETA  &BSPREV-1
&CNT     SETA  &CNT+1
         AIF   (&CNT LT &BASE).LANOTHP
.FINP    ANOP
         LR    2,1             SAVE PARAMETER LIST POINTER
         GETMAIN R,LV=80       GETMAIN SAVE AREA
         ST    13,4(1)         CHAIN SAVE AREAS
         ST    1,8(13)         ..
         LR    13,1            POINT TO NEW SAVE AREA
         LR    1,2             RESTORE PARAMETER ADDR LIST POINTER
         MEXIT
.ASMPLI  ANOP
         ENTRY PLIMAIN
PLIMAIN  DC    A(&LBL)
         AIF   (&A/2*2 NE &A).ALIGNEDA
&NAME    SETC  ' &NAME'
&C       SETA  &A+1
.ALIGNEDA ANOP
&B       SETA  ((&C+2)/2)*2+4
&CSECT   CSECT
         DC    CL&C'&NAME'     PROGRAM IDENTIFIER
         DC    AL1(&A)         ..
&LBL     STM   14,12,12(13)    STORE REGISTERS
         BALR  11,0            GET BASE ADDRESS
         AIF   (&BASE LE 1).BASEDA
&CNT     SETA  1
&BSNUM   SETA  10
.ANOTHERA ANOP
&BS      SETC  '&BS'.',&BSNUM'
&BSNUM   SETA  &BSNUM-1
&CNT     SETA  &CNT+1
         AIF   (&CNT LT &BASE).ANOTHERA
.BASEDA  ANOP
         USING *,11&BS         IDENTIFY BASE ADDRESS
         AIF   (&BASE LE 1).FINA
&CNT     SETA  1
&BSNUM   SETA  10
&BSPREV  SETA  11
.LANOTHA ANOP
         LA    &BSNUM,4095
         LA    &BSNUM,1(&BSNUM,&BSPREV)
&BSNUM   SETA  &BSNUM-1
&BSPREV  SETA  &BSPREV-1
&CNT     SETA  &CNT+1
         AIF   (&CNT LT &BASE).LANOTHA
.FINA    ANOP
         LR    2,1             SAVE PARAMETER LIST POINTER
         GETMAIN R,LV=80       GETMAIN SAVE AREA
         ST    13,4(1)         CHAIN SAVE AREAS
         ST    1,8(13)         ..
         MVC   72(8,1),72(13)  COPY PL/I SLOTS
         LR    13,1            POINT TO NEW SAVE AREA
         LR    1,2             RESTORE PARAMETER ADDR LIST POINTER
         MEND
