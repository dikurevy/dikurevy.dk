package DIKUrevy::User;
use Mojo::Base 'DIKUrevy::DB';
use utf8;

use Crypt::PBKDF2;
use Encode qw/encode/;
use Mojo::Util qw/md5_sum secure_compare/;

DIKUrevy::DB::db_fields(qw(
    id
    username
    email
    password
    password_legacy
    realname
    phone
    verified
    admin
));

sub db_table { 'users' }

sub auth_user {
    my $class = shift;
    my ($username, $password) = @_;

    my $user = $class->retrieve({ username => $username });
    return unless $user && $user->verified;

    my $encoded_password = encode('UTF-8', $password);

    if ($user->password) {
        my $pbkdf2 = Crypt::PBKDF2->new();
        return unless $pbkdf2->validate( $user->password, $encoded_password );
    } elsif ($user->password_legacy) {
        # Legacy password authentication from Drupal
        # (Unsalted MD5; ugh.)
        return unless secure_compare($user->password_legacy, md5_sum $encoded_password);

        $user->set_password( $password );
        $user->save();
    }

    return $user;
}

sub set_password {
    my $self = shift;
    my $password = shift;

    my $encoded_password = encode('UTF-8', $password);

    my $pbkdf2 = Crypt::PBKDF2->new();
    $self->password( $pbkdf2->generate( $encoded_password ) );
    $self->password_legacy(undef);
    return $self;
}

1;

