use strict;
use warnings;

use Test::Spelling;

my @stopwords;
for (<DATA>) {
    chomp;
    push @stopwords, $_
        unless /\A (?: \# | \s* \z)/msx;    # skip comments, whitespace
}

add_stopwords(@stopwords);
local $ENV{LC_ALL} = 'C';
set_spell_cmd('aspell list -l en');
all_pod_files_spelling_ok;

__DATA__
## personal names
Aankhen
Anders
Aran
Buels
Clary
Debolaz
Deltac
Etheridge
Florian
Goro
Goulah
Hardison
Kinyon
Kinyon's
Kogman
Lanyon
Luehrs
McWhirter
Pearcey
Piotr
Prather
Ragwitz
Reis
Rockway
Roditi
Rolsky
Roszatycki
Roszatycki's
SL
Sedlacek
Shlomi
Stevan
Vilain
Yuval
autarch
backported
backports
blblack
bluefeet
chansen
chromatic's
dexter
doy
ewilhelm
frodwith
gphat
groditi
ingy
jgoulah
jrockway
kolibrie
konobi
lbr
merlyn
mst
nothingmuch
perigrin
phaylon
rafl
rindolf
rlb
robkinyon
sartak
stevan
tozt
wreis

## proper names
AOP
CentOS
CLOS
CPAN
OCaml
SVN
ohloh

## Moose
AttributeHelpers
BUILDALL
BUILDARGS
BankAccount
BankAccount's
BinaryTree
CLR
CheckingAccount
DEMOLISHALL
Debuggable
JVM
METACLASS
Metaclass
MOPs
MetaModel
MetaObject
Metalevel
MooseX
Num
OtherName
PosInt
PositiveInt
RoleSummation
Specio
Str
TypeContraints
clearers
composable
hardcode
immutabilization
immutabilize
introspectable
metaclass
metaclass's
metadata
metaobject
metaobjects
metaprogrammer
metarole
metaroles
metatraits
mixins
oose
ro
rw

## computerese
API
APIs
Baz
Changelog
Coercions
DUCKTYPE
DWIM
GitHub
GitHub's
Haskell
IRC
Immutabilization
Inlinable
JSON
Lexically
O'Caml
OO
OOP
ORM
ROLETYPE
SUBCLASSES
SUBTYPES
Subclasses
Smalltalk
Subtypes
TODO
UNIMPORTING
URI
Unported
Whitelist
# from the Support manual talking about version numbers
YY
YYZZ
ZZ
arity
arrayrefs
autodelegation
blog
clearers
codebase
coercions
committer
committers
compat
continutation
contrib
datetimes
dec
decrement
definedness
deinitialized
deprecations
destructor
destructors
destructuring
dev
discoverable
env
eval'ing
extensibility
hashrefs
hotspots
immutabilize
immutabilized
immutabilizes
incrementing
inlinable
inline
inlines
installable
instantiation
interoperable
invocant
invocant's
irc
isa
kv
login
matcher
metadata
mixin
mixins
mul
munge
namespace
Namespace
namespace's
namespaced
namespaces
namespacing
natatime
# as in required-ness
ness
optimizations
overridable
parameterizable
parameterization
parameterize
parameterized
parameterizes
params
pluggable
plugins
polymorphism
prechecking
prepends
pu
rebase
rebased
rebasing
rebless
reblesses
reblessing
refactored
refactoring
rethrows
runtime
serializer
sigil
sigils
stacktrace
stacktraces
stateful
subclass's
subclassable
subclasses
subname
subtype
subtypes
subtyping
unblessed
unexport
unimporting
uninitialize
unordered
unresolvable
unsets
unsettable
utils
whitelisted
workflow
workflows

## other jargon
bey
gey

## neologisms
breakability
delegatee
featureful
hackery
hacktern
undeprecate
wrappee

## compound
# half-assed
assed
# role-ish, Ruby-ish, medium-to-large-ish
ish
# kool-aid
kool
# pre-5.10
pre
# vice versa
versa
lookup
# co-maint
maint

## slang
C'mon
might've
Nuff

## things that should be in the dictionary, but are not
attribute's
declaratively
everybody's
everyone's
human's
indices
initializers
newfound
reimplements
reinitializes
specializer
unintrusive

## misspelt on purpose
emali
uniq
