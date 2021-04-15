// Line class for tokenizer

void fnsplit(char *fname, char *name, char *ext);
void fnmerge(char *fname, char *name, char *ext);
char* getstr(char *str, int max, FILE* fi);
void putWord(int val, FILE* fo);
char cvt(char c);

class Line {
  int num;
  char line[1024];

public:
  Line(char *iline);

  void tokenize(void);
  int number(void) { return num; }
  int length(void) { return strlen(line); }
  char* data(void) { return line; }
};
