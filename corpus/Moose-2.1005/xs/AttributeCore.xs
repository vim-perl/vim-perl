#include "mop.h"

MODULE = Class::MOP::Mixin::AttributeCore   PACKAGE = Class::MOP::Mixin::AttributeCore

PROTOTYPES: DISABLE

BOOT:
    INSTALL_SIMPLE_READER(Mixin::AttributeCore, name);
    INSTALL_SIMPLE_READER(Mixin::AttributeCore, accessor);
    INSTALL_SIMPLE_READER(Mixin::AttributeCore, reader);
    INSTALL_SIMPLE_READER(Mixin::AttributeCore, writer);
    INSTALL_SIMPLE_READER(Mixin::AttributeCore, predicate);
    INSTALL_SIMPLE_READER(Mixin::AttributeCore, clearer);
    INSTALL_SIMPLE_READER(Mixin::AttributeCore, builder);
    INSTALL_SIMPLE_READER(Mixin::AttributeCore, init_arg);
    INSTALL_SIMPLE_READER(Mixin::AttributeCore, initializer);
    INSTALL_SIMPLE_READER(Mixin::AttributeCore, definition_context);
    INSTALL_SIMPLE_READER(Mixin::AttributeCore, insertion_order);
