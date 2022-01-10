#include "mop.h"

MODULE = Class::MOP   PACKAGE = Class::MOP

PROTOTYPES: DISABLE

# use prototype here to be compatible with get_code_info from Sub::Identify
void
get_code_info(coderef)
    SV *coderef
    PROTOTYPE: $
    PREINIT:
        char *pkg  = NULL;
        char *name = NULL;
    PPCODE:
        SvGETMAGIC(coderef);
        if (mop_get_code_info(coderef, &pkg, &name)) {
            EXTEND(SP, 2);
            mPUSHs(newSVpv(pkg, 0));
            mPUSHs(newSVpv(name, 0));
        }
