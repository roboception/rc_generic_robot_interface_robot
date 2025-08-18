/PROG  GRI_EXAMPLE_PICK_AND_PLACE	  Macro
/ATTR
OWNER		= MNEDITOR;
COMMENT		= "GRI PickNPlace Example";
PROG_SIZE	= 1851;
CREATE		= DATE 25-07-11  TIME 11:03:38;
MODIFIED	= DATE 25-07-11  TIME 11:08:16;
FILE_NAME	= ;
VERSION		= 0;
LINE_COUNT	= 44;
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
LOCAL_REGISTERS	= 0,0,0;
/MN
   1:  MESSAGE[Starting pick-and-place cycle] ;
   2:  !--- Step 1: Go to home position ;
   3:J P[1] 100% CNT100    ;
   4:  MESSAGE[At home position] ;
   5:  !--- Step 2: Start GRI communicat ;
   6:  CALL GRI_OPEN_COMMUNICATION    ;
   7:  MESSAGE[GRI communication started] ;
   8:  !--- Step 3: Get grasp pose from ;
   9:  CALL GRI_TRIGGER_JOB_SYNC(42) ;
  10:  !Check if pose was found ;
  11:  IF R[150:gri obj status]=20,JMP LBL[20] ;
  12:  MESSAGE[No pose available - aborting] ;
  13:  JMP LBL[99] ;
  14:  LBL[20] ;
  15:  MESSAGE[Pose found - approach] ;
  16:  !--- Step 4: Calculate pre-grasp ;
  17:  PR[54:pre_grasp]=PR[53:gri move pose]    ;
  18:  PR[54,3:pre_grasp]=PR[54,3:pre_grasp]+100    ;
  19:  MESSAGE[Pre-grasp position calculated] ;
  20:  !--- Step 5: Move to pre-grasp po ;
  21:J PR[54:pre_grasp] 100% CNT100    ;
  22:  MESSAGE[At pre-grasp position] ;
  23:  !--- Step 6: Linear move to grasp ;
  24:L PR[53:gri move pose] 20mm/sec FINE    ;
  25:  MESSAGE[At grasp position] ;
  26:  !Close gripper here (add your gri ;
  27:  WAIT    2.50(sec) ;
  28:  !--- Step 7: Linear move back to ;
  29:L PR[54:pre_grasp] 20mm/sec FINE    ;
  30:  MESSAGE[Back at pre-grasp with part] ;
  31:  !--- Step 8: Move to place positi ;
  32:J P[2] 10% FINE    ;
  33:  MESSAGE[At place position] ;
  34:  !--- Step 9: Place the part --- ;
  35:  !Open gripper here (add your grip ;
  36:  WAIT    2.50(sec) ;
  37:  MESSAGE[Part placed] ;
  38:  !--- Step 10: Return to home --- ;
  39:J P[1] 10% CNT100    ;
  40:  MESSAGE[Cycle complete - back at home] ;
  41:  LBL[99] ;
  42:  !--- Final: Close GRI communicati ;
  43:  CALL GRI_QUIT    ;
  44:  MESSAGE[Pick-and-place cycle finished] ;
/POS
P[1]{
    GP1:
    UF : 0, UT : 1,		CONFIG : 'F D T, 0, 1',
    X =     0.000  mm,	Y =     0.000  mm,	Z =     0.000  mm,
    W =     0.000 deg,	P =     0.000 deg,	R =     0.000 deg
};
P[2]{
   GP1:
	UF : 0, UT : 1,		CONFIG : 'F D T, 0, 1',
	X =     0.000  mm,	Y =     0.000  mm,	Z =     0.000  mm,
	W =     0.000 deg,	P =     0.000 deg,	R =     0.000 deg
};
/END
