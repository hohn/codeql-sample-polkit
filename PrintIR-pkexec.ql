/**
 * @name Print Aliased SSA IR
 * @description Outputs a representation of the Aliased SSA IR graph
 * @id cpp/example/polkit-ir
 * @kind graph
 */

// From PrintIR.qll:
//     ...  For most uses, however, it is better to write a query
//     that imports `PrintIR.qll`,
//     extends `PrintIRConfiguration`,
//     and overrides `shouldPrintFunction()` to select a subset of functions to dump.

import semmle.code.cpp.ir.PrintIR
import semmle.code.cpp.ir.internal.IRCppLanguage as Language

class PkexecMainConfig extends PrintIRConfiguration  {
  /** Gets a textual representation of this configuration. */
  override string toString() { result = "PkexecMainConfig" }

  /**
   * Holds if the IR for `func` should be printed. By default, holds for all
   * functions.
   */
  override predicate shouldPrintFunction(Language::Function func) { 
    func.getName() = "main" and 
    func.getLocation().getFile().getBaseName() = "pkexec.c"
  }
}
