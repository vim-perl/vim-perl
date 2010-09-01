my $escaped_fixed = "lol is \"lol\"";
my $escaped_fixed = q(lol is (\)));
my $escaped_fixed = qq(lol is (\)));
my $escaped_fixed = qr(\((.)\)); # this really is ok, not sure how to match balanced ()s in vim-syntax-lingo though

package Dummy;

=head1 About Dummy.pm

This package exists only to give a playground for testing Vim.  It
is not actually used.

=head2 Reasons this is useful

=over 4

=item * Users don't have to make their own.

=item * Making a sample file can be B<hard work>.

=back

=cut

use strict;
use warnings;
use Wango;

1; # Happy
