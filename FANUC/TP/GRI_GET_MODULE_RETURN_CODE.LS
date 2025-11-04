/PROG GRI_GET_MODULE_RETURN_CODE
/ATTR
COMMENT = "Read module return (data_1) from R[151]";
/MN
  ! Module return code is provided by the GRI server in data_1
  ! Uniform mapping: R[151] = module return (data_1)
  ! Optional: notify if non-zero (warning/error from module)
  IF R[151:module return]<>0,JMP LBL[warn] ;
  JMP LBL[done] ;
  LBL[warn] ;
  MESSAGE[Non-zero module return in R151] ;
  LBL[done] ;
/END

