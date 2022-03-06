/**
 * @name Print part of the CFG
 * @description Outputs a subset of the control flow graph
 * @id cpp/example/polkit/cfg-false-successor
 * @kind graph
 */

import cpp

query predicate edges(ControlFlowNode n1, ControlFlowNode n2) {
  exists(
    RelationalOperation cmp, Parameter argc, ControlFlowNode startFrom, Variable n, ForStmt forloop
  |
    // minimal restriction: start from comparison
    argc.getName() = "argc" and
    argc.getAnAccess() = cmp.getAnOperand().getAChild*() and
    n.getAnAccess() = cmp.getAnOperand().getAChild*() and
    not n instanceof Parameter and
    n.getName() = "n" and
    forloop.getCondition() = cmp and
    forloop.getControlFlowScope().getName() = "main" and
    //
    startFrom = cmp.getAFalseSuccessor() and
    startFrom.getASuccessor*() = n1 and
    //
    n1.getASuccessor() = n2 and
    n1.getControlFlowScope().getName() = "main" and
    // polkit has many `main` functions, grab the one from pkexec.c
    n1.getLocation().getFile().getBaseName() = "pkexec.c"
  )
}
// For reference, see the file
//     db/polkit-0.119.db/tmp/polkit/src/programs/pkexec.c
// (after extracting src.zip)
