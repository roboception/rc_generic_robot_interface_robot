/PROG  GRI_GET_JOB_STATUS      Macro
/ATTR
OWNER		= MNEDITOR;
COMMENT		= "Get job status";
PROG_SIZE	= 800;
CREATE		= DATE 25-01-07  TIME 18:00:00;
MODIFIED	= DATE 25-01-07  TIME 22:30:00;
FILE_NAME	= ;
VERSION		= 0;
LINE_COUNT	= 24;
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
   1:  !GRI Get Job Status - Robot Programmer Interface ;
   2:  !Parameter: AR[1] = Job ID ;
   3:  !Returns: R[150] = job status ;
   4:  !Check if background ready ;
   5:  IF R[149:gri comm bit]<>0,JMP LBL[99] ;
   6:  !Send get status request ;
   7:  R[142:gri param 0]=AR[1]    ;
   8:  R[143:gri param 1]=0    ;
   9:  R[144:gri param 2]=0    ;
  10:  R[141:gri command]=4    ;
  11:  !Wait for command processing ;
  12:  WAIT R[141:gri command]=(-1)    ;
  13:  WAIT R[148:gri processing]=0    ;
  14:  !Check result using uniform mapping ;
  15:  IF R[150:gri error code]=0,JMP LBL[10] ;
  16:  MESSAGE[GRI error, see R150/R151] ;
  17:  JMP LBL[20] ;
  18:  LBL[10] ;
  19:  !Success: job status in R[152] (1..4) ;
  20:  LBL[20] ;
  21:  END ;
  22:  LBL[99] ;
  23:  !Communication not ready ;
  24:  MESSAGE[GRI comm not ready] ;
/POS
/END 