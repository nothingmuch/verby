
package Interfaces;

use strict;
use warnings;

use Class::Interfaces (
    'Visitor'   => [ 'visit' ],
    'Visitable' => [ 'accept' ],
        
    'Step'      => {
        isa     => 'Visitable',
        methods => [ 'dependents', 'depends_on', 'add_action', 'actions', 'is_satisfied' ]
        },
        
    'Action'    => [ 'do', 'verify' ],

	'Config::Data' => [ qw/get derive data parent AUTOLOAD/ ],
	'Config::Data::Mutable' => [ qw/set AUTOLOAD/ ],
	
    'Context'   => { # shadows the Config::Hub or the global context
		isa => 'Config::Data::Mutable',
	},
	
	'Config::Hub' => { # shadows all the Config::Source objects
		isa => 'Config::Data',
		methods => qw/sources/, # Module::Pluggable::Ordered
	},

	'Config::Source' => {
		isa => 'Config::Data',
		methods => qw/extract/, # like get but only once
	},
    );
    
1;

__END__

=pod

=head1 NAME

Interfaces - A set of Interfaces for this framework

=head1 SYNOPSIS

    my $step1 = Step->new();
    $step1->add_action(Action->new(
        perform => sub { 
            mkdir('var/www');
        },
        verify  => sub { -e 'var' && -d 'var' && -e 'var/www' && -d 'var/www' }
    ));

    my $step1_1 = Step->new();
    $step1_1->add_action(Action->new(
        perform => sub { 
            chdir('var/www/'); # assume that this exists because
                               # we are dependant upon it                         
            open(FILE, ">", "index.html") || die "cannot open file : $!";
            print FILE "<HTML><BODY><H1>Hello World</H1></BODY></HTML>"
            close(FILE);
        },
        verify  => sub { -e 'index.html' && -f 'index.html' && -s 'index.html' }
    ));
    $step1_1->depends_on($step1);

    $step1_1->depends_on(); # returns $step1
    $step1->dependents() # returns [ $step1_1 ]

    my $v = Visitor->new(sub {
        my ($self, $dep) = @_;
        # perform all of the 
        # actions in the current
        # dependent
        foreach my $a ($dep->actions()) {
            $a->do();
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

    $step1->accept($v);

=head1 DESCRIPTION

This file defines two interfaces.

=head1 INTERFACES

=head2 Step

=over 4

=item B<dependents>

A B<Step> object can have other B<Step> objects which depend upon it. This method will return a list of direct dependents.

In parent-child parlance, this will return a list of this objects children.

=item B<depends_on (?$dependency)>

A B<Step> object itself may be dependent upon other B<Step> object. If C<$dependency> is passed to this method, then the invocant becomes a dependant of C<$dependency>. If no C<$dependency> is passed, then this will return the object which the invocant depends upon (if it exists).

In parent-child parlance, this will return a this objects parent.

=item B<add_action>

A B<Step> object may itself contain a number of B<Action> objects. This method allows the addition of these actions.

=item B<actions>

This returns all the B<Action> objects this B<Step> has.

=item B<is_satisfied>

This method will determine if this B<Step> has been satisifed. It does this by calling C<verify> on all of its  B<Action> objects.

=back

=head2 Action

=over 4

=item B<do (?$context)>

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

Actions do not have pre-conditions. It is assumed that the Step container takes care of the environment.

=head1 AUTHORS

Stevan Little E<gt>stevan@iinteractive.comE<lt>

=cut
