#include "mop.h"

MODULE = Class::MOP::Method::Generated   PACKAGE = Class::MOP::Method::Generated

PROTOTYPES: DISABLE

BOOT:
    INSTALL_SIMPLE_READER(Method::Generated, is_inline);
    INSTALL_SIMPLE_READER(Method::Generated, definition_context);
