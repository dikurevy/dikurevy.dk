package DIKUrevy::Website::Controller::Admin;
use Mojo::Base 'Mojolicious::Controller';

use DIKUrevy::Email;
use DIKUrevy::User;

sub index { shift->render('admin/index'); }

sub user_list {
    my $self = shift;

    my $users = DIKUrevy::User->fetch( { order => 'id DESC' } );
    $self->stash( users => $users );
    $self->render( 'admin/user_list' );
}

sub toggle_verified {
    my $self = shift;
    my $userid = $self->stash('userid');

    my $user = DIKUrevy::User->retrieve( { id => $userid } );
    $user->verified( $user->verified ? 0 : 1 );
    $user->save;

    my $mail = $self->render_to_string(template => 'auth/mail_confirmed', layout => undef)->to_string;
    DIKUrevy::Email->send_mail(
        to      => $user->email,
        subject => "Din bruger er hermed bekræftet på dikurevy.dk",
        body    => $mail,
    );

    $self->redirect_to('admin_user_list');
}

1;

