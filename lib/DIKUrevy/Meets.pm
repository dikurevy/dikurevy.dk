package DIKUrevy::Meets;
use Mojo::Base -base;
use utf8::all;

use DIKUrevy::Meets::Meeting;

use Mojo::File;
use Mojo::JSON qw/from_json/;

=head1 NAME

DIKUrevy::Meets - Parses the DIKUrevy Meets calendar data.

=head1 SYNOPSIS

 my $meets = DIKUrevy::Meets->load_from_dir( $data_directory );

=cut

has 'meetings';
has 'users';

sub load_from_dir {
    my ($class, $data_directory) = @_;

    my $path = Mojo::File::path($data_directory)->make_path;

    my $meetings_data = from_json( $path->child('meetings.json')->slurp );
    my $users_data    = from_json( $path->child('users.json')->slurp );

    my $meetings = [
        map { DIKUrevy::Meets::Meeting->from_data( $_, $meetings_data->{$_} ) } (keys %$meetings_data)
    ];

    return DIKUrevy::Meets->new( meetings => $meetings, users => $users_data );
}

sub upcoming_meetings {
    my $self = shift;

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    my $today = sprintf("%04d-%02d-%02d", $year+1900, $mon+1, $mday);

    my @active = sort { $a->date cmp $b->date }
                 grep { $_->date ge $today } @{ $self->meetings };

    return @active;
}

1;

