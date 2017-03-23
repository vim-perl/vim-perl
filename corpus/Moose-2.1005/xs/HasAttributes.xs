#include "mop.h"

MODULE = Class::MOP::Mixin::HasAttributes   PACKAGE = Class::MOP::Mixin::HasAttributes

PROTOTYPES: DISABLE

BOOT:
    INSTALL_SIMPLE_READER(Mixin::HasAttributes, attribute_metaclass);
    INSTALL_SIMPLE_READER_WITH_KEY(Mixin::HasAttributes, _attribute_map, attributes);
