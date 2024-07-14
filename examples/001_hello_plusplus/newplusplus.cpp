#include <stdlib.h>

extern "C" void dbgfatal (void);

extern "C" void* pcfx_new (unsigned len)
{
  void *p = malloc( len );
  if (p == 0)
  {
    // No exceptions ... so abort!
    dbgfatal();
  }
  return p;
}

extern "C" void pcfx_delete (void * p)
{
  free(p);
}

void * operator new      (unsigned len) __attribute__((alias("pcfx_new")));
void * operator new[]    (unsigned len) __attribute__((alias("pcfx_new")));   
void   operator delete   (void* p)      __attribute__((alias("pcfx_delete")));
void   operator delete[] (void* p)      __attribute__((alias("pcfx_delete")));
void * __cxa_pure_virtual = 0;
