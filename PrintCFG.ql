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

// For reference, see the file
//     db/polkit-0.119.db/tmp/polkit/src/programs/pkexec.c 
// (after extracting src.zip)
