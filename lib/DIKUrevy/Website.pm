package DIKUrevy::Website;
use Mojo::Base 'Mojolicious';
use utf8;
use DIKUrevy::User;

# This method will run once at server start
sub startup {
    my $self = shift;

    $self->plugin('Config', { file => 'dikurevy_website.conf' });
    $self->secrets( $self->config('secrets') );

    $DIKUrevy::DB::db = $self->config('db');
    $self->helper(db => sub { return $DIKUrevy::DB::db });

    if ($self->mode eq 'production') {
        # Allow access to cookie from møder.dikurevy.dk
        $self->sessions->cookie_domain('.dikurevy.dk');

        # If specified; drop privileges on webservers down to the given
        # user/group after initial launch
        my $user_group = $self->config('server_user_group');
        if ($user_group) {
            $self->plugin('SetUserGroup', $user_group);
        }
    }

    for my $type (qw(message error)) {
        $self->helper("show_$type" => sub {
            my ($self, $msg, %args) = @_;
            my $loc = $args{flash} ? 'flash' : 'stash';
            my $messages = $self->$loc($type.'s') // [];
            $self->$loc($type.'s', [ @$messages, $msg ]);
        });
    }

    $self->helper(form_group => sub {
        my $self = shift;
        my $name = shift;
        my @classes = 'form-group';
        push(@classes, 'has-error') if $self->validation->has_error($name);
        return $self->tag('div', class => join(' ', @classes), @_);
    });

    # Is the current date <= the given date?
    $self->helper(date_is_before => sub {
        my $self = shift;
        my ($byear, $bmonth, $bday) = @_;

        my ($sec, $min, $hour, $mday, $mon, $year) = localtime(time);
        $year += 1900;
        $mon += 1; # 0-indexed...

        return $year < $byear || $year == $byear && (
            $mon < $bmonth || $mon == $bmonth && $mday <= $bday
        );

    });

    $self->plugin(authentication => {
        autoload_user => 1,
        load_user     => sub {
            my ($self, $id) = @_;
            return DIKUrevy::User->retrieve({ id => $id });
        },
        validate_user => sub {
            my ($self, $username, $password) = @_;
            my $user = DIKUrevy::User->auth_user($username, $password);
            return $user ? $user->id : undef;
        }
    });

    # Migrate DB schema
    my $path = $self->home->rel_file('migrations/users.sql');
    $self->db->migrations->name('users')->from_file($path)->migrate;
    $path = $self->home->rel_file('migrations/user_data.sql');
    if (-f $path) {
        $self->db->migrations->name('user_data')->from_file($path)->migrate;
    }

    $self->defaults(
        layout   => 'bootstrap',
        title    => 'DIKUrevy',
    );

    # Router
    my $r = $self->routes;

    my $authed = $r->under('/')->to(cb => sub {
        my $self = shift;
        return 1 if $self->is_user_authenticated;
        $self->redirect_to('login');
        return 0;
    });

    my $admin = $r->under('/admin')->to(cb => sub {
        my $self = shift;
        return 1 if $self->is_user_authenticated && $self->current_user->admin;
        $self->redirect_to('login');
        return 0;
    });

    # Front page
    $r->get('/')->to('website#index')->name('frontpage');

    # Subpages
    $r->get('/billetsalg')->to('website#tickets')->name('tickets');
    $r->get('/medier')->to('website#media')->name('media');
    $r->get('/plakater')->to('website#posters')->name('posters');
    $r->get('/vaer-med')->to('website#join_us')->name('join_us');
    $r->get('/kontakt')->to('website#contact')->name('contact');
    $r->get('/harlem')->to('website#harlem')->name('harlem');
    $r->post('/harlem')->to('website#harlem_submit')->name('harlem_submit');

    # Redirects
    $r->get('/introdag' => sub { return shift->redirect_to('https://www.facebook.com/events/1347504975375816/') });

    # Login/logout pages
    $r->get('/log-ind')->to('auth#login')->name('login');
    $r->post('/log-ind')->to('auth#login_submit')->name('login_submit');
    $r->get('/log-ud')->to('auth#logout')->name('logout');
    $r->get('/opret-bruger')->to('auth#create_user')->name('create_user');
    $r->post('/opret-bruger')->to('auth#create_user_submit')->name('create_user_submit');
    $r->get('/nyt-loesen')->to('auth#new_password')->name('new_password');
    $r->post('/nyt-loesen')->to('auth#new_password_submit')->name('new_password_submit');
    $r->get('/hop-ind')->to('auth#login_with_token')->name('login_with_token');

    # Secured pages
    $authed->get('/telefonbog')->to('website#phone_dir')->name('phone_dir');
    $authed->get('/git')->to('website#git')->name('git');
    $authed->get('/rediger-bruger')->to('auth#edit_user')->name('edit_user');
    $authed->post('/rediger-bruger')->to('auth#edit_user_submit')->name('edit_user_submit');

    # Admin pages
    $admin->get('/')->to('admin#index')->name('admin_index');
    $admin->get('/brugere')->to('admin#user_list')->name('admin_user_list');
    $admin->get('/brugere/:userid/bekraeftet')->to('admin#toggle_verified')->name('admin_toggle_verified');
}

1;
