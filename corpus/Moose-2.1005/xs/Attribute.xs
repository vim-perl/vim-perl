#include "mop.h"

MODULE = Class::MOP::Attribute   PACKAGE = Class::MOP::Attribute

PROTOTYPES: DISABLE

BOOT:
    INSTALL_SIMPLE_READER(Attribute, associated_class);
    INSTALL_SIMPLE_READER(Attribute, associated_methods);
