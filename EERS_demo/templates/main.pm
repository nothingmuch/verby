
package [% c.perl_module_namespace %];

use strict;
use warnings;

our $VERSION = '0.01';

use IOC::Registry;

use base 'EERS::main';

use generics inherit => 'EERS::main';

our $DISPATCH_KEY = 'path_info';

1;

__END__

=head1 NAME

[% c.perl_module_namespace %] - [% c.perl_module_namespace %] EERS (Employee Engagement Reporting System)

=head1 SYNOPSIS

  use [% c.perl_module_namespace %];

=head1 DESCRIPTION

=head1 SUPER CLASS

=over 4

=item B<EERS::main>

=back

=head1 DISPATCH KEY

I<path_info>

=head1 SUB REQUEST HANDLERS

=over 4

=item B<>

=back

=head1 TEMPLATES USED

=over 4

=item B<>

=back

=head1 CODE COVERAGE

We use B<Devel::Cover> to test the code coverage of my tests, please see the L<Premier> module for more information.

=head1 SEE ALSO

=head1 AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

=cut
