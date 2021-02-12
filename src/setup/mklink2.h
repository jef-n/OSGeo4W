#ifndef SETUP_MKLINK2_H
#define SETUP_MKLINK2_H

/* This part of the code must be in C because the C++ interface to COM
doesn't work. */

#ifdef __cplusplus
extern "C"
{
#endif
  void make_link_2 (char const *exepath, char const *args, char const *icon, char const *lname);

  int mkcygsymlink (const char *from, const char *to);
  int mkcyghardlink (const char *from, const char *to);

#ifdef __cplusplus
};
#endif

#endif /* SETUP_MKLINK2_H */
