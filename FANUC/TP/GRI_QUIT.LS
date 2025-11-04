/PROG  GRI_QUIT	  Macro
/ATTR
OWNER		= MNEDITOR;
COMMENT		= "Quit GRI background program";
PROG_SIZE	= 600;
CREATE		= DATE 25-01-07  TIME 18:00:00;
MODIFIED	= DATE 25-01-07  TIME 18:00:00;
FILE_NAME	= ;
VERSION		= 0;
LINE_COUNT	= 16;
MEMORY_SIZE	= 800;
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
   1:  !Quit GRI Background Program ;
   2:  MESSAGE[Sending Quit Command] ;
   3:  !Check if background running ;
   4:  IF R[149:gri comm bit]<>0,JMP LBL[99] ;
   5:  !Send quit command ;
   6:  R[142:param0]=0    ;
   7:  R[143:param1]=0    ;
   8:  R[144:param2]=0    ;
   9:  R[141:gri command]=99    ;
  10:  WAIT R[148:gri processing]=0    ;
  11:  MESSAGE[Background Program Stopped] ;
  12:  JMP LBL[100] ;
  13:  LBL[99] ;
  14:  MESSAGE[Background not running] ;
  15:  LBL[100] ;
  16:  MESSAGE[GRI Quit Complete] ;
/POS
/END 