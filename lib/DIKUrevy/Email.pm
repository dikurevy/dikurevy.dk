package DIKUrevy::Email;
use Mojo::Base -base;
use utf8;

use Email::Stuffer;
use HTML::FormatText;

sub send_mail {
    my $self = shift;
    my %args = @_;

    my $text = $args{body_text} // HTML::FormatText->format_string($args{body});

    my $email = Email::Stuffer->to($args{to})
                              ->from('DIKUrevy-webside-botten <website@dikurevy.dk>')
                              ->text_body($text)
                              ->html_body($args{body})
                              ->subject($args{subject});

    $email = $email->header('Reply-To', $args{reply_to}) if ($args{reply_to});

    $email->send;
}


1;

