#!/usr/bin/perl

package Config::Source::XML;

use strict;
use warnings;

our $VERSION = '0.01';

use XML::SAX::ParserFactory;

sub new {
    my $class = shift;
    return bless { _config => undef }, ref($class) || $class;
}

sub load {
    my ($self, $file) = @_;
    (-e $file && -f $file)
        || die "Bad config file '$file' either it doesn't exist or it's not a file";    
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

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->{_config}           = undef;
    $self->{_in_main_config}   = undef;
    $self->{_in_steps}         = undef;
    $self->{_current_node}     = [];
    $self->{_current_tag_name} = undef;
    $self->{_current_step}     = undef;
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
            ($key => $el->{Attributes}->{$_}->{Value})
        }
        keys %{$el->{Attributes}};        
}

## <config> utility functions

sub _config_init {
    my ($self) = @_;
    # enter the main config ...
    $self->{_in_main_config} = 1;   # set the flag
    $self->{_config}->{conf} = {};  # init the hash node
    # ... and add it to our context
    push @{$self->{_current_node}}, $self->{_config}->{conf};     
}

sub _config_start {
    my ($self, $tag_name) = @_;
    if (defined $self->{_current_tag_name}) {
        # init a hash node
        my $node = {}; 
        # link it to the structure
        $self->{_current_node}->[-1]->{$self->{_current_tag_name}} = $node; 
        # push it onto the current context
        push @{$self->{_current_node}} => $node;
    }
    # record the current tag name
    $self->{_current_tag_name} = $tag_name;      
}

sub _config_end {
    my ($self, $tag_name) = @_;
    if (defined $self->{_current_tag_name} && $self->{_current_tag_name} eq $tag_name) {
        # clear our current tag ...
        $self->{_current_tag_name} = undef;    
    }
    else {
        # exit the current context
        pop @{$self->{_current_node}};
    }     
}

sub _config_characters {
    my ($self, $data) = @_;
    (defined $self->{_current_tag_name} && @{$self->{_current_node}})
        || die "we should always have a current tag and some context"; 
    $self->{_current_node}->[-1]->{$self->{_current_tag_name}} = $data;    
}

sub _config_cleanup {
    my ($self) = @_;
    $self->{_in_main_config} = 0; # turn off the flag
    $self->{_current_node} = [];  # clear the context
}

## <step> tags

sub _step_init {
    my ($self, $el) = @_;
    $self->{_in_steps} = 1;         # turn on the flag
    $self->{_config}->{steps} = []; # create a context
    push @{$self->{_current_node}} => $self->{_config}->{steps};        
}

sub _step_start {
    my ($self, $el) = @_;
    # create a new node
    my $node = { $self->_get_all_values($el), substeps => [] };   
    # if we are at the base of the steps ...
    if (ref($self->{_current_node}->[-1]) eq 'ARRAY') {
        push @{$self->{_current_node}->[-1]} => $node;         
    }
    # otherwise ...
    else {
        push @{$self->{_current_node}->[-1]->{substeps}} => $node; 
    }            
    push @{$self->{_current_node}}, $node;       
}

sub _step_end {
    my ($self, $el) = @_;
    my $val = pop @{$self->{_current_node}};   
    unless (@{$val->{substeps}}) {
        delete $val->{substeps};
    }
}

sub _step_characters {
    my ($self, $data) = @_;
    # nothing really happens here ...
}

sub _step_cleanup {
    my ($self, $el) = @_;
    $self->{_in_steps} = 0;       # turn off the flag
    $self->{_current_node} = [];  # clear the context    
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
