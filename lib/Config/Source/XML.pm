#!/usr/bin/perl

package Config::Source::XML;

use strict;
use warnings;

our $VERSION = '0.01';

use XML::SAX::ParserFactory;
use Carp qw/croak/;

sub new {
    my $class = shift;
    return bless { _config => undef }, ref($class) || $class;
}

sub load {
    my ($self, $file) = @_;
    (-e $file && -f $file)
        || croak "Bad config file '$file' either it doesn't exist or it's not a file";    
    my $handler = Config::Source::XML::SAX::Handler->new();
    my $p = XML::SAX::ParserFactory->parser(Handler => $handler);
    $p->parse_uri($file);
    $self->{_config} = $handler->config();
}

sub config { (shift)->{_config} }

package Config::Source::XML::SAX::Handler;

use strict;
use warnings;

our $VERSION = '0.01';

use base 'XML::SAX::Base';

use Carp qw/croak/;
use Array::RefElem qw/hv_store av_push/;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->{_config}           = undef;
    $self->{_in_main_config}   = undef;
    $self->{_in_steps}         = undef;
    $self->{_node_stack}       = [];
    return $self;
}

sub config { (shift)->{_config} }

sub start_element {
    my ($self, $el) = @_;
    my $tag_name = lc($el->{Name});
    if ($tag_name eq 'installer') {
        $self->{_config} = {} unless $self->{_config};    
    }
    elsif ($tag_name eq 'config') {
        $self->_config_init();
    }
    # we are in the main config ...
    elsif ($self->{_in_main_config}) {
        $self->_config_start($tag_name);    
    }
    elsif ($tag_name eq 'steps') {
        $self->_step_init();
    }
    elsif ($self->{_in_steps} && $tag_name eq 'step') {
        $self->_step_start($el);
    }
    else {
        warn "I dont recognize the opening tag '$tag_name'";
    }
}

sub end_element {
    my ($self, $el) = @_;
    my $tag_name = lc($el->{Name});
    if ($tag_name eq 'installer') {
        ;
    } 
    elsif ($tag_name eq 'config') {
        $self->_config_cleanup();
    }  
    elsif ($self->{_in_main_config}) {
        $self->_config_end($tag_name);   
    } 
    elsif ($tag_name eq 'steps') {
        $self->_step_cleanup();
    }
    elsif ($self->{_in_steps} && $tag_name eq 'step') {
        $self->_step_end($el);
    }
    else {
        warn "I dont recognize the closing tag '$tag_name'";    
    }
}

sub characters {
    my ($self, $el) = @_;
    my $data = $el->{Data};
    return if $data =~ /^\s+$/;
    if ($self->{_in_main_config}) {
        $self->_config_characters($data);
    }
    elsif ($self->{_in_steps}) {
        $self->_step_characters($data);
    }
}

sub _get_value {
    my ($self, $el, $key) = @_;
    return undef unless exists $el->{Attributes}->{'{}' . $key};
    return $el->{Attributes}->{'{}' . $key}->{Value};        
}

sub _get_all_values {
    my ($self, $el) = @_;
    return map {
            my ($key) = /^\{\}(.*)$/;
			my $value = $el->{Attributes}->{$_}->{Value};
			$value =~ s/(?<!\\)\$(\{\w+\}|\w+)/$self->_fetch_config_var($1)/e;
            ($key => $value)
        }
        keys %{$el->{Attributes}};        
}

sub _fetch_config_var {
	my ($self, $var) = @_;
	$self->{_config}{conf}{$var};
}

## <config> utility functions

sub _config_init {
    my ($self) = @_;
    # enter the main config ...
    $self->{_in_main_config} = 1;   # set the flag
    $self->{_config}->{conf} = {};  # init the hash node
    # ... and add it to our context
    av_push(@{$self->{_node_stack}}, $self->{_config}->{conf});
}

sub _config_start {
    my ($self, $tag_name) = @_;

	# '<foo><bar>blah</bar> more text </foo>' is illegal
	defined and not ref and croak "Node can't contain both text and sub elements" for $self->{_node_stack}[-1];

	# put the same node  both on the stack, *and* in the right place in the structure
	# note that setting the last element on the stack will also set the thing in the structue, since we are aliasing
	my $node; # this is a new container
	hv_store(%{ $self->{_node_stack}[-1] }, $tag_name, $node); # the same contaner (not value) is put in both the hash
	av_push(@{ $self->{_node_stack} }, $node); # and the last node of the array
}

sub _config_end {
    my ($self, $tag_name) = @_;
    pop @{$self->{_node_stack}};
}

sub _config_characters {
    my ($self, $data) = @_;
	$self->{_node_stack}->[-1] = $data; # since we aliased the structure's node will also be set. See above
}

sub _config_cleanup {
    my ($self) = @_;
    $self->{_in_main_config} = 0; # turn off the flag
    $self->{_node_stack} = [];  # clear the context
}

## <step> tags

sub _step_init {
    my ($self, $el) = @_;
    $self->{_in_steps} = 1;         # turn on the flag
    $self->{_config}->{steps} = []; # create a context
    push @{$self->{_node_stack}} => { substeps => $self->{_config}->{steps} }; # the substeps of the root element are just the top level array.
}

sub _step_start {
    my ($self, $el) = @_;
    # create a new node
    my $node = { $self->_get_all_values($el), substeps => [] };   

    push @{$self->{_node_stack}[-1]{substeps}} => $node;
    push @{$self->{_node_stack}}, $node;
}

sub _step_end {
    my ($self, $el) = @_;
    my $val = pop @{$self->{_node_stack}};
	delete $val->{substeps} unless @{ $val->{substeps} };
}

sub _step_characters {
    my ($self, $data) = @_;
    # nothing really happens here ...
}

sub _step_cleanup {
    my ($self, $el) = @_;
    $self->{_in_steps} = 0;       # turn off the flag
    $self->{_node_stack} = [];  # clear the context    
}

__PACKAGE__

__END__

=pod

=head1 NAME

Config::Source::XML - 

=head1 SYNOPSIS

	use Config::Source::XML;

=head1 DESCRIPTION

=cut
