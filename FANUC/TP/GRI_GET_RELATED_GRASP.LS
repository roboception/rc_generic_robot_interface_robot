/PROG  GRI_GET_RELATED_GRASP      Macro
/ATTR
OWNER		= MNEDITOR;
COMMENT		= "Get related grasp pose";
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
   1:  !GRI Get Related Grasp - Robot Programmer Interface ;
   2:  !Parameter: AR[1] = Job ID ;
   3:  !Returns: PR[53] = pose, R[152] = rem primary, R[153] = rem related ;
   4:  !Check if background ready ;
   5:  IF R[149:gri comm bit]<>0,JMP LBL[99] ;
   6:  !Send get related grasp request ;
   7:  R[142:gri param 0]=AR[1]    ;
   8:  R[143:gri param 1]=0    ;
   9:  R[144:gri param 2]=0    ;
  10:  R[141:gri command]=6    ;
  11:  !Wait for command processing ;
  12:  WAIT R[141:gri command]=(-1)    ;
  13:  WAIT R[151:gri status]<>99    ;
  14:  !Check if command succeeded ;
  15:  IF R[151:gri status]=0,JMP LBL[17] ;
  16:  !Command failed - set error status ;
  17:  R[150:gri obj status]=23    ;
  18:  END ;
  19:  LBL[17] ;
  20:  !Command succeeded - result in R[150] ;
  21:  END ;
  22:  LBL[99] ;
  23:  !Communication not ready ;
  24:  R[150:gri obj status]=23    ;
/POS
/END 