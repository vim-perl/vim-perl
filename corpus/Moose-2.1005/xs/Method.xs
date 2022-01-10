#include "mop.h"

MODULE = Class::MOP::Method   PACKAGE = Class::MOP::Method

PROTOTYPES: DISABLE

BOOT:
    INSTALL_SIMPLE_READER(Method, name);
    INSTALL_SIMPLE_READER(Method, package_name);
    INSTALL_SIMPLE_READER(Method, body);

bool
is_stub(self)
    SV *self

    PREINIT:
        CV *const body = (CV *)SvRV( HeVAL( hv_fetch_ent((HV *)SvRV(self), KEY_FOR(body), 0, HASH_FOR(body)) ) );

    CODE:
        RETVAL = !( CvISXSUB(body) || CvROOT(body) );

    OUTPUT:
        RETVAL
