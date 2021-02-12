/*
 *
 */

#ifndef SETUP_LICENSE_AGREEMENT_H
#define SETUP_LICENSE_AGREEMENT_H

// This is the header for the SplashPage class.  Since the splash page
// has little to do, there's not much here.

#include "proppage.h"


class BoolOption;
extern BoolOption AutoAcceptLicenseOption;

class LicensePage : public PropertyPage
{
public:
  HWND ins_pkgname;
  HWND ins_licensetxt;
  
  LicensePage ();
  //LicensePage (LicensePage const &);
  virtual ~LicensePage() {}

  bool Create ();
  virtual void OnInit();
  virtual void OnActivate();
  virtual long OnNext();
  virtual long OnBack();
  virtual bool OnMessageCmd (int id, HWND hwndctl, UINT code);

  bool wantsActivation() const;
  long OnUnattended ();

  void setPackageName(const TCHAR * t);
  void setLicenseText(const std::string &t);
  void updateButtonNext();

  bool loadLicense(std::string file);

  std::string currentLicense;
  
  /*Printing functions*/
  void printLicense(HWND hWndParent);

  HDC getPrinterDC(HWND Hwnd);
};

class RestrictivePackage
{
public:
  std::string name;
  std::string version;
  std::string remote_path;
  std::string local_path;

  bool agree_license;
  bool selectedpkg;

  //TypeLicense type;
  RestrictivePackage(RestrictivePackage const &);

  RestrictivePackage(std::string pname, std::string pversion, std::string ppath )
    : name(pname), version(pversion), remote_path(ppath)
    , local_path(""), agree_license(false), selectedpkg(false)
  {}

  RestrictivePackage()
    : name(""), version(""), agree_license(false), selectedpkg(false)
  {}
};

#endif /* SETUP_LICENSE_AGREEMENT_H */
