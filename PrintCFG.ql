/**
 * @name Print part of the CFG
 * @description Outputs a subset of the control flow graph
 * @id cpp/example/polkit/cfg
 * @kind graph
 */

import cpp

query predicate edges(ControlFlowNode n1, ControlFlowNode n2) {
  n1.getASuccessor() = n2 and
  n1.getControlFlowScope().getName() = "main" and
  // polkit has many `main` functions, grab the one from pkexec.c
  n1.getLocation().getFile().getBaseName() = "pkexec.c"
}

query predicate nodes(ControlFlowNode n1, string key, string value) {
  exists(
    RelationalOperation cmp, Parameter argc, ControlFlowNode startFrom, Variable n, ForStmt forloop
  |
    // Find the comparison
    argc.getName() = "argc" and
    argc.getAnAccess() = cmp.getAnOperand().getAChild*() and
    n.getAnAccess() = cmp.getAnOperand().getAChild*() and
    not n instanceof Parameter and
    n.getName() = "n" and
    forloop.getCondition() = cmp and
    forloop.getControlFlowScope().getName() = "main" and
    // Find the false branch's starting node
    startFrom = cmp.getAFalseSuccessor() and
    //
    (edges(n1, _) or edges(_, n1)) and
    (
      if startFrom.getASuccessor*() = n1
      then (
        key = "color" and value = "red"
        or
        key = "line" and value = n1.getLocation().getStartLine().toString()
      ) else (
        key = "color" and value = "black"
        or
        key = "line" and value = n1.getLocation().getStartLine().toString()
      )
    )
  )
}
// For reference, see the file
//     db/polkit-0.119.db/tmp/polkit/src/programs/pkexec.c
// (after extracting src.zip)
