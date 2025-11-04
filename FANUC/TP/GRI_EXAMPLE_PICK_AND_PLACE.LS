/PROG  GRI_EXAMPLE_PICK_AND_PLACE	  Macro
/ATTR
OWNER		= MNEDITOR;
COMMENT		= "GRI PickNPlace Example";
PROG_SIZE	= 1851;
CREATE		= DATE 25-07-11  TIME 11:03:38;
MODIFIED	= DATE 25-07-11  TIME 11:08:16;
FILE_NAME	= ;
VERSION		= 0;
LINE_COUNT	= 46;
MEMORY_SIZE	= 2327;
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
   1:  MESSAGE[Starting pick-and-place cycle] ;
   2:  !--- Step 1: Go to home position ;
   3:J P[1] 100% CNT100    ;
   4:  MESSAGE[At home position] ;
   5:  ! Standardize frames: UF:0 (world), UT:0 (flange)
   6:  CALL GRI_SETFRAMES ;
   7:  !--- Step 2: Start GRI communication ;
   8:  CALL GRI_OPEN_COMMUNICATION    ;
   9:  MESSAGE[GRI communication started] ;
  10:  !--- Step 3: Get grasp pose from ;
  11:  CALL GRI_TRIGGER_JOB_SYNC(42) ;
  12:  !Check if pose was found ;
  13:  IF R[150:gri error code]=0,JMP LBL[20] ;
  14:  MESSAGE[No pose available - aborting] ;
  15:  JMP LBL[99] ;
  16:  LBL[20] ;
  17:  MESSAGE[Pose found - approach] ;
  18:  !--- Step 4: Calculate pre-grasp ;
  19:  PR[54:pre_grasp]=PR[53:gri move pose]    ;
  20:  PR[54,3:pre_grasp]=PR[54,3:pre_grasp]+100    ;
  21:  MESSAGE[Pre-grasp position calculated] ;
  22:  !--- Step 5: Move to pre-grasp po ;
  23:J PR[54:pre_grasp] 100% CNT100    ;
  24:  MESSAGE[At pre-grasp position] ;
  25:  !--- Step 6: Linear move to grasp ;
  26:L PR[53:gri move pose] 20mm/sec FINE    ;
  27:  MESSAGE[At grasp position] ;
  28:  !Close gripper here ;
  29:  WAIT    2.50(sec) ;
  30:  !--- Step 7: Linear move back to ;
  31:L PR[54:pre_grasp] 20mm/sec FINE    ;
  32:  MESSAGE[Back at pre-grasp with part] ;
  33:  !--- Step 8: Move to place positi ;
  34:J P[2] 10% FINE    ;
  35:  MESSAGE[At place position] ;
  36:  !--- Step 9: Place the part --- ;
  37:  !Open gripper here ;
  38:  WAIT    2.50(sec) ;
  39:  MESSAGE[Part placed] ;
  40:  !--- Step 10: Return to home --- ;
  41:J P[1] 10% CNT100    ;
  42:  MESSAGE[Cycle complete - back at home] ;
  43:  LBL[99] ;
  44:  !--- Final: Close GRI communicati ;
  45:  CALL GRI_QUIT    ;
  46:  MESSAGE[Pick-and-place cycle finished] ;
/END
