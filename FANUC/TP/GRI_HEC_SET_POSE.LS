/PROG  GRI_HEC_SET_POSE      Macro
/ATTR
OWNER		= MNEDITOR;
COMMENT		= "HEC Set Pose";
PROG_SIZE	= 800;
CREATE		= DATE 25-01-07  TIME 18:00:00;
MODIFIED	= DATE 25-01-07  TIME 22:30:00;
FILE_NAME	= ;
VERSION		= 0;
LINE_COUNT	= 26;
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
   1:  !GRI HEC Set Pose - Robot Programmer Interface ;
   2:  !Parameter: AR[1] = Pipeline ID ;
   3:  !Parameter: AR[2] = Slot Number ;
   4:  !Check if background ready ;
   5:  IF R[149:gri comm bit]<>0,JMP LBL[99] ;
   6:  !Current robot pose captured automatically by KAREL ;
   7:  !Send HEC set pose request ;
   8:  R[142:param0]=AR[1]    ;
   9:  R[143:param1]=AR[2]    ;
  10:  R[144:param2]=0    ;
  11:  R[141:gri_command]=8    ;
  12:  !Wait for command processing ;
  13:  WAIT R[141:gri_command]=(-1)    ;
  14:  WAIT R[148:gri processing]=0    ;
  15:  !Check result using uniform mapping ;
  16:  IF R[150:gri error code]=0,JMP LBL[10] ;
  17:  MESSAGE[GRI error, see R150/R151] ;
  18:  JMP LBL[20] ;
  19:  LBL[10] ;
  20:  !Pose set successfully ;
  21:  LBL[20] ;
  22:  END ;
  23:  LBL[99] ;
  24:  !Communication not ready ;
  25:  R[150:gri error code]=23    ;
  26:  MESSAGE[HEC Comm Not Ready] ;
/POS
/END 