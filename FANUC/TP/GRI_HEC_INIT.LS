/PROG  GRI_HEC_INIT      Macro
/ATTR
OWNER		= MNEDITOR;
COMMENT		= "HEC Initialize";
PROG_SIZE	= 800;
CREATE		= DATE 25-01-07  TIME 18:00:00;
MODIFIED	= DATE 25-01-07  TIME 22:30:00;
FILE_NAME	= ;
VERSION		= 0;
LINE_COUNT	= 22;
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
   1:  !GRI HEC Initialize - Robot Programmer Interface ;
   2:  !Parameter: AR[1] = Pipeline ID ;
   3:  !Check if background ready ;
   4:  IF R[149:gri comm bit]<>0,JMP LBL[99] ;
   5:  !Send HEC init request ;
   6:  R[142:gri param 0]=AR[1]    ;
   7:  WAIT R[149:gri comm status]=0    ;
   8:  R[141:gri_command]=7    ;
   9:  WAIT R[151:gri status]<>99    ;
  10:  WAIT R[141:gri_command]=(-1)    ;
  11:  !Check if command succeeded ;
  12:  IF R[151:gri_status]=0,JMP LBL[17] ;
  13:  !Command failed - set error status ;
  14:  R[150:gri obj status]=23    ;
  15:  END ;
  16:  LBL[17] ;
  17:  !Command succeeded - HEC initialized ;
  18:  R[150:gri obj status]=1    ;
  19:  END ;
  20:  LBL[99] ;
  21:  !Communication not ready ;
  22:  R[150:gri obj status]=23    ;
/POS
/END 