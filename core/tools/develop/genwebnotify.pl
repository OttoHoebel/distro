#!/usr/bin/env perl
# Author: Crawford Currie http://c-dot.co.uk
#
# Generates WebNotify from the WaitingFor and ReportedBy fields
#
use strict;
use warnings;

my $ROOT = '/var/www/trunk.foswiki.org';
my $PROD = '/var/www/foswiki.org';

my $where = "$PROD/data/Tasks";
my $text =
`cd $ROOT/core/bin && perl ./view topic="Tasks.GenerateWebNotify" -skin text -contenttype text/plain`;
my %topics;
foreach my $line ( split( /\r?\n/, $text ) ) {
    $line =~ s#(TWiki:)?Main[./]##g;
    if ( $line =~ /^(.*):(.*)$/ ) {
        my ( $names, $topic ) = ( $1, $2 );
        foreach my $name ( split( /[,;\s]+/, $names ) ) {
            if ( $name =~ /^[A-Z]+[a-z]+[A-Z]/ ) {
                $topics{$name}{$topic} = 1;
            }
        }
    }
}
if ( open( F, '<', "$where/DontBugMe.txt" ) ) {
    local $/ = "\n";
    while (<F>) {
        $_ =~ s#(TWiki:)?Main[./]##g;
        next unless $_ =~ /^\s*\* ([A-Z]+[a-z]+[A-Z]\w+)\s*$/;
        delete $topics{$1};
    }
    close(F);
}
open( F, '>', "$where/WebNotify.txt" ) || die "Can't open $where/WebNotify: $!";
print F <<GUFF;
<!--
   * Set NOAUTOLINK = on
-->
This topic is automatically generated by a script running on the server. The
script analyses all the 'WaitingFor' and 'ReportedBy' fields in reports and
generates this WebNotify.

*Don't waste your time trying to edit this topic; you can't.*
You can exclude yourself from all notification by adding yourself to the topic
[[DontBugMe]].

GUFF
foreach my $name ( sort keys %topics ) {
    print F "   * $name: ", join( ' ', sort( keys %{ $topics{$name} } ) ), "\n";
}
close(F);
