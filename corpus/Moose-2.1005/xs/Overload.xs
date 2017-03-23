#include "mop.h"

MODULE = Class::MOP::Method::Overload   PACKAGE = Class::MOP::Method::Overload

PROTOTYPES: DISABLE

BOOT:
    INSTALL_SIMPLE_READER(Method::Overload, operator);
