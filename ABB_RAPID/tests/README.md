# GRI edge-case tests (ABB RAPID)
GriEdgeCases.modx runs edge cases of the GRI client against a live rc_cube (jobs 0, 1, 2 configured).
Load it next to the RcGenericRobotInterface modules: add <Module>GriEdgeCases.modx</Module> to the .pgf, or use Load Module.
Start it with PP to Routine > edge_tests, then run; each case prints PASS/FAIL on the FlexPendant / Operator Window.
It ends with a summary "N passed, M failed" and stops the program (EXIT).
