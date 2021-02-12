#ifndef SETUP_PREREQ_H
#define SETUP_PREREQ_H

#include <map>
#include "proppage.h"
#include "PackageTrust.h"
#include "package_meta.h"

using namespace std;

// keeps the map sorted by name
struct packagemeta_ltcomp
{
  bool operator() ( const packagemeta *m1, const packagemeta *m2 ) const
    { return casecompare(m1->name, m2->name) < 0; }
};


class PrereqPage:public PropertyPage
{
public:
  PrereqPage ();
  virtual ~PrereqPage () { };
  bool Create ();
  virtual void OnInit ();
  virtual void OnActivate ();
  virtual long OnNext ();
  virtual long OnBack ();
  virtual long OnUnattended ();
};

class PrereqChecker
{
public:
  // checks all dependecies, populates 'unmet'
  // returns true if unsatisfied dependencies exist
  bool isMet ();
  
  // formats 'unmet' as a string for display
  void getUnmetString (std::string &s);
  
  // selects/picks the needed packages that were missing
  void selectMissing ();
  
  // notes the current trust (for use in selectMissing)
  void setTrust (trusts t) { theTrust = t; };

private:
  
  // this is the actual hash_map that does all the work
  static map <packagemeta *, vector <packagemeta *>, packagemeta_ltcomp> unmet;
  static trusts theTrust;
};

#endif /* SETUP_PREREQ_H */
