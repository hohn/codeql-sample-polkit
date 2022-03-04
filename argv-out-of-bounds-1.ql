/**
 * @name Argv index out-of-bounds-1
 * @ kind problem
 * @id cpp/example/argv-out-of-bounds-1
 */

import cpp
import semmle.code.cpp.rangeanalysis.SimpleRangeAnalysis
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
  //   ignore argv use when it's an argument of strcmp
  //
  not exists(FunctionCall strcmp |
    strcmp.getTarget().getName() = "strcmp" and
    strcmp.getAnArgument*() = argvAccess
  ) and
  // // ----------------------
  // //
  // //     The first thing to try is the range library via these predicates:
  // select argc, "definition of argc", cmp, "use in comparison", n, "other var in comparison",
  //   argvAccess, "argv indexed", argvSet, "argv assigned",
  //   , lowerBound(cmp.getLeftOperand()), "left lower bound"
  //   , lowerBound(cmp.getRightOperand()), "right lower bound"
  // // ----------------------
  // //
  // //     Both bounds are 0, which is somewhat surprising.  The reason is that
  // //     results include possible increments from loop; with overflow and cast,
  // //     this makes 0 the minimum.
  // //     These are correct bounds for the types, but too general -- they include the possible results
  // //     of iteration.  We are only interested in initial bounds that are statically determinate,
  // //     those before any iteration happens.
  // //     Just to check:
  // select argc, "definition of argc", cmp, "use in comparison", n, "other var in comparison",
  //   argvAccess, "argv indexed", argvSet, "argv assigned",
  //   lowerBound(cmp.getLeftOperand().getFullyConverted()),  "left lower bound",
  //   lowerBound(cmp.getRightOperand().getFullyConverted()), "right lower bound"
  // ----------------------
  //
  //      Step back from the general range library and note a few details about this
  //      problem:
  //      - The range of argc is set by the OS, so it's known at compile time
  //      - The first value of n is set in the code, it's also statically determined
  //      - We are concerned about the lowest possible value of the argv index, no other
  //
  //      We can rephrase the problem:
  //
  //      Find an execution path (if any), using statically known values, that reaches
  //      an argv assignment with invalid index.
  //
  //      To track only values of the argv index that are too low, we need to stay on
  //      certain branches of the CFG, namely those matching a SSA defition of the
  //      index variable.
  //
  //      A first attempt, starting from `cmp` is the following.  This finds two
  //      invalidNDef locations, n++ and n = 1, and several `argvAccess`s
  cmp.getLesserOperand() = invalidN.getAUse(n) and
  cmp.getGreaterOperand() = argc.getAnAccess() and
  invalidN.getAnUltimateDefiningValue(n).getValue().toInt() > 0 and
  invalidNDef = invalidN.getAnUltimateSsaDefinition(n) and
  //
  //     We still find an access inside the loop,
  //        opt_user = g_strdup (argv[n]);
  //     so let's narrow:
  invalidN.getAUse(n) = argvAccess.getArrayOffset() and
  argvSet = cmp.getAFalseSuccessor().getASuccessor*() and
  argvAccess = cmp.getAFalseSuccessor().getASuccessor*() and
  // 
  //    Reduce to a single invalidNDef location, the n = 1 case.
  // // 
  // //     Try one; still get `n = 1` and `n++`
  // and  exists( Expr t| t =  invalidNDef.getDefiningValue(n))
  //
  //    Try two, require an explicit value:
  exists(string t | t = invalidNDef.getDefiningValue(n).getValue())
  // 
  //    This works!  Some clean up/simplification, to be used in the next iteration.
  and
  invalidNDef = invalidN.getAnUltimateSsaDefinition(n) and 
  invalidNDef.getDefiningValue(n).getValue().toInt() > 0
  
select argc, "definition of argc", cmp, "use in comparison", n, "other var in comparison",
  argvAccess, "argv indexed", argvSet, "argv assigned", invalidNDef, "invalid n definition"
  
