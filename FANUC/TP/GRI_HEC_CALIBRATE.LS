/PROG  GRI_HEC_CALIBRATE      Macro
/ATTR
OWNER		= MNEDITOR;
COMMENT		= "HEC Calibrate";
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
   1:  !GRI HEC Calibrate - Robot Programmer Interface ;
   2:  !Parameter: AR[1] = Pipeline ID ;
   3:  !Check if background ready ;
   4:  IF R[149:gri comm bit]<>0,JMP LBL[99] ;
   5:  !Send HEC calibrate request ;
   6:  R[142:param0]=AR[1]    ;
   7:  R[143:param1]=0    ;
   8:  R[144:param2]=0    ;
   9:  R[141:gri_command]=9    ;
  10:  !Wait for command processing ;
  11:  WAIT R[141:gri_command]=(-1)    ;
  12:  WAIT R[148:gri processing]=0    ;
  13:  !Check result using uniform mapping ;
  14:  IF R[150:gri error code]=0,JMP LBL[20] ;
  15:  MESSAGE[GRI error, see R150/R151] ;
  16:  JMP LBL[20] ;
  17:  LBL[20] ;
  18:  MESSAGE[HEC OK] ;
  19:  END ;
  20:  LBL[99] ;
  21:  !Communication not ready ;
  22:  R[150:gri error code]=23    ;
  23:  MESSAGE[HEC Comm Not Ready] ;
/POS
/END 