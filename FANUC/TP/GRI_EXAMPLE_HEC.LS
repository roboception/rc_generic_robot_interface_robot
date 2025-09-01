/PROG  GRI_EXAMPLE_HEC	  Macro
/ATTR
OWNER		= MNEDITOR;
COMMENT		= "HEC Example";
PROG_SIZE	= 2532;
CREATE		= DATE 25-07-10  TIME 18:05:34;
MODIFIED	= DATE 25-07-10  TIME 18:05:56;
FILE_NAME	= AAAGRIHE;
VERSION		= 0;
LINE_COUNT	= 74;
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
   2:  ! GRI HAND-EYE CALIBRATION EXAMPL ;
   3:  ! 8-Pose Calibration for Maximum  ;
   4:  ! Uses direct positions with touc ;
   5:  !================================ ;
   6:   ;
   7:  !--- INSTRUCTIONS FOR ROBOT PROGR ;
   8:  MESSAGE[HEC 8-Pose Calibration] ;
   9:  MESSAGE[Use TOUCHUP on P[1] to P[8]] ;
  10:  PAUSE ;
  11:   ;
  12:  !--- START CALIBRATION PROCESS -- ;
  13:  MESSAGE[Starting HEC Calibration] ;
  14:   ;
  15:  !--- Open Communication --- ;
  16:  CALL GRI_OPEN_COMMUNICATION    ;
  17:  MESSAGE[Communication ready] ;
  18:   ;
  19:  !--- Initialize HEC Pipeline 0 -- ;
  20:  MESSAGE[Init HEC Pipeline 0] ;
  21:  CALL GRI_HEC_INIT(0) ;
  22:  WAIT R[141:gri_command]=(-1)    ;
  23:  WAIT    .20(sec) ;
  24:  MESSAGE[HEC Pipeline ready] ;
  25:   ;
  26:  !--- CALIBRATION POSES 1-8 --- ;
  27:  MESSAGE[Move to Pose 1] ;
  28:J P[1] 100% FINE    ;
  29:  WAIT   2.00(sec) ;
  30:  CALL GRI_HEC_SET_POSE(0,1) ;
  31:   ;
  32:  MESSAGE[Move to Pose 2] ;
  33:J P[2] 100% FINE    ;
  34:  WAIT   2.00(sec) ;
  35:  CALL GRI_HEC_SET_POSE(0,2) ;
  36:   ;
  37:  MESSAGE[Move to Pose 3] ;
  38:J P[3] 100% FINE    ;
  39:  WAIT   2.00(sec) ;
  40:  CALL GRI_HEC_SET_POSE(0,3) ;
  41:   ;
  42:  MESSAGE[Move to Pose 4] ;
  43:J P[4] 100% FINE    ;
  44:  WAIT   2.00(sec) ;
  45:  CALL GRI_HEC_SET_POSE(0,4) ;
  46:   ;
  47:  MESSAGE[Move to Pose 5] ;
  48:J P[5] 100% FINE    ;
  49:  WAIT   2.00(sec) ;
  50:  CALL GRI_HEC_SET_POSE(0,5) ;
  51:   ;
  52:  MESSAGE[Move to Pose 6] ;
  53:J P[6] 100% FINE    ;
  54:  WAIT   2.00(sec) ;
  55:  CALL GRI_HEC_SET_POSE(0,6) ;
  56:   ;
  57:  MESSAGE[Move to Pose 7] ;
  58:J P[7] 100% FINE    ;
  59:  WAIT   2.00(sec) ;
  60:  CALL GRI_HEC_SET_POSE(0,7) ;
  61:   ;
  62:  MESSAGE[Move to Pose 8] ;
  63:J P[8] 100% FINE    ;
  64:  WAIT   2.00(sec) ;
  65:  CALL GRI_HEC_SET_POSE(0,8) ;
  66:   ;
  67:  !--- PERFORM CALIBRATION --- ;
  68:  MESSAGE[All poses set] ;
  69:  MESSAGE[Calibrating...] ;
  70:  CALL GRI_HEC_CALIBRATE(0) ;
  71:  MESSAGE[HEC Complete] ;
  72:  LBL[99] ;
  73:  !--- CLEANUP --- ;
  74:  CALL GRI_QUIT    ;
/END
