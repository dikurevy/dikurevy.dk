package DIKUrevy::Website::Controller::Website;
use Mojo::Base 'Mojolicious::Controller';

use DIKUrevy::User;

sub index   { return shift->render('website/index');   }
sub tickets { return shift->render('website/tickets'); }
sub media   { return shift->render('website/media');   }
sub posters { return shift->render('website/posters'); }
sub join_us { return shift->render('website/join_us'); }
sub contact { return shift->render('website/contact'); }

sub phone_dir {
    my $self = shift;

    my $users = DIKUrevy::User->fetch( { verified => 1, order => 'realname ASC' } );
    $self->stash( users => $users );
    $self->render( 'website/phone_dir' );
}

1;

