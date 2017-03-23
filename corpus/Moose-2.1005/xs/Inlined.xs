#include "mop.h"

MODULE = Class::MOP::Method::Inlined   PACKAGE = Class::MOP::Method::Inlined

PROTOTYPES: DISABLE

BOOT:
    INSTALL_SIMPLE_READER(Method::Inlined, _expected_method_class);
