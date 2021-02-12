/*
 * $Id: rfc1738.h,v 1.1 2005/04/05 22:55:09 maxb Exp $
 */

#ifndef SETUP_RFC1738_H
#define SETUP_RFC1738_H

#include <string>

std::string rfc1738_escape_part(const std::string &url);
std::string rfc1738_unescape(const std::string &s);

#endif /* SETUP_RFC1738_H */
