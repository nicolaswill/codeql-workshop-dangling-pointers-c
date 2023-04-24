/**
 * @name Local variable goes out of scope
 * @description A local variable goes out of scope.
 * @kind problem
 */

import cpp

/**
 * Holds if `lv` goes out of scope at `cfn`.
 */
predicate goesOutOfScope(LocalVariable lv, ControlFlowNode cfn) { none() }

private newtype TInvalidReason =
  TUninitialized(DeclStmt ds, LocalVariable lv) { ds.getADeclaration() = lv } or
  TVariableOutOfScope(LocalVariable lv, ControlFlowNode cfn) { none() }

class InvalidReason extends TInvalidReason {
  string toString() {
    exists(DeclStmt ds, LocalVariable lv |
      none() and
      result = "variable " + lv.getName() + " is unitialized."
    )
    or
    exists(LocalVariable lv, ControlFlowNode cfn |
      none() and
      result = "variable " + lv.getName() + " went out of scope."
    )
  }
}

private newtype TPSetEntry =
  PSetInvalid(InvalidReason ir) { none() } or
  ReplaceThisWithTheOtherTwoTypes() { none() }

class PSetEntry extends TPSetEntry {
  string toString() { none() }
}

from PSetEntry pse, InvalidReason ir, LocalVariable lv, ControlFlowNode cfn
where
  pse = PSetInvalid(ir) and
  ir = TVariableOutOfScope(lv, cfn)
select cfn, "Variable $@ goes out of scope here.", lv, lv.getName()
