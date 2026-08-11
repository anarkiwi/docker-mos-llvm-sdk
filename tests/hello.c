#include <stdio.h>

int main(void) {
  for (unsigned char i = 0; i < 3; ++i) {
    printf("hello %u\n", i);
  }
  return 0;
}
