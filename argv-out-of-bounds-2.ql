/**
 * @name Argv index out-of-bounds-2
 * @ kind problem
 * @id cpp/example/argv-out-of-bounds-2
 */

import cpp
import semmle.code.cpp.controlflow.SSA

//
//    Use https://codeql.github.com/docs/codeql-language-guides/codeql-library-for-cpp/
//    to find the codeql class matching c++ syntax
//
//    See https://codeql.github.com/docs/codeql-language-guides/using-range-analsis-in-cpp/
//    for the entry points to the range analysis library.  Namely,
//    `import semmle.code.cpp.rangeanalysis.SimpleRangeAnalysis`
//    and
//    `lowerBound(expr)`
//
//    There is a short example of SSA use at
//    https://codeql.github.com/docs/codeql-language-guides/detecting-a-potential-buffer-overflow/#improving-the-query-using-the-ssa-library
//

from
  Parameter argc, RelationalOperation cmp, Variable n, Parameter argv, ArrayExpr argvAccess,
  AssignExpr argvSet, SsaDefinition invalidN, SsaDefinition invalidNDef
where
  //
  //     consider argc and n when they occur in the same comparison
  //
  argc.getName() = "argc" and
  argc.getAnAccess() = cmp.getAnOperand().getAChild*() and
  n.getAnAccess() = cmp.getAnOperand().getAChild*() and
  not n instanceof Parameter and
  //
  //    find indexed reads of argv using n
  //
  argvAccess.getArrayBase() = argv.getAnAccess() and
  argvAccess.getArrayOffset() = n.getAnAccess() and
  //
  //   find the indexed writes of argv
  //
  exists(ArrayExpr aa |
    aa.getArrayBase() = argv.getAnAccess() and
    aa.getArrayOffset() = n.getAnAccess() and
    argvSet.getLValue() = aa and
    /*  Separate the read */
    aa != argvAccess
  ) and
  //
  //   Ignore argv use when it's an argument of strcmp
  //
  not exists(FunctionCall strcmp |
    strcmp.getTarget().getName() = "strcmp" and
    strcmp.getAnArgument*() = argvAccess
  ) and
  //
  //      To track only values of the argv index that are too high, we need to
  //      stay on branches of the CFG matching a SSA definition of the index
  //      variable with known high value.
  //
  cmp.getLesserOperand() = invalidN.getAUse(n) and
  cmp.getGreaterOperand() = argc.getAnAccess() and
  invalidNDef = invalidN.getAnUltimateSsaDefinition(n) and
  invalidNDef.getDefiningValue(n).getValue().toInt() > 0 and
  //
  //     We still find an access inside the loop,
  //        opt_user = g_strdup (argv[n]);
  //     so let's narrow to branches outside the loop.
  // 
  invalidN.getAUse(n) = argvAccess.getArrayOffset() and
  argvSet = cmp.getAFalseSuccessor().getASuccessor*() and
  argvAccess = cmp.getAFalseSuccessor().getASuccessor*()
  
select argc, cmp, n, argvAccess, argvSet, invalidNDef, invalidN
