#include "mop.h"

MODULE = Class::MOP::Instance   PACKAGE = Class::MOP::Instance

PROTOTYPES: DISABLE

BOOT:
    INSTALL_SIMPLE_READER(Instance, associated_metaclass);
