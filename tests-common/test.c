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