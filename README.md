# CodeQL Workshop — Identifying Dangling Pointers in C and C++

## Acknowledgements
This workshop is based on [this write-up](https://github.com/advanced-security/codeql-workshops-staging/blob/master/cpp/type-conversions-dangling-pointer/README.md) and the [LifetimeProfile.qll library](https://github.com/github/codeql-coding-standards/blob/main/cpp/common/src/codingstandards/cpp/lifetimes/lifetimeprofile/LifetimeProfile.qll) from the [CodeQL Coding Standards repository](https://github.com/github/codeql-coding-standards).

## Setup Instructions
- Install [Visual Studio Code](https://code.visualstudio.com/).
- Install the [CodeQL extension for Visual Studio Code](https://codeql.github.com/docs/codeql-for-visual-studio-code/setting-up-codeql-in-visual-studio-code/).
- Install the latest version of the [CodeQL CLI](https://github.com/github/codeql-cli-binaries/releases).
- Clone this repository:
  ```bash
  git clone https://github.com/kraiouchkine/codeql-workshop-dangling-pointers-c
  ```
- Install the CodeQL pack dependencies using the command `CodeQL: Install Pack Dependencies` and select `exercises`, `solutions`, `exercises-tests`, and `solutions-tests` from the list of packs.
- If you have CodeQL on your PATH, build the database using `build-database.sh` and load the database with the VS Code CodeQL extension. 
  - Alternatively, you can download [this pre-built database](https://drive.google.com/file/d/1CvqvJwnIp332HZ5SWCS2pHVGyy5b1g8_/view?usp=share_link).
- :exclamation:Important:exclamation:: Run `initialize-qltests.sh` to initialize the tests. Otherwise, you will not be able to run the QLTests (in `exercises-tests` and `solutions-tests`).

## Introduction
A dangling pointer is a memory safety violation where the pointer does not point to a valid object.
These dangling pointers are the result of not modifying the value of the pointer after the pointed to object is destructed or not properly initializing the pointer.

The use of a dangling pointer can result in a security issue, particularly in C++ if that dangling pointer is used to invoke a *virtual* method and an attacker was able to overwrite the parts of the memory that would have contained the `vtable` of the object.

The following snippet demonstrates how a dangling pointer can occur:

```cpp
void dangling_pointer() {
	char **p = nullptr;
	{
		char * s = "hello world";
		p = &s;
	}
	printf("%s", *p);
}
```

Another less obvious case is:

```cpp
void dangling_pointer() {
	std::string_view s = "hello world"s;
	std::cout << s << std::endl;
}
```

After the full expression from the preceding example is evaluated, the temporary object is destroyed.

Many more interesting examples are discussed here: https://herbsutter.com/2018/09/20/lifetime-profile-v1-0-posted/

To find these issues, we can implement an analysis that tracks lifetimes. A nice specification for a local lifetime analysis is given by https://github.com/isocpp/CppCoreGuidelines/blob/master/docs/Lifetime.pdf.

The gist of the analysis is, for each local variable, to track the things that it can point to at a particular _location_ in the program. These _locations_ are other local variables and special values for global variables, null values, and invalid values. Whenever a variable goes out of scope, each reference to that variable in a points-to set is invalidated.

In the next few exercises, we are going to implement a simplified version of the lifetime profile to find the dangling pointer in the following example:

```cpp
extern void printf(char *, ...);

void simple_dangling_pointer() {
  char **p;
  {
    char *s = "hello world!";
    p = &s;
  }
  printf("%s", *p);
  char *s = "hello world!";
  p = &s;
  printf("%s", *p);
  return;
}
```

The simplified version will track 3 possible *points-to* values.

1. Variable; A pointer points to another pointer. We will only consider local variables represented by the class `LocalVariable`.
2. Invalid; A pointer is not initialized or points to a variable that went out of scope.
3. Unknown; A pointer is assigned something other than the address of another `LocalVariable` (e.g., the address of a string.).

### Exercise 1

In the first exercise we are going to model the entries of the *points-to* set that we are going to associated with pointers at locations in the program as well as the two possible `Invalid` value types: uninitialized and out of scope. 

#### Task 1
Start by implementing the [algebraic datatype](https://codeql.github.com/docs/ql-language-reference/types/#algebraic-datatypes) `PSetEntry` that represents the possible entries of our *points-to* set with the three values listed above. A template has been provided.


#### Task 2
Next, to be able to represent the *invalid* values, we need to implement another *algebraic datatype* for the two possible values. Note that besides the `newtype`, `Exercise1.ql` provides a template of a `class` that extends from the *algebraic datatype*. This is a [standard pattern](https://codeql.github.com/docs/ql-language-reference/types/#standard-pattern-for-using-algebraic-datatypes) that allows us to associate a convenient `toString` member predicate that we will use to print the invalid reason.

The type `TInvalidReason` creates a user-defined type with values that are neither *primitive* values nor *entities* for database. Each of two values represent an invalid *points-to* value. The case when a pointer is not initialized or pointing to a pointer that is out of scope.

The `TVariableOutOfScope` branch associates a new value of the branch type to the pair `(LocalVariable, ControlFlowNode)` if the local variable goes out of scope at that point in the program. 

#### Task 3
Define the `goesOutOfScope` predicate using the following predicates:
* `Element::getParentScope` (`LocalVariable` derives from `Element`)
* `Stmt::getFollowingStmt` (`BlockStmt` derives from `Stmt`)

Run the query and ensure that you have three results.

### Exercise 2

With the *points-to* set entries modeled we can start to implement parts of our *points-to* set that will associate *points-to* set entries to local variables at a program location. That map will be implemented by the predicate `pointsToMap`.

In this predicate we must consider three cases:

1. The local variable `lv` is assigned a value at location `cfn` that defines the *points-to* set entry `pse`.
2. The local local variable `lv` is not assigned so we have to propagate the *points-to* set entry from a previous location.
3. The local variable `lv` is not assigned, but points to a variable that went out of scope at location `cfn` so we need to invalid the entry for that variable.

In this exercise we are going to implement the first case by implementing the `getAnAssignedPSetEntry` predicate and a one-liner use of it in `pointsToMap`.

#### Hints

1. The class `DeclStmt` models a declaration statement and the predicate `getADeclaration` relates what is declared (e.g., a `Variable`)
2. For a `Variable` we can get the `Expr` that represent the value that is assigned to the variable with the predicate `getAnAssignedValue`.
3. The `AddressOfExpr` models an "address taken of" operation, which when assigned to a variable, can be used to determine if one variable points-to another variable. Consider using recursion to handle this case.

### Exercise 3

With case 1 of the `pointsToMap` being implemented we are going to implement cases 2 and 3. First, however, we need to implement the `isPSetReassigned` predicate.

- The predicate `isPSetReassigned` should hold if a new *points-to* entry should be assigned at that location. This happens when:
	- A local variable is declared and is uninitialized.
	- A local variable is assigned a value.
- The predicate `getAnAssignedPSEntry` should relate a program location and variable to a *points-to* entry.

For case 2, we now need to propagate a *points-to* entry from a previous location. 

For case 3, we need to invalidate a *points-to* entry if the entry at the previous location is a `PSetVar` for which the variable goes out of scope at our current location `cfn`.

Note that we only consider case 2 and case 3 if the variable doesn't go out of scope at the current location, otherwise we stop propagation for of *points-to* entries for that variable.

```ql
predicate pointsToMap(ControlFlowNode cfn, LocalVariable lv, PSEntry pse) {
	if isPSetReassigned(cfn, lv)
	then pse = getAnAssignedPSetEntry(cfn, lv)
	else
		exists(ControlFlowNode pred, PSEntry prevPse |
            // `lv` does not go out of scope at `cfn`
            // and pred/prevPse are bound via a predecessor
            // entry in the `pointsToMap` relation
		|
			// case 2
			or
			// case 3
		)
}
```

### Exercise 4

With the *points-to* map implemented we can find *uses* of dangling pointers. 

Implement the class `DanglingPointerAccess` that finds uses of dangling points.

#### Hint
- You will need to use `TVariableOutOfScope`, but `TVariableOutOfScope` binds an `LocalVariable` to the specific `ControlFlowNode` at which it went out of scope; the `LocalVariable` and `ControlFlowNode` that the `PointerDereferenceExpr` references may be different. Therefore, use a ["don't-care expression"](https://codeql.github.com/docs/ql-language-reference/ql-language-specification/#don-t-care-expressions).
