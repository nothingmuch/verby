
package Interfaces;

use strict;
use warnings;

use Class::Interfaces (
    'Visitor'    => [ 'visit' ],
    'Visitable'  => [ 'accept' ],
        
    'Dependency' => {
        isa      => 'Visitable',
        methods  => [ 'dependents', 'depends_on', 'add_action', 'actions', 'is_satisfied' ]
        },
        
    'Action'     => [ 'perform', 'verify' ],
    'Context'    => [ 'get', 'set' ],
    );
    
1;

__END__

=pod

=head1 NAME

Interfaces - A set of Interfaces for this framework

=head1 SYNOPSIS

    my $dep1 = Dependency->new();
    $dep1->add_action(Action->new(
        perform => sub { 
            mkdir('var/www');
        },
        verify  => sub { -e 'var' && -d 'var' && -e 'var/www' && -d 'var/www' }
    ));

    my $dep2 = Dependency->new();
    $dep2->add_action(Action->new(
        perform => sub { 
            chdir('var/www/'); # assume that this exists because
                               # we are dependant upon it                         
            open(FILE, ">", "index.html") || die "cannot open file : $!";
            print FILE "<HTML><BODY><H1>Hello World</H1></BODY></HTML>"
            close(FILE);
        },
        verify  => sub { -e 'index.html' && -f 'index.html' && -s 'index.html' }
    ));
    $dep2->depends_on($dep1);

    $dep2->depends_on(); # returns $dep
    $dep1->dependents() # returns [ $dep2 ]

    my $v = Visitor->new(sub {
        my ($self, $dep) = @_;
        # perform all of the 
        # actions in the current
        # dependent
        foreach my $a ($dep->actions()) {
            $a->perform();
            # we could warn, we could die, it all
            # depends upon our application
            $a->verify() || warn "could not verify $a";
        }
        # now that all the actions have been performed
        # we can now process our dependents
        foreach my $sub_dep ($dep->depenents()) {
            # we traverse the tree, passing the
            # visitor so that it will perform this
            # action recursively
            $sub_dep->accept($self);
        }
    });

    $dep1->accept($v);

=head1 DESCRIPTION

This file defines two interfaces.

=head1 INTERFACES

=head2 Dependency

=over 4

=item B<dependents>

A B<Dependency> object can have other B<Dependency> objects which depend upon it. This method will return a list of direct dependents.

In parent-child parlance, this will return a list of this objects children.

=item B<depends_on (?$dependency)>

A B<Dependency> object itself may be dependent upon other B<Dependency> object. If C<$dependency> is passed to this method, then the invocant becomes a dependant of C<$dependency>. If no C<$dependency> is passed, then this will return the object which the invocant depends upon (if it exists).

In parent-child parlance, this will return a this objects parent.

=item B<add_action>

A B<Dependency> object may itself contain a number of B<Action> objects. This method allows the addition of these actions.

=item B<actions>

This returns all the B<Action> objects this B<Dependency> has.

=item B<is_satisfied>

This method will determine if this B<Dependency> has been satisifed. It does this by calling C<verify> on all of its  B<Action> objects.

=back

=head2 Action

=over 4

=item B<perform (?$context)>

This will perform the action specified, it can potentially take a C<$context> object.

=item B<verify>

This will verify that the action has been performed correctly.

=back

=head2 Context

A B<Context> object is just a simple scratch-pad to be held by B<Visitor> objects, and passed to B<Action> objects. It allows the B<Visitor> to keep notes for itself.

=over 4

=item B<get>

=item B<set>

=back

Actions do not have pre-conditions. It is assumed that the Dependency container takes care of the environment.

=head1 AUTHORS

Stevan Little E<gt>stevan@iinteractive.comE<lt>

=cut