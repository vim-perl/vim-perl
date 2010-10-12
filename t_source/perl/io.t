print "text\n";
print STDERR "text\n";
print {$filehandle} "text\n";
print { $OK ? STDOUT : STDERR } "stuff\n";

printf "text\n";
printf STDERR "text\n";
printf {$filehandle} "text\n";
printf { $OK ? STDOUT : STDERR } "stuff\n";


use 5.010;

say "text";
say STDERR "text";
say {$filehandle} "text";
say { $OK ? STDOUT : STDERR } "stuff\n";

