/PROG  GRI_TRIGGER_JOB_SYNC      Macro
/ATTR
OWNER		= MNEDITOR;
COMMENT		= "Get pose from GRI job";
PROG_SIZE	= 800;
CREATE		= DATE 25-01-07  TIME 18:00:00;
MODIFIED	= DATE 25-01-07  TIME 22:30:00;
FILE_NAME	= ;
VERSION		= 0;
LINE_COUNT	= 23;
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
   1:  !GRI Get Pose - Robot Programmer Interface ;
   2:  !Parameter: AR[1] = Job ID ;
   3:  !Check if background ready ;
   4:  IF R[149:gri comm bit]<>0,JMP LBL[99] ;
   5:  !Send sync job request ;
   6:  R[142:gri param 0]=AR[1]    ;
   7:  R[143:gri param 1]=0    ;
   8:  R[144:gri param 2]=0    ;
   9:  R[141:gri command]=2    ;
  10:  !Wait for command processing ;
  11:  WAIT R[141:gri command]=(-1)    ;
  12:  WAIT R[148:gri processing]=0    ;
  13:  !Check result using uniform mapping ;
  14:  IF R[150:gri error code]=0,JMP LBL[10] ;
  15:  MESSAGE[GRI error, see R150/R151] ;
  16:  JMP LBL[20] ;
  17:  LBL[10] ;
  18:  !Success: PR[53] pose valid; counts in R[152]/R[153] ;
  19:  LBL[20] ;
  20:  END ;
  21:  LBL[99] ;
  22:  !Communication not ready ;
  23:  R[150:gri error code]=23    ;
/POS
/END 