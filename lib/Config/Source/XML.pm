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

package Config::Source::XML::SAX::Handler;

use strict;
use warnings;

our $VERSION = '0.01';

use base 'XML::SAX::Base';

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->{_config} = undef;
    return $self;
}

sub config { (shift)->{_config} }

sub start_element {
    my ($self, $el) = @_;
    my $tag_name = lc($el->{Name});
    if ($tag_name eq 'installer') {
        $self->{_config} = {} unless $self->{_config};    
    }
    else {
        die "I dont recognize the tag name '$tag_name'";
    }
}

sub _get_value {
    my ($self, $el, $key) = @_;
    return undef unless exists $el->{Attributes}->{'{}' . $key};
    return $el->{Attributes}->{'{}' . $key}->{Value};        
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
