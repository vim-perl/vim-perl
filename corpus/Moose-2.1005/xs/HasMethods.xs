#include "mop.h"

SV *mop_method_metaclass;
SV *mop_associated_metaclass;
SV *mop_wrap;

static void
mop_update_method_map(pTHX_ HV *const stash, HV *const map)
{
    char *method_name;
    I32   method_name_len;
    SV   *method;
    HV   *symbols;

    symbols = mop_get_all_package_symbols(stash, TYPE_FILTER_CODE);
    sv_2mortal((SV*)symbols);

    (void)hv_iterinit(map);
    while ((method = hv_iternextsv(map, &method_name, &method_name_len))) {
        SV *body;
        SV *stash_slot;

        if (!SvROK(method)) {
            continue;
        }

        if (sv_isobject(method)) {
            /* $method_object->body() */
            body = mop_call0(aTHX_ method, KEY_FOR(body));
        }
        else {
            body = method;
        }

        stash_slot = *hv_fetch(symbols, method_name, method_name_len, TRUE);
        if (SvROK(stash_slot) && ((CV*)SvRV(body)) == ((CV*)SvRV(stash_slot))) {
            continue;
        }

        /* delete $map->{$method_name} */
        (void)hv_delete(map, method_name, method_name_len, G_DISCARD);
    }
}

MODULE = Class::MOP::Mixin::HasMethods   PACKAGE = Class::MOP::Mixin::HasMethods

PROTOTYPES: DISABLE

void
_method_map(self)
    SV *self
    PREINIT:
        HV *const obj        = (HV *)SvRV(self);
        SV *const class_name = HeVAL( hv_fetch_ent(obj, KEY_FOR(package), 0, HASH_FOR(package)) );
        HV *const stash      = gv_stashsv(class_name, 0);
        UV current;
        SV *cache_flag;
        SV *map_ref;
    PPCODE:
        if (!stash) {
             mXPUSHs(newRV_noinc((SV *)newHV()));
             return;
        }

        current    = mop_check_package_cache_flag(aTHX_ stash);
        cache_flag = HeVAL( hv_fetch_ent(obj, KEY_FOR(package_cache_flag), TRUE, HASH_FOR(package_cache_flag)));
        map_ref    = HeVAL( hv_fetch_ent(obj, KEY_FOR(methods), TRUE, HASH_FOR(methods)));

        /* $self->{methods} does not yet exist (or got deleted) */
        if ( !SvROK(map_ref) || SvTYPE(SvRV(map_ref)) != SVt_PVHV ) {
            SV *new_map_ref = newRV_noinc((SV *)newHV());
            sv_2mortal(new_map_ref);
            sv_setsv(map_ref, new_map_ref);
        }

        if ( !SvOK(cache_flag) || SvUV(cache_flag) != current ) {
            mop_update_method_map(aTHX_ stash, (HV *)SvRV(map_ref));
            sv_setuv(cache_flag, mop_check_package_cache_flag(aTHX_ stash)); /* update_cache_flag() */
        }

        XPUSHs(map_ref);

BOOT:
    mop_method_metaclass     = newSVpvs("method_metaclass");
    mop_associated_metaclass = newSVpvs("associated_metaclass");
    mop_wrap                 = newSVpvs("wrap");
    INSTALL_SIMPLE_READER(Mixin::HasMethods, method_metaclass);
    INSTALL_SIMPLE_READER(Mixin::HasMethods, wrapped_method_metaclass);
