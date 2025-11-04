/PROG  GRI_GET_NEXT_GRASP      Macro
/ATTR
OWNER		= MNEDITOR;
COMMENT		= "Get next grasp pose";
PROG_SIZE	= 800;
CREATE		= DATE 25-01-07  TIME 18:00:00;
MODIFIED	= DATE 25-01-07  TIME 22:30:00;
FILE_NAME	= ;
VERSION		= 0;
LINE_COUNT	= 28;
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
   1:  !GRI Get Next Grasp - Robot Programmer Interface ;
   2:  !Parameter: AR[1] = Job ID ;
   3:  !Returns: PR[53] = pose, R[152] = remaining ;
   4:  !Check if background ready ;
   5:  IF R[149:gri comm bit]<>0,JMP LBL[99] ;
   6:  !Send get next grasp request ;
   7:  R[142:gri param 0]=AR[1]    ;
   8:  R[143:gri param 1]=0    ;
   9:  R[144:gri param 2]=0    ;
  10:  R[141:gri command]=5    ;
  11:  !Wait for command processing ;
  12:  WAIT R[141:gri command]=(-1)    ;
  13:  WAIT R[148:gri processing]=0    ;
  14:  !Check result using uniform mapping ;
  15:  IF R[150:gri error code]=0,JMP LBL[10] ;
  16:  IF R[150:gri error code]=1,JMP LBL[20] ;
  17:  MESSAGE[GRI error, see R150/R151] ;
  18:  JMP LBL[30] ;
  19:  LBL[10] ;
  20:  !Success: PR[53] pose valid; counts in R[152]/R[153] ;
  21:  JMP LBL[30] ;
  22:  LBL[20] ;
  23:  MESSAGE[No poses available] ;
  24:  LBL[30] ;
  25:  END ;
  26:  LBL[99] ;
  27:  !Communication not ready ;
  28:  R[150:gri error code]=23    ;
/POS
/END 