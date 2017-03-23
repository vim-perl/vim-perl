#include "mop.h"

MODULE = Class::MOP::Package   PACKAGE = Class::MOP::Package

PROTOTYPES: DISABLE

BOOT:
    INSTALL_SIMPLE_READER_WITH_KEY(Package, name, package);
