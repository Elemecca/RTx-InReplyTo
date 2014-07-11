package RTx::InReplyTo;

#############################  WARNING  #############################
#                                                                   #
#                       NEVER EDIT THIS FILE                        #
#                                                                   #
#         Instead, copy any sections you want to change to          #
#         RT_SiteConfig.pm and edit them there.  Otherwise,         #
#         your changes will be lost when you upgrade RT.            #
#                                                                   #
#############################  WARNING  #############################

=head1 RTx::InReplyTo configuration

=over 4

=item C<$InReplyTo_TrustPrev>

Boolean, default on. When enabled, if the previous extractor found
a ticket ID InReplyTo will use it without considerint its headers.
Disable this if a ticket found from the headers should win over one
found from the previous extractor when they're different.

=cut

Set( $InReplyTo_TrustPrev, 1 );


=item C<$InReplyTo_PreferPrev>

Boolean, default on. When enabled, if the previous extractor found
a ticket ID and it matches any ticket found from the headers it will
be chosen regardless of header order. Otherwise the first ticket found
from the headers will always be used and the ticket found by the
previous extractor will be ignored unless none is found in the headers.

=cut

Set( $InReplyTo_PreferPrev, 1 );


=item C<@InReplyTo_Headers>

Array of strings, default C<In-Reply-To> and C<References>. The list of
headers containing message IDs that should be used to look for tickets.

=cut

Set( @InReplyTo_Headers, qw/ In-Reply-To References / );

=back
=cut
1;
