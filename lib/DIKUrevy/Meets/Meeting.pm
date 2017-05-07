package DIKUrevy::Meets::Meeting;
use Mojo::Base -base;
use utf8::all;

has 'date';
has 'data';


sub from_data {
    my ($class, $date, $data) = @_;

    return $class->new( date => $date, data => $data);
}

sub attendees {
    my ($self) = @_;

    my @attendees;
    for my $user (values %{ $self->data->{users} }) {
        if ( grep { $_->{attending} } (values %{ $user->{schedule} }) ) {
            push( @attendees, $user );
        }
    }

    return \@attendees;
}

sub title { return shift->data->{title}; }

sub url {
    my ($self) = @_;

    return sprintf("http://møder.dikurevy.dk/?meeting=" . $self->date);
}

sub short_date {
    my $self = shift;

    my ($y,$m,$d) = $self->date =~ m/^(\d{4})-(\d{2})-(\d{2})$/;
    return "$d/$m";
}


1;

