/PROG  GRI_HEC_SET_POSE      Macro
/ATTR
OWNER		= MNEDITOR;
COMMENT		= "HEC Set Pose";
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
   1:  !GRI HEC Set Pose - Robot Programmer Interface ;
   2:  !Parameter: AR[1] = Pipeline ID ;
   3:  !Parameter: AR[2] = Slot Number ;
   4:  !Check if background ready ;
   5:  IF R[149:gri comm bit]<>0,JMP LBL[99] ;
   6:  !Capture current robot pose automatically ;
   7:  PR[52:hec_pose]=LPOS    ;
   8:  !Send HEC set pose request ;
   9:  R[142:param0]=AR[1]    ;
  10:  R[143:param1]=AR[2]    ;
  11:  R[144:param2]=0    ;
  12:  R[141:gri_command]=8    ;
  13:  !Wait for command processing ;
  14:  WAIT R[141:gri_command]=(-1)    ;
  15:  WAIT R[151:gri_status]<>99    ;
  16:  !Check if command succeeded ;
  17:  IF R[151:gri_status]=0,JMP LBL[17] ;
  18:  !Command failed - set error status ;
  19:  R[150:gri obj status]=23    ;
  20:  END ;
  21:  LBL[17] ;
  22:  !Command succeeded - pose set ;
  23:  R[150:gri obj status]=1    ;
  24:  END ;
  25:  LBL[99] ;
  26:  !Communication not ready ;
  27:  R[150:gri obj status]=23    ;
  28:  MESSAGE[HEC Comm Not Ready] ;
/POS
/END 