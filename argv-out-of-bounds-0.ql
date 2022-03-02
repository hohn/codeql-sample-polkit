/**
 * @name Argv index out-of-bounds-0
 * @kind problem
 * @id cpp/example/argv-out-of-bounds-0
 */

import cpp

/*
 * This query's goal is to isolate the parts of the source relevant to the bug, namely
 *      declaration      | 435 main (int argc, char *argv[])
 *                      | 436 {
 *                      | ...
 *     init other var;  | 534   for (n = 1;
 *     compare to argc  |            n < (guint) argc;
 *     update other var |            n++)
 *                      | 535     {
 *                      | ...
 *                      | 568     }
 *                      | ...
 *     indexed read     | 610   path = g_strdup (argv[n]);
 *                      | ...
 *                      | 629   if (path[0] != '/')
 *                      | 630     {
 *                      | ...
 *                      | 632       s = g_find_program_in_path (path);
 *                      | ...
 *     indexed write    | 639       argv[n] = path = s;
 *                      | 640     }
 *
 * As reference, use
 * https://codeql.github.com/docs/codeql-language-guides/codeql-library-for-cpp/
 * to find the codeql class matching c++ syntax
 */

/* Too many results */
// from Parameter argc
// where argc.getName() = "argc"
// select argc, "Definition of argc"
//
/*
 * Include the comparison operation to narrow results.
 *   Still finds 12 results.
 */

// from Parameter argc, ComparisonOperation cmp
// where
//   argc.getName() = "argc" and
//   argc.getAnAccess() = cmp.getAnOperand().getAChild*()
// select argc, "Definition of argc", cmp, "use in comparison"
/*
 * Make sure there is another variable in the comparison.  Refer to it as `n`
 *   Note that a ql `Parameter` is also a `Variable`, so we look for non-parameters.
 *   This narrows the `alerts` to 2 results, but still leaves 8 `#select`s
 */

// from Parameter argc, ComparisonOperation cmp, Variable n
// where
//   argc.getName() = "argc" and
//   argc.getAnAccess() = cmp.getAnOperand().getAChild*() and
//   n.getAnAccess() = cmp.getAnOperand().getAChild*() and
//   not n instanceof Parameter
// select argc, "definition of argc", cmp, "use in comparison", n, "other var in comparison"
/*
 * Find `n`'s use as argv index.  This still results in two alerts (which are grouped
 * by definitions of `argc`), and actually increases the `#select`s.
 */

// from Parameter argc, ComparisonOperation cmp, Variable n, Parameter argv, ArrayExpr argvAccess
// where
//   argc.getName() = "argc" and
//   argc.getAnAccess() = cmp.getAnOperand().getAChild*() and
//   n.getAnAccess() = cmp.getAnOperand().getAChild*() and
//   not n instanceof Parameter and
//   argvAccess.getArrayBase() = argv.getAnAccess() and
//   argvAccess.getArrayOffset() = n.getAnAccess()
// select argc, "definition of argc", cmp, "use in comparison", n, "other var in comparison",
//   argvAccess, "argv indexed"
/*
 * Narrow further by requiring writes involving `argv[n]`.
 *
 * This finally narrows results to a single function and 14 `#select`s;
 * until now there was a chance we might find variants of the same problem,
 * but now it looks like there aren't any.
 *
 * Examining the `argvAccess` column, it's clear that most reads we don't
 * care about are in the form of `strcmp (argv[n], ...)`
 */

// from
//   Parameter argc, ComparisonOperation cmp, Variable n, Parameter argv, ArrayExpr argvAccess,
//   AssignExpr argvSet
// where
//   argc.getName() = "argc" and
//   argc.getAnAccess() = cmp.getAnOperand().getAChild*() and
//   n.getAnAccess() = cmp.getAnOperand().getAChild*() and
//   not n instanceof Parameter and
//   argvAccess.getArrayBase() = argv.getAnAccess() and
//   argvAccess.getArrayOffset() = n.getAnAccess() and
//   exists(ArrayExpr aa |
//     aa.getArrayBase() = argv.getAnAccess() and
//     aa.getArrayOffset() = n.getAnAccess() and
//     argvSet.getLValue() = aa and
//     /*  Separate the read */
//     aa != argvAccess
//   )
// select argc, "definition of argc", cmp, "use in comparison", n, "other var in comparison",
//   argvAccess, "argv indexed", argvSet, "argv assigned"
/*
 * Filter out the `strcmp(argv[n],...)  expressions.
 *
 * This only returns 4 results, specific enough for some range analysis work.
 */

from
  Parameter argc, ComparisonOperation cmp, Variable n, Parameter argv, ArrayExpr argvAccess,
  AssignExpr argvSet
where
  argc.getName() = "argc" and
  argc.getAnAccess() = cmp.getAnOperand().getAChild*() and
  n.getAnAccess() = cmp.getAnOperand().getAChild*() and
  not n instanceof Parameter and
  argvAccess.getArrayBase() = argv.getAnAccess() and
  argvAccess.getArrayOffset() = n.getAnAccess() and
  not exists(FunctionCall strcmp |
    strcmp.getTarget().getName() = "strcmp" and
    strcmp.getAnArgument*() = argvAccess
  ) and
  exists(ArrayExpr aa |
    aa.getArrayBase() = argv.getAnAccess() and
    aa.getArrayOffset() = n.getAnAccess() and
    argvSet.getLValue() = aa and
    /*  Separate the read */
    aa != argvAccess
  )
select argc, "definition of argc", cmp, "use in comparison", n, "other var in comparison",
  argvAccess, "argv indexed", argvSet, "argv assigned"
