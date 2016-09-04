# DIKUrevy.dk

## Quick-start guide

For at køre siden i udvikling:

    # Installér afhængigheder
    cpan -i Mojolicious Mojolicious::Plugin::Authentication Email::Stuffer Crypt::PBKDF2 FindBin Mojo::SQLite

    # Tilpas konfigurationsfilen
    cp dikurevy_website.conf.example dikurevy_website.conf
    gedit dikurevy_website.conf

    # Start udviklings-webserveren
    morbo script/dikurevy_website

For at opdatere koden på dikurevy.dk:

    cd /var/www/dikurevy/new
    git pull
    sudo -u www-data hypnotoad script/dikurevy_website

## Hvor ligger ting?

### Vil du rette indhold?
* `templates/` indeholder alle HTML-skabeloner.

### Vil du rette layout?
* `templates/layout/` indeholder opsætningen af sidens layout og menuer.

### Vil du oprette nye sider?
* `lib/DIKUrevy/Website.pm` indeholder bl.a. opsætningen af ruter (hvad der skal håndtere en given URL).
* `lib/DIKUrevy/Website/Controllers/` indeholder controllers'ne der håndterer renderingen af ruterne.
