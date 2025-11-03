/PROG  GRI_HEC_INIT      Macro
/ATTR
OWNER		= MNEDITOR;
COMMENT		= "HEC Initialize";
PROG_SIZE	= 800;
CREATE		= DATE 25-01-07  TIME 18:00:00;
MODIFIED	= DATE 25-01-07  TIME 22:30:00;
FILE_NAME	= ;
VERSION		= 0;
LINE_COUNT	= 20;
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
   7:  R[141:gri_command]=7    ;
   8:  WAIT R[141:gri_command]=(-1)    ;
   9:  WAIT R[148:gri processing]=0    ;
  10:  !Check result using uniform mapping ;
  11:  IF R[150:gri error code]=0,JMP LBL[10] ;
  12:  MESSAGE[GRI error, see R150/R151] ;
  13:  JMP LBL[20] ;
  14:  LBL[10] ;
  15:  !HEC initialized successfully ;
  16:  LBL[20] ;
  17:  END ;
  18:  LBL[99] ;
  19:  !Communication not ready ;
  20:  MESSAGE[GRI comm not ready] ;
/POS
/END 