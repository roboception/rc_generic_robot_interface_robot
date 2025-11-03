/PROG  GRI_EXAMPLE_ASYNC	  Macro
/ATTR
OWNER		= MNEDITOR;
COMMENT		= "Async job example";
PROG_SIZE	= 1400;
CREATE		= DATE 25-01-07  TIME 18:00:00;
MODIFIED	= DATE 25-01-07  TIME 18:00:00;
FILE_NAME	= ;
VERSION		= 0;
LINE_COUNT	= 34;
MEMORY_SIZE	= 2000;
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
   1:  !GRI Async Example - Trigger, poll status, fetch pose ;
   2:  MESSAGE[Starting GRI Async Example] ;
   3:  ! Standardize frames: UF:0 (world), UT:0 (flange)
   4:  CALL GRI_SETFRAMES ;
   5:  !--- Open Communication --- ;
   6:  CALL GRI_OPEN_COMMUNICATION ;
   7:  MESSAGE[GRI Communication Started] ;
   8:  ! Trigger async job with ID 1 ;
   9:  CALL GRI_TRIGGER_JOB_ASYNC(1) ;
  10:  IF R[150:gri error code]=0,JMP LBL[10] ;
  11:  MESSAGE[Async start failed] ;
  12:  JMP LBL[90] ;
  13:  LBL[10] ;
  14:  MESSAGE[Async started OK] ;
  15:  ! Poll job status until DONE ;
  16:  LBL[20] ;
  17:  CALL GRI_GET_JOB_STATUS(1) ;
  18:  IF R[150:gri error code]<>0,JMP LBL[90] ;
  19:  IF R[152:gri data 2]=2,JMP LBL[20] ;
  20:  IF R[152:gri data 2]=4,JMP LBL[90] ;
  21:  IF R[152:gri data 2]<>3,JMP LBL[20] ;
  22:  MESSAGE[Job DONE] ;
  23:  ! Fetch next pose ;
  24:  CALL GRI_GET_NEXT_GRASP(1) ;
  25:  IF R[150:gri error code]=0,JMP LBL[30] ;
  26:  MESSAGE[No pose available] ;
  27:  JMP LBL[90] ;
  28:  LBL[30] ;
  29:  MESSAGE[Pose received - PR[53]] ;
  30:  LBL[90] ;
  31:  CALL GRI_QUIT ;
  32:  MESSAGE[GRI Async Example Failed] ;
  33:  JMP LBL[100] ;
  34:  LBL[100] ;
/POS
/END

