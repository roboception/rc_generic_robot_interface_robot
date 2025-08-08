/PROG  GRI_OPEN_COMMUNICATION	  Macro
/ATTR
OWNER		= MNEDITOR;
COMMENT		= "Start GRI communication system";
PROG_SIZE	= 600;
CREATE		= DATE 25-01-07  TIME 18:00:00;
MODIFIED	= DATE 25-01-07  TIME 18:00:00;
FILE_NAME	= ;
VERSION		= 0;
LINE_COUNT	= 36;
MEMORY_SIZE	= 1200;
PROTECT		= READ_WRITE;
TCD:  STACK_SIZE	= 0,
      TASK_PRIORITY	= 50,
      TIME_SLICE	= 0,
      BUSY_LAMP_OFF	= 0,
      ABORT_REQUEST	= 0,
      PAUSE_REQUEST	= 0;
DEFAULT_GROUP	= 1,*,*,*,*;
CONTROL_CODE	= 00000000 00000000;
/MN
   1:  !GRI Open Communication - Simplified ;
   2:  !Set comm handshake bit ;
   3:  R[149:gri comm bit]=(-1)    ;
   4:  WAIT   1.00(sec) ;
   5:  !Check if comm bit has been reset ;
   6:  IF R[149:gri comm bit]<>0,JMP LBL[1] ;
   7:  END ;
   8:  LBL[1] ;
   9:  !Start GRI communication ;
  10:  RUN GRI_COMM_BACKGROUND ;
  11:  !Wait for communication ready ;
  12:  R[200:timeout]=0    ;
  13:  LBL[2] ;
  14:  IF R[149:gri comm bit]=0,JMP LBL[3] ;
  15:  R[200:timeout]=R[200:timeout]+1    ;
  16:  !Wait 3 seconds before checking for errors ;
  17:  IF R[200:timeout]<30,JMP LBL[4] ;
  18:  IF R[149:gri comm bit]=(-1),JMP LBL[5] ;
  19:  LBL[4] ;
  20:  IF R[200:timeout]>100,JMP LBL[6] ;
  21:  WAIT    .10(sec) ;
  22:  JMP LBL[2] ;
  23:  LBL[3] ;
  24:  !Communication ready ;
  25:  MESSAGE[GRI Communication Started!] ;
  26:  JMP LBL[7] ;
  27:  LBL[5] ;
  28:  !Communication failed ;
  29:  MESSAGE[GRI Communication Failed] ;
  30:  MESSAGE[Check socket C2 configuration] ;
  31:  JMP LBL[7] ;
  32:  LBL[6] ;
  33:  !Communication timeout ;
  34:  MESSAGE[GRI Communication Timeout] ;
  35:  MESSAGE[Background program failed] ;
  36:  LBL[7] ;
/POS
/END 