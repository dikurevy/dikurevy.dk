package DIKUrevy::Website::Controller::Website;
use Mojo::Base 'Mojolicious::Controller';
use utf8;

use DIKUrevy::Email;
use DIKUrevy::User;

sub index   { return shift->render('website/index');   }
sub tickets { return shift->render('website/tickets'); }
sub media   { return shift->render('website/media');   }
sub posters { return shift->render('website/posters'); }
sub join_us { return shift->render('website/join_us'); }
sub contact { return shift->render('website/contact'); }
sub harlem  { return shift->render('website/harlem');  }
sub git     {
    my $self = shift;

    $self->stash( hemmeligt_løsen => $self->config('hemmeligt_løsen') );

    return $self->render('website/git');
}

sub phone_dir {
    my $self = shift;

    my $users = DIKUrevy::User->fetch( { verified => 1, order => 'realname ASC' } );
    $self->stash( users => $users );
    $self->render( 'website/phone_dir' );
}

sub harlem_submit {
    my $self = shift;

    my $v = $self->validation;
    $v->required($_) for qw/full_name card_no end_date reason/;
    $v->required('email')->like(qr/^.*\@.*$/);

    if ($v->has_error || $v->csrf_protect->has_error('csrf_token')) {
        $self->show_error('Fejl i formularen.');
        return $self->harlem();
    }

    my %fields = map { $_ => $self->param($_) } qw/full_name card_no end_date reason email/;

    my $admin_mail = $self->render_to_string(
        template => 'website/harlem_mail',
        layout   => undef,
        %fields
    );

    DIKUrevy::Email->send_mail(
        to       => $self->config('admin_mail'),
        reply_to => $self->param('email'),
        subject  => "Anmodning om Harlem-adgang: " . $self->param('full_name'),
        body     => $admin_mail,
    );

    my $receipt_mail = $self->render_to_string(
        template   => 'website/harlem_receipt_mail',
        admin_mail => $admin_mail,
        full_name  => $self->param('full_name'),
        layout     => undef,
    );

    DIKUrevy::Email->send_mail(
        to       => $self->param('email'),
        reply_to => $self->config('admin_mail'),
        subject  => "Kvittering på anmodning om Harlem-adgang for " . $self->param('full_name'),
        body     => $receipt_mail,
    );

    $self->show_message('Dit anmodning om adgang er hermed indsendt. Kvittering herpå er sendt til din email-adresse. Du vil få svar snarest muligt.', flash => 1);
    return $self->redirect_to('harlem');
}

1;

