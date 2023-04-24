SRCDIR=$(pwd)/tests-common
DB=$(pwd)/cpp-dangling-pointer-database
codeql database create --language=cpp -s "$SRCDIR" -j 8 -v $DB --command="clang -fsyntax-only $SRCDIR/test.c"