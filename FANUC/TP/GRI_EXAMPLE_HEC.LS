/PROG  GRI_EXAMPLE_HEC	  Macro
/ATTR
OWNER		= MNEDITOR;
COMMENT		= "HEC Example";
PROG_SIZE	= 2532;
CREATE		= DATE 25-07-10  TIME 18:05:34;
MODIFIED	= DATE 25-07-10  TIME 18:05:56;
FILE_NAME	= AAAGRIHE;
VERSION		= 0;
LINE_COUNT	= 62;
MEMORY_SIZE	= 3036;
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
   1:  !================================ ;
   2:  ! GRI HEC EXAMPLE ;
   3:  ! 8-Pose Calibration ;
   4:  !================================ ;
   5:  !--- INSTRUCTIONS FOR ROBOT PROGR ;
   6:  MESSAGE[HEC 8-Pose Calibration] ;
   7:  MESSAGE[Use TOUCHUP on P[1] to P[8]] ;
   8:  PAUSE ;
   9:  !--- START CALIBRATION PROCESS -- ;
  10:  MESSAGE[Starting HEC Calibration] ;
  11:  ! Standardize frames: UF:0 (world), UT:0 (flange)
  12:  CALL GRI_SETFRAMES ;
  13:  !--- Open Communication --- ;
  14:  CALL GRI_OPEN_COMMUNICATION    ;
  15:  MESSAGE[Communication ready] ;
  16:  !--- Initialize HEC Pipeline 0 -- ;
  17:  MESSAGE[Init HEC Pipeline 0] ;
  18:  CALL GRI_HEC_INIT(0) ;
  19:  WAIT R[141:gri_command]=(-1)    ;
  20:  WAIT    .20(sec) ;
  21:  MESSAGE[HEC Pipeline ready] ;
  22:  !--- CALIBRATION POSES 1-8 --- ;
  23:  MESSAGE[Move to Pose 1] ;
  24:J P[1] 100% FINE    ;
  25:  WAIT   2.00(sec) ;
  26:  CALL GRI_HEC_SET_POSE(0,1) ;
  27:  MESSAGE[Move to Pose 2] ;
  28:J P[2] 100% FINE    ;
  29:  WAIT   2.00(sec) ;
  30:  CALL GRI_HEC_SET_POSE(0,2) ;
  31:  MESSAGE[Move to Pose 3] ;
  32:J P[3] 100% FINE    ;
  33:  WAIT   2.00(sec) ;
  34:  CALL GRI_HEC_SET_POSE(0,3) ;
  35:  MESSAGE[Move to Pose 4] ;
  36:J P[4] 100% FINE    ;
  37:  WAIT   2.00(sec) ;
  38:  CALL GRI_HEC_SET_POSE(0,4) ;
  39:  MESSAGE[Move to Pose 5] ;
  40:J P[5] 100% FINE    ;
  41:  WAIT   2.00(sec) ;
  42:  CALL GRI_HEC_SET_POSE(0,5) ;
  43:  MESSAGE[Move to Pose 6] ;
  44:J P[6] 100% FINE    ;
  45:  WAIT   2.00(sec) ;
  46:  CALL GRI_HEC_SET_POSE(0,6) ;
  47:  MESSAGE[Move to Pose 7] ;
  48:J P[7] 100% FINE    ;
  49:  WAIT   2.00(sec) ;
  50:  CALL GRI_HEC_SET_POSE(0,7) ;
  51:  MESSAGE[Move to Pose 8] ;
  52:J P[8] 100% FINE    ;
  53:  WAIT   2.00(sec) ;
  54:  CALL GRI_HEC_SET_POSE(0,8) ;
  55:  !--- PERFORM CALIBRATION --- ;
  56:  MESSAGE[All poses set] ;
  57:  MESSAGE[Calibrating...] ;
  58:  CALL GRI_HEC_CALIBRATE(0) ;
  59:  MESSAGE[HEC Complete] ;
  60:  LBL[99] ;
  61:  !--- CLEANUP --- ;
  62:  CALL GRI_QUIT    ;
/END
