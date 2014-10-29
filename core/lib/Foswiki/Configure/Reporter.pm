# See bottom of file for license and copyright information
package Foswiki::Configure::Reporter;

use strict;
use warnings;

use Assert;

use JSON         ();
use Data::Dumper ();

# Number of levels of a stack trace to keep
use constant KEEP_STACK_LEVELS => 0;    #( (DEBUG) ? 2 : 0 );

=begin TML

---+ package Foswiki::Configure::Reporter

Report package for configure, supporting text reporting and
simple TML expansion to HTML.

This class doesn't actually handle expansion of TML to anything else;
it simply stores messages for processing by formatting back ends.
However it is a sensible place to define the subset of TML that is expected
to be supported by renderers.

   * Single level of lists (* and 1)
   * Blank line = paragraph break &lt;p /&gt;
   * &gt; at start of line = &lt;br&gt; before and after
     (i.e. line stands alone)
   * Simple tables | like | this |
   * Text styling e.g. <nop>*bold*, <nop>=code= etc
   * URL links [<nop>[http://that][text description]]
   * &lt;verbatim&gt;...&lt;/verbatim&gt;
   * HTML types =button=, =select=, =option= and =textarea= are supported
     for wizard inputs, if the renderer supports them. Non-interactive
     renderers should ignore them.
   * ---+++ Headings

Each of the reporting methods (NOTE, WARN, ERROR) accepts any number of
message parameters. These are treated as individual error messages, rather
than being concatenated into a single message. \n can be used in any
message, and it will survive into the final TML.

Most renderers will assume an implicit > at the front of every WARN and
ERROR message.

=cut

sub new {
    my ($class) = @_;

    my $this = bless( {}, $class );
    $this->clear();
    return $this;
}

=begin TML

---++ ObjectMethod NOTE(@notes) -> $this

Report one or more notes. Each parameter is handled as an independent
message. Returns the reporter to allow chaining.

=cut

sub NOTE {
    my $this = shift;
    push( @{ $this->{messages} }, map { { level => 'notes', text => $_ } } @_ );
    return $this;
}

=begin TML

---++ ObjectMethod WARN(@warnings)

Report one or more warnings. Each parameter is handled as an independent
message. Returns the reporter to allow chaining.

=cut

sub WARN {
    my $this = shift;
    push(
        @{ $this->{messages} },
        map { { level => 'warnings', text => $_ } } @_
    );
}

=begin TML

---++ ObjectMethod ERROR(@errors) -> $this

Report one or more errors. Each parameter is handled as an independent
message. Returns the reporter to allow chaining.

=cut

sub ERROR {
    my $this = shift;
    push( @{ $this->{messages} },
        map { { level => 'errors', text => $_ } } @_ );
    return $this;
}

=begin TML

---++ ObjectMethod CHANGED($keys) -> $this

Report that a =Foswiki::cfg= entry has changed. The new value will
be taken from the current value in =$Foswiki::cfg= at the time of
the call to CHANGED.

Example: =$reporter->CHANGED('{Email}{Method}')=

Returns the reporter to allow chaining.

=cut

sub CHANGED {
    my ( $this, $keys ) = @_;
    $this->{changes}->{$keys} = uneval( eval "\$Foswiki::cfg$keys" );
    return $this;
}

=begin TML

---++ ObjectMethod WIZARD($label, $data) -> $note

Generate a wizard button suitable for adding to the stream.
This should return '' if the reporter does not support wizards.
The default is to create an HTML button.

Caller is expected to add the result to the reporter stream using
NOTE etc.

=cut

sub WIZARD {
    my ( $this, $label, $data ) = @_;
    my $json = JSON->new->encode($data);
    $json =~ s/"/&quot;/g;
    return
      "<button class=\"wizard_button\" data-wizard=\"$json\">$label</button>";
}

=begin TML

---++ ObjectMethod has_level( $level ) -> $boolean

Return true if the reporter has seen at least one $level message, where
$level is one of notes, warnings or errors.

=cut

sub has_level {
    my ( $this, $level ) = @_;
    foreach my $m ( @{ $this->{messages} } ) {
        return 1 if ( $m->{level} eq $level );
    }
    return 0;
}

=begin TML

---++ ObjectMethod clear() -> $this

Clear all contents from the reporter.
Returns the reporter to allow chaining.

=cut

sub clear {
    my $this = shift;
    $this->{messages} = [];
    $this->{changes}  = {};
    return $this;
}

=begin TML

---++ ObjectMethod messages() -> \@messages

Get the content of the reporter. @messages is an ordered array of hashes,
each of which has fields:
   * level: one of errors, warnings, notes
   * text: text of the message
Each message corresponds to a single parameter to one of the ERROR,
WARN or NOTES methods.

=cut

sub messages {
    my ($this) = @_;

    return $this->{messages};
}

=begin TML

---++ ObjectMethod changes() -> \%changes

Get the content of the reporter. %changes is a hash mapping a key
to a (new) value. Each entry corresponds to a call to the CHANGED
method (though multiple calls to CHANGED with the same keys will
only result in one entry).

=cut

sub changes {
    my ($this) = @_;

    return $this->{changes};
}

=begin TML

---++ StaticMethod uneval($datum [, $indent]) -> $string

Serialise the perl datum $datum as a perl string that can be
evalled to recover the original value.

$indent can be used to override the default setting (0) for
$Data::Dumper::Indent. See perldoc Data::Dumper for more information.

=cut

sub uneval {
    my ( $datum, $indent ) = @_;
    local $Data::Dumper::Sortkeys = 1;
    local $Data::Dumper::Terse    = 1;
    local $Data::Dumper::Indent   = $indent || 0;
    my $d = Data::Dumper->Dump( [$datum] );
    $d =~ s/^\$VAR1\s*=\s*//s;
    $d =~ s/;\s*$//s;
    return $d;
}

=begin TML

---++ StaticMethod ellipsis($string, $limit) -> $string

If $string exceeds $limit in length, truncate the string to
$limit-3 characters and append ellipsis (...)

=cut

sub ellipsis {
    my ( $string, $limit ) = @_;
    if ( length($string) > $limit - 3 ) {
        $string = substr( $string, 0, $limit - 3 ) . '...';
    }
    return $string;
}

=begin TML

---++ StaticMethod stripStacktrace($stacktrace) -> $message

Strip traceback from die and carp for a user message

=cut

sub stripStacktrace {
    my ($message) = @_;

    return '' unless ( length $message );

    my @lines = split( /\n/, $message );
    splice( @lines, KEEP_STACK_LEVELS + 1 );
    return join(
        "\n",
        map {
            $_ =~ s/ at .*? line \d+\.?$//;
            $_;
        } @lines
    );
}

1;
__END__
Foswiki - The Free and Open Source Wiki, http://foswiki.org/

Copyright (C) 2014 Foswiki Contributors. Foswiki Contributors
are listed in the AUTHORS file in the root of this distribution.
NOTE: Please extend that file, not this notice.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version. For
more details read LICENSE in the root of this distribution.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

As per the GPL, removal of this notice is prohibited.
