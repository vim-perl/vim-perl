#!/usr/bin/perl

use strict;
use warnings;

use Fatal qw/open/;
use File::Spec;

our $VERSION = '0.201008171';

my $root = $ARGV[0] || '.';
die 'Wrong directory' unless -e $root and -r _ and -x _;

sub perlfile {
 my $path = File::Spec->catfile($root, $_[0]);
 return $_[1] ? do { open my $fh, '<', $path; $fh } : $path;
}

my (%macros, %functions, %private, %superseded);

my %skip_functions = map { $_ => 1 } qw{
 lop
};

my %types = map { $_ => 1 } qw{
 pTHX    _pTHX    pTHX_
 pMY_CXT _pMY_CXT pMY_CXT_
 my_cxt_t
 OPCODE
};

my %skip_types = map { $_ => 1 } qw{
 sv av hv he hek cv gv gp io
 op unop binop listop svop pvop pmop padop loop logop
 cop block subst context stackinfo
 token nexttoken
 interpreter expectation
 jmpenv
 any
};

sub maybe_type {
 local $_ = $_[0];

 return if $skip_types{$_};

 ++$types{$_};
}

my %variables = map { $_ => 1 } qw{
 aTHX    _aTHX    aTHX_
 aMY_CXT _aMY_CXT aMY_CXT_
 MY_CXT
 SP TARG MARK ORIGMARK
 RETVAL items
};

my %constants = map { $_ => 1 } qw{
 SVt_PVBM SVt_RV
};

my %strings = map { $_ => 1 } qw{
 IVdf UVuf UVof UVxf NVef NVff NVgf
 SVf SVf_ SVf32 SVf256
};

my %exceptions = map { $_ => 1 } qw{
 dXCPT XCPT_TRY_START XCPT_TRY_END XCPT_CATCH XCPT_RETHROW
};

my %keywords = map { $_ => 1 } qw{
 MODULE PACKAGE PREFIX
 IN OUTLIST IN_OUTLIST OUT IN_OUT
 ENABLE DISABLE
 length
 OUTPUT: NO_OUTPUT: CODE: INIT: NO_INIT: PREINIT: SCOPE: INPUT: C_ARGS:
 PPCODE: REQUIRE: CLEANUP: POSTCALL: BOOT: VERSIONCHECK:
 PROTOTYPES: PROTOTYPE: ALIAS: OVERLOAD: FALLBACK:
 INTERFACE: INTERFACE_MACRO: INCLUDE: CASE:
};

my %skip_macro = map { $_ => 1 } qw{
 void const register volatile NULL
};

sub maybe_macro {
 local $_  = $_[0];
 my $value = $_[1];

 return if $skip_macro{$_}
        or $functions{$_}  or $private{$_}    or $superseded{$_}
        or $types{$_}      or $variables{$_}  or $constants{$_}
        or $strings{$_}    or $exceptions{$_} or $keywords{$_};

 if (/^(?:SV[sfp]|OPf_|OPp[A-Z]+|OA_|CXt_|G_|PERL_MAGIC_)/) {
  ++$constants{$_};
  return;
 } elsif (/^\w+_t$/) {
  ++$types{$_};
  return;
 }

 ++$macros{$_};
}

my %clib = (
 map( { 'std' . $_ => 'PerlIO_std' . $_ } qw/in out err/ ),
 map( { 'f' . $_ => 'PerlIO_' . $_ } qw/open reopen flush close read write puts eof seek getpos setpos error/ ),
 map( { my $p = 'PerlIO_' . $_; $_ => $p, "f$_" => $p } qw/printf getc putc/ ),
 map( { $_ => 'PerlIO_' . $_ } qw/ungetc rewind clearerr/ ),
 'fgets'   => 'sv_gets',
 'malloc'  => 'Newx',
 'calloc'  => 'Newxz',
 'realloc' => 'Renew',
 'memcpy'  => 'Copy',
 'memmove' => 'Move',
 'memset'  => 'Zero',
 'free'    => 'Safefree',
 'strdup'  => 'savepv',
 'strstr'  => 'instr',
 'strcmp'  => 'strEQ',
 'strncmp' => 'strnEQ',
 'strlen'  => 'sv_len',
 'strcpy'  => 'sv_setpv',
 'strncpy' => 'sv_setpvn',
 'strcat'  => 'sv_catpv',
 'strncat' => 'sv_catpvn',
 'sprintf' => 'sv_setpvf',
 map( { my $u = uc; "is$_" => "is$u" } qw/alnum alpha cntrl digit graph lower print punct space upper xdigit/),
 map( { my $u = uc; "to$_" => "to$u" } qw/lower upper/),
 map( { $_ => ucfirst } qw/atof atol strtol strtoul/),
 'strtod' => 'croak', # Dummy
 'rand'   => 'Drand01',
 'srand'  => 'seedDrand01',
 'exit'   => 'my_exit',
 'system' => 'croak', # Dummy
 'getenv' => 'PerlEnv_getenv',
 'setenv' => 'my_putenv'
);

%superseded = map { $_ => 1 } keys %clib;

{
 my $intrpvar = perlfile('intrpvar.h', 1);
 while (<$intrpvar>) {
  if (/^\s*PERLVARI?\s*\(\s*I?(\w+)/) {
   ++$variables{"PL_$1"}
  }
 }
}

{
 my $pp_proto = perlfile('pp_proto.h', 1);
 while (<$pp_proto>) {
  if (/^\s*PERL_(?:CK|PP)DEF\s*\((\w+)\)/) {
   next if $skip_functions{$1};
   ++$functions{$1};
  }
 }
}

{
 my $embed = perlfile('embed.fnc', 1);
 while (<$embed>) {
  next if /^[\s:#]/;
  (my $flags, my $name) = /^(\w+)\s*\|.*?\|\s*([^\|\s]+)/;
  next unless $flags and $name;
  next if $skip_functions{$name};
  if ($flags =~ /A/ and $flags !~ /D/) {
   if ($flags =~ /m/) {
    ++$macros{$name}           unless $flags =~ /o/;
   } else {
    ++$functions{$name}        unless $flags =~ /o/;
    ++$functions{"Perl_$name"} if     $flags =~ /p/;
   }
  } else {
   if ($flags =~ /m/) {
    ++$private{$name};
   } elsif ($flags =~ /[sED]/) {
    ++$private{$name}        unless $flags =~ /o/;
    ++$private{"Perl_$name"} if     $flags =~ /p/;
    ++$private{"S_$name"}    if     $flags =~ /s/;
   }
  }
 }
}

my %skip_header = (
 'embed.h'    => 1,
 'pp_proto.h' => 1,
 'intrpvar.h' => 1,
);

for my $header (glob perlfile('*.h')) {
 next if $skip_header{ (File::Spec->splitpath($header))[2] };
 open my $header_fh, '<', $header;
 my ($comment, $enum);
 while (<$header_fh>) {
  s[/\*.*\*/][];
  if (s[/\*.*][]) {
   $comment = 1;
   # Process the beginning of the line
  } elsif ($comment) {
   $comment = not s[.*\*/][];
   next if $comment;
  }
  if ($enum || s/^\s*typedef\s*enum\s*\w*\s*\{//) {
   $enum = !/\}\s*(\w*)\s*;/;
   ++$types{$1} if $1;
   ++$constants{$_} for map { /^\s*(\w+)/ ? $1 : () } split /,/, $_;
   next;
  }
  if (/^\s*\#\s*undef\s*(\w+)/) {
   delete $macros{$1};
  } elsif (my ($macro, $value) = /^\s*\#\s*define\s*(\w+)\s*(\S*)/) {
   maybe_macro($macro, $value);
  } elsif (   /^\s*typedef.*?(\w+)\s*;/
           or /^\s*(?:struct|enum|union)\s+(\w+)\s+[\{;]/) {
   maybe_type($1);
  } elsif (/\b(?:extern|EXT(?:|ERN(?:_C)?|CONST))\b.*?\b(PL_\w+)\b/) {
   ++$variables{$1};
  }
 }
}

{
 my $toke = perlfile('toke.c', 1);
 while (<$toke>) {
  if (/^\s*#\s*define\s*(PL_\w+)/) {
   ++$variables{$1};
  }
 }
}

print STDERR "Found " . (keys %functions) . " functions, "
                      . (keys %macros)    . " macros, "
                      . (keys %variables) . " variables, "
                      . (keys %constants) . " constants and "
                      . (keys %types)     . " types\n";

my $len = 78;

sub output {
 my ($data, $type, $fh) = @_;
 $fh = *STDOUT unless $fh;
 my $head = "syn keyword xs$type";
 my $line = $head;
 for (sort keys %$data) {
  if (length() + length($line) + 1 >= $len) {
   print $fh "$line\n";
   $line = $head;
  }
  $line .= " $_";
 }
 print $fh "$line\n" if $line;
}

my $vim = \*STDOUT;

my ( undef, undef, undef, $day, $month, $year ) = gmtime();
$year += 1900;
$month++;
my $date = sprintf '%04d-%02d-%02d', $year, $month, $day;

print $vim <<_VIM_;
" Vim syntax file
" Language:    XS (Perl extension interface language)
" Author:      Autogenerated from perl headers, on an original basis of Michael W. Dodge <sarge\@pobox.com>
" Maintainer:  vim-perl <vim-perl\@googlegroups.com>
" Previous:    Vincent Pit <perl\@profvince.com>
" Last Change: $date

" For version 5.x: Clear all syntax items
" For version 6.x: Quit when a syntax file was already loaded
if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

" Read the C syntax to start with
if version < 600
  source <sfile>:p:h/c.vim
else
  runtime! syntax/c.vim
endif

let xs_superseded = 1 " mark C functions superseded by Perl replacements
let xs_not_core   = 1 " mark private core functions

_VIM_

print $vim "if exists(\"xs_superseded\") && xs_superseded\n";
output \%superseded, 'Superseded' => $vim;
print $vim "endif\n";

print $vim "if exists(\"xs_not_core\") && xs_not_core\n";
output \%private,    'Private'    => $vim;
print $vim "endif\n";

output \%types,      'Type'       => $vim;
output \%strings,    'String'     => $vim;
output \%constants,  'Constant'   => $vim;
output \%exceptions, 'Exception'  => $vim;
output \%keywords,   'Keyword'    => $vim;
output \%functions,  'Function'   => $vim;
output \%variables,  'Variable'   => $vim;
output \%macros,     'Macro'      => $vim;

print $vim <<'_VIM_';

" Define the default highlighting.
" For version 5.7 and earlier: only when not done already
" For version 5.8 and later: only when an item doesn't have highlighting yet
if version >= 508 || !exists("did_xs_syntax_inits")
  if version < 508
    let did_xs_syntax_inits = 1
    command -nargs=+ HiLink hi link <args>
  else
    command -nargs=+ HiLink hi def link <args>
  endif

  HiLink xsPrivate    Error
  HiLink xsSuperseded Error
  HiLink xsType       Type
  HiLink xsString     String
  HiLink xsConstant   Constant
  HiLink xsException  Exception
  HiLink xsKeyword    Keyword
  HiLink xsFunction   Function
  HiLink xsVariable   Identifier
  HiLink xsMacro      Macro

  delcommand HiLink
endif

let b:current_syntax = "xs"

" vim: ts=8
_VIM_
