/**
 * @name Local variable goes out of scope
 * @description A local variable goes out of scope.
 */

 import cpp

 /**
  * Holds if `lv` goes out of scope at `cfn`.
  */
 predicate goesOutOfScope(LocalVariable lv, ControlFlowNode cfn) {
   exists(BlockStmt scope |
     scope = lv.getParentScope() and
     if exists(scope.getFollowingStmt()) then scope.getFollowingStmt() = cfn else cfn = scope
   )
 }
 
 private newtype TInvalidReason =
   TUninitialized(DeclStmt ds, LocalVariable lv) { ds.getADeclaration() = lv } or
   TVariableOutOfScope(LocalVariable lv, ControlFlowNode cfn) { goesOutOfScope(lv, cfn) }
 
 class InvalidReason extends TInvalidReason {
   string toString() {
     exists(DeclStmt ds, LocalVariable lv |
       this = TUninitialized(ds, lv) and
       result = "variable " + lv.getName() + " is uninitialized."
     )
     or
     exists(LocalVariable lv, ControlFlowNode cfn |
       this = TVariableOutOfScope(lv, cfn) and
       result = "variable " + lv.getName() + " went out of scope."
     )
   }
 }
 
 private newtype TPSetEntry =
   PSetVar(LocalVariable lv) or
   PSetInvalid(InvalidReason ir) or
   PSetUnknown()
 
 class PSetEntry extends TPSetEntry {
   string toString() {
     exists(LocalVariable lv |
       this = PSetVar(lv) and
       result = "Var(" + lv.toString() + ")"
     )
     or
     this = PSetUnknown() and result = "Unknown"
     or
     exists(InvalidReason ir |
       this = PSetInvalid(ir) and
       result = "Invalid because " + ir.toString()
     )
   }
 }
 
 /**
  * Holds if `lv` is reassigned at `cfn`.
  */
 private predicate isPSetReassigned(ControlFlowNode cfn, LocalVariable lv) {
   exists(DeclStmt ds |
     none()
   )
   or
   none()
 }
 
 /**
  * Returns a `PSetEntry` for `lv` at `cfn`.
  */
 private PSetEntry getAnAssignedPSetEntry(ControlFlowNode cfn, LocalVariable lv) {
   exists(DeclStmt ds |
      none()
   )
   or
   exists(Expr assign |
     none()
   |
     exists(LocalVariable otherLv |
       none()
     )
     or
     exists(VariableAccess va |
       none()
     )
     or
     not assign instanceof AddressOfExpr and
     not assign instanceof VariableAccess and
     result = PSetUnknown()
   )
 }
 
 predicate pointsToMap(ControlFlowNode cfn, LocalVariable lv, PSetEntry pse) {
   none()
 }
 
 from ControlFlowNode cfn, LocalVariable lv, PSetEntry pse
 where pointsToMap(cfn, lv, pse)
 select cfn, lv, pse
 