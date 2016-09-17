package DIKUrevy::Website::Controller::Auth;
use Mojo::Base 'Mojolicious::Controller';
use utf8;
use Try::Tiny;

use DIKUrevy::Email;

use Mojo::Template;
use Mojo::JWT;


my $_email_match = qr/^.*\@.*$/;

sub login {
    my $self = shift;
    return $self->render('auth/login');
}

sub login_submit {
    my $self = shift;

    my $v = $self->validation;
    $v->required('username');
    $v->required('password');

    if ($v->has_error || $v->csrf_protect->has_error('csrf_token')) {
        $self->show_error('Udfyld både navn og løsen.');
        return $self->login();
    }

    unless ($self->helpers->authenticate( $v->output->{username}, $v->output->{password} )) {
        $self->show_error('Ugyldigt login.');
        return $self->login();
    }


    return $self->redirect_to('frontpage');
}

sub logout {
    my $self = shift;
    $self->helpers->logout;
    return $self->redirect_to('frontpage');
}

sub create_user {
    my $self = shift;
    return $self->render('auth/create_user');
}

sub _user_validator {
    my $self = shift;

    my $v = $self->validation;
    $v->required($_) for qw/username password realname phone/;
    $v->required('email')->like($_email_match);

    return $v;
}

sub create_user_submit {
    my $self = shift;

    my $v = $self->_user_validator();

    if ($v->has_error || $v->csrf_protect->has_error('csrf_token')) {
        $self->show_error('Fejl i formularen.');
        return $self->create_user();
    }

    my $user = DIKUrevy::User->retrieve( { username => $v->output->{username} } );
    if ($user) {
        $self->show_error('Brugernavnet er allerede taget.');
        return $self->create_user();
    }

    $user = DIKUrevy::User->retrieve( { email => $v->output->{email} } );
    if ($user) {
        $self->show_error('Emailadressen er allerede taget.');
        return $self->create_user();
    }

    $user = DIKUrevy::User->new( %{ $v->output } );
    $user->set_password($self->param('password'));
    $user->save;

    my $mail = $self->render_to_string(template => 'auth/mail_created', user => $user, layout => undef)->to_string;
    DIKUrevy::Email->send_mail(
        to      => $self->config('admin_mail'),
        subject => 'Ny bruger oprettet på websiden: ' . $user->username,
        body    => $mail,
    );

    $self->show_message('Din bruger er oprettet, men skal først bekræftes af revybosserne. Når dette er sket vil du få en mail.', flash => 1);
    return $self->redirect_to('frontpage');
}

sub new_password {
    my $self = shift;

    return $self->render('auth/new_password');
}

sub new_password_submit {
    my $self = shift;

    my $v = $self->validation;
    $v->required('email_address')->like($_email_match);

    if ($v->has_error || $v->csrf_protect->has_error('csrf_token')) {
        $self->show_error('Udfyld email-adresse.');
        return $self->new_password();
    }

    my $user = DIKUrevy::User->retrieve( { email => $v->output->{email_address} } );
    if ($user) {
        my $secret = $self->config('secrets')->[0];
        my $in_one_day = time() + 60 * 60 * 24;
        my $jwt = Mojo::JWT->new(secret => $secret,
                                 expires => $in_one_day,
                                 claims => {id => $user->id})->encode;

        my $mail = $self->render_to_string(template => 'auth/new_password_email',
                                           jwt => $jwt,
                                           layout => undef)->to_string;
        DIKUrevy::Email->send_mail(
            to      => $v->output->{email_address},
            subject => "Nyt løsen til dikurevy.dk",
            body    => $mail,
            );
    }

    # Show this message even if the email address is invalid, to defend against
    # targeted data extraction.
    $self->show_message('Vi har sendt dig instruktioner til at lave et nyt løsen.',
                        flash => 1);
    return $self->redirect_to('frontpage');
}

sub login_with_token {
    my $self = shift;

    my $jwt = $self->req->query_params->param('jwt');
    if ($jwt) {
        my $secret = $self->config('secrets')->[0];
        my $claims;
        try {
            $claims = Mojo::JWT->new(secret => $secret)->decode($jwt);
            $self->authenticate(undef, undef, { auto_validate => $claims->{id} });
            $self->show_message('Du er nu logget ind og kan sætte dit nye løsen.',
                                flash => 1);
            $self->redirect_to('edit_user')
        } catch {
            $self->show_error('Ugyldigt løsen-link.', flash => 1);
            return $self->redirect_to('frontpage');
        };
    }
    else {
        return $self->redirect_to('frontpage');
    }
}

sub edit_user {
    my $self = shift;
    my $user = $self->current_user;
    for my $f (qw/username password realname phone email/) {
        $self->param($f, $user->$f) if (! $self->param($f) && $user->$f);
            $self->param($f, $user->$f) if (! $self->param($f) && $user->$f);}
    return $self->render('auth/edit_user');
}

sub edit_user_submit {
    my $self = shift;

    my $v = $self->_user_validator();

    if ($v->has_error || $v->csrf_protect->has_error('csrf_token')) {
        $self->show_error('Fejl i formularen.');
        return $self->edit_user();
    }

    my $user = $self->current_user;
    for my $f (qw/username realname phone email/) {
        $user->$f( $self->param($f) ) if defined($self->param($f));
    }

    $user->set_password($self->param('password'));

    $user->save();

    $self->show_message('Din bruger er hermed opdateret.', flash => 1);
    $self->redirect_to('edit_user');
}

1;
