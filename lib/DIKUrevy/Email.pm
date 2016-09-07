package DIKUrevy::Email;
use Mojo::Base -base;
use utf8;

use Email::Stuffer;

sub send_mail {
    my $self = shift;
    my %args = @_;

    my $email = Email::Stuffer->to($args{to})
                              ->from('DIKUrevy-webside-botten <website@dikurevy.dk>')
                              ->html_body($args{body})
                              ->subject($args{subject});

    $email = $email->header('Reply-To', $args{reply_to}) if ($args{reply_to});

    $email->send;
}


1;

