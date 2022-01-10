#ifndef __MOP_H__
#define __MOP_H__

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_newRV_noinc
#define NEED_sv_2pv_flags
#define NEED_sv_2pv_nolen
#include "ppport.h"

/* In theory, ExtUtils::ParseXS provide backcompat for this. However, the only
 * available version doing that right now is 3.03_02, which is a dev release. We
 * don't want to depend on dev releases, so we copy the code here. It should be
 * removed once there's a stable ExtUtils::ParseXS version newer than 3.03_02. */
#ifndef XS_EXTERNAL
#  define XS_EXTERNAL XS
#endif

#define MOP_CALL_BOOT(name)  mop_call_xs(aTHX_ name, cv, mark);

#ifndef XSPROTO
#define XSPROTO(name) XS_EXTERNAL(name)
#endif

#ifndef CvISXSUB
#define CvISXSUB(cv)  (CvXSUB(cv) ? TRUE : FALSE)
#endif

void mop_call_xs (pTHX_ XSPROTO(subaddr), CV *cv, SV **mark);

typedef enum {
    KEY__expected_method_class,
    KEY_ISA,
    KEY_VERSION,
    KEY_accessor,
    KEY_associated_class,
    KEY_associated_metaclass,
    KEY_associated_methods,
    KEY_attribute_metaclass,
    KEY_attributes,
    KEY_body,
    KEY_builder,
    KEY_clearer,
    KEY_constructor_class,
    KEY_constructor_name,
    KEY_definition_context,
    KEY_destructor_class,
    KEY_immutable_trait,
    KEY_init_arg,
    KEY_initializer,
    KEY_insertion_order,
    KEY_instance_metaclass,
    KEY_is_inline,
    KEY_method_metaclass,
    KEY_methods,
    KEY_name,
    KEY_package,
    KEY_package_name,
    KEY_predicate,
    KEY_reader,
    KEY_wrapped_method_metaclass,
    KEY_writer,
    KEY_package_cache_flag,
    KEY__version,
    KEY_operator,
    key_last,
} mop_prehashed_key_t;

#define KEY_FOR(name)  mop_prehashed_key_for(KEY_ ##name)
#define HASH_FOR(name) mop_prehashed_hash_for(KEY_ ##name)

void mop_prehash_keys (void);
SV *mop_prehashed_key_for (mop_prehashed_key_t key);
U32 mop_prehashed_hash_for (mop_prehashed_key_t key);

#define INSTALL_SIMPLE_READER(klass, name)  INSTALL_SIMPLE_READER_WITH_KEY(klass, name, name)
#define INSTALL_SIMPLE_READER_WITH_KEY(klass, name, key) \
    { \
        CV *cv = newXS("Class::MOP::" #klass "::" #name, mop_xs_simple_reader, __FILE__); \
        CvXSUBANY(cv).any_i32 = KEY_ ##key; \
    }

XS_EXTERNAL(mop_xs_simple_reader);

extern SV *mop_method_metaclass;
extern SV *mop_associated_metaclass;
extern SV *mop_wrap;

UV mop_check_package_cache_flag(pTHX_ HV *stash);
int mop_get_code_info (SV *coderef, char **pkg, char **name);
SV *mop_call0(pTHX_ SV *const self, SV *const method);

typedef enum {
    TYPE_FILTER_NONE,
    TYPE_FILTER_CODE,
    TYPE_FILTER_ARRAY,
    TYPE_FILTER_IO,
    TYPE_FILTER_HASH,
    TYPE_FILTER_SCALAR,
} type_filter_t;

typedef bool (*get_package_symbols_cb_t) (const char *, STRLEN, SV *, void *);

void mop_get_package_symbols(HV *stash, type_filter_t filter, get_package_symbols_cb_t cb, void *ud);
HV *mop_get_all_package_symbols (HV *stash, type_filter_t filter);

#endif
