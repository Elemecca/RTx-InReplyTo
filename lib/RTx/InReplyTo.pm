use strict;
use warnings;

package RTx::InReplyTo;

=head1 NAME

RTx::InReplyTo - match email to ticket based on In-Reply-To header

=head1 DESCRIPTION

=cut

require RT::Interface::Email;

{
    my $super = RT::Interface::Email->can( 'ExtractTicketId' )
        or die "RTx::InReplyTo requires at least RT 4.0.7";

    no warnings qw( redefine );

    *RT::Interface::Email::ExtractTicketId = sub {
        my $entity = shift;

        my $prev = $super->( $entity );
        return $prev if $prev
            and RT->Config->Get( 'InReplyTo_TrustPrev' );

        # extract message IDs from the headers we're configured to use
        # they come out in descending order of priority
        my @references =
            grep length,
            map { s/^<(.*?)>$/$1/o }
            map { split /\s+/m, $_ }
            grep defined,
            map { $entity->head->get( $_ ) }
            RT->Config->Get( 'InReplyTo_Headers' );

        unless (@references) {
            # we didn't find any references in the headers
            # use the ticket from the previous extractor
            return $prev;
        }

        # run the query with the system user as we want to find the
        # best match; the gateway will make a permissions check
        my $query = RT::Attachments->new( $RT::SystemUser );
        $query->Limit(
            ENTRYAGGREGATOR => 'AND',
            FIELD           => 'MessageId',
            OPERATOR        => 'IN',
            VALUE           => @references,
        );
        $query->Limit(
            ENTRYAGGREGATOR => 'AND',
            ALIAS           => $query->TransactionAlias(),
            FIELD           => 'ObjectType',
            VALUE           => 'RT::Ticket',
        );

        my $prefer_match = RT->Config->Get( 'InReplyTo_PreferPrev' );
        my %matches;

        while (my $attachment = $query->Next) {
            my $ticket = $attachment->TransactionObj->ObjectId;

            if ($prefer_match and $ticket eq $prev) {
                # this reference matches the previous extractor
                # that probably means it's the right one
                return $prev;
            }

            # there isn't a unique constraint on MessageId
            # we could potentially get multiple tickets for the same
            # reference, so we keep them in an array and check later
            push( $matches{ $attachment->MessageId } ||= [], $ticket );
        }

        for my $reference (@references) {
            my $tickets = $matches{ $reference };
            if (@$tickets > 1) {
                RT->Logger->warning(
                    "RTx::InReplyTo ignoring duplicated Message-ID"
                    . " <$reference> attached to tickets "
                    . join( ', ', @$tickets )
                );
            } elsif (@$tickets) {
                return $$tickets[ 0 ];
            }
        }

        # we didn't find a ticket in the references
        # use the ticket from the previous extractor
        return $prev;
    };
}

=head1 AUTHORS

    Sam Hanes <sam@maltera.com>

=cut

1;
