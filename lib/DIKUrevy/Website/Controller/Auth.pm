package DIKUrevy::Website::Controller::Auth;
use Mojo::Base 'Mojolicious::Controller';

use DIKUrevy::Email;

use Mojo::Template;

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
    $v->required('email')->like(qr/^.*\@.*$/);

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

    $user = DIKUrevy::User->new( %{ $v->output } );
    $user->save;

    my $mail = $self->render_to_string(template => 'auth/mail_created', user => $user, layout => undef)->to_string;
    DIKUrevy::Email->send_mail(
        to      => $self->config('admin_mail'),
        subject => "Ny bruger oprettet på websiden: " . $user->username,
        body    => $mail,
    );

    $self->show_message('Din bruger er oprettet, men skal først bekræftes af revybosserne. Når dette er sket vil du få en mail.', flash => 1);
    return $self->redirect_to('frontpage');
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

