# See bottom of file for license and copyright information
package Foswiki;

use strict;
use warnings;

use Unicode::Normalize;

BEGIN {
    if ( $Foswiki::cfg{UseLocale} ) {
        require locale;
        import locale();
    }
}

sub USERLIST {
    my ( $this, $params ) = @_;
    my $format = $params->{format} || '$wikiname';
    my $limit  = $params->{limit}  || 0;
    my $filter = $params->{_DEFAULT};
    my $separator = $params->{separator};
    $separator = ', ' unless defined $separator;
    my $header = $params->{header};
    $header = '' unless defined $header;
    my $footer = $params->{footer};
    $footer = '' unless defined $footer;
    my $casesensitive =
      ( Foswiki::isTrue( $params->{casesensitive} ) ) ? '' : '(?i)';
    my $checkaccess = 0;
    my $session     = $Foswiki::Plugins::SESSION;

    if ( defined $Foswiki::cfg{FeatureAccess}{USERLIST}
        && $Foswiki::cfg{FeatureAccess}{USERLIST} ne 'all' )
    {
        if ( $Foswiki::cfg{FeatureAccess}{USERLIST} eq 'admin' ) {
            return '' unless ( $this->{users}->isAdmin( $this->{user} ) );
        }
        elsif ( $Foswiki::cfg{FeatureAccess}{USERLIST} eq 'authenticated' ) {
            return '' unless $session->inContext("authenticated");
        }
        else {
            # Must be "acl" access, but don't check admins..
            $checkaccess = 1
              unless ( $this->{users}->isAdmin( $this->{user} ) );
        }
    }

    my $excludeTopics =
      Foswiki::convertTopicPatternToRegex( $params->{exclude} )
      if ( $params->{exclude} );

    my $it = $Foswiki::Plugins::SESSION->{users}->eachUser();
    $it->{process} = sub {
        return $Foswiki::Plugins::SESSION->{users}->getWikiName( $_[0] );
    };

    my @users;

    while ( $it->hasNext() ) {
        my $user = $it->next();
        if ( length($filter) ) {
            next unless ( $user =~ m/$casesensitive$filter/ );
        }
        if ( defined $excludeTopics ) {
            next if $user =~ m/$casesensitive$excludeTopics/;
        }
        push @users, $user;
    }

    return '' unless scalar @users;

    my $count   = 0;
    my $results = $header;
    foreach my $user ( sort { NFKD($a) cmp NFKD($b) } @users ) {
        $count++;
        last if ( $limit && $count > $limit );
        if ($checkaccess) {
            if ( $session->topicExists( $Foswiki::cfg{UsersWebName}, $user ) ) {
                my $userto =
                  Foswiki::Meta->load( $session, $Foswiki::cfg{UsersWebName},
                    $user );
                next unless $userto->haveAccess('VIEW');
            }
        }

        my $temp = $format;
        $temp =~ s/\$wikiname/$user/g;
        $results .= $temp;
        $results .= $separator if ($separator);
    }
    $results = substr( $results, 0, -length($separator) ) if length($separator);
    $results .= $footer;

    return Foswiki::expandStandardEscapes($results);
}

1;
__END__
Foswiki - The Free and Open Source Wiki, http://foswiki.org/

Copyright (C) 2008-2017 Foswiki Contributors. Foswiki Contributors
are listed in the AUTHORS file in the root of this distribution.
NOTE: Please extend that file, not this notice.

Additional copyrights apply to some or all of the code in this
file as follows:

Copyright (C) 1999-2007 Peter Thoeny, peter@thoeny.org
and TWiki Contributors. All Rights Reserved. TWiki Contributors
are listed in the AUTHORS file in the root of this distribution.
Based on parts of Ward Cunninghams original Wiki and JosWiki.
Copyright (C) 1998 Markus Peter - SPiN GmbH (warpi@spin.de)
Some changes by Dave Harris (drh@bhresearch.co.uk) incorporated

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version. For
more details read LICENSE in the root of this distribution.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

As per the GPL, removal of this notice is prohibited.
