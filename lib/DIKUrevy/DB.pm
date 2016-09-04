package DIKUrevy::DB;
use Mojo::Base -base;
use utf8;

my $db;
has '_db_fields';
has '_loaded' => 0;

sub db {
    return $DIKUrevy::DB::db;
}

sub db_fields {
    my ($class) = caller;
    my @fields = @_;
    $class->attr([ @fields ]);
    $class->attr(_db_fields => sub { [ @fields ] });
}

sub db_table { ... }

sub query {
    my $self = shift;
    my $res = $self->db->db->query(@_);
    return $res;
}

sub build_select {
    my $self = shift;
    my $args = shift;
    my $limit = '';
    my $order = '';
    my @eqs;
    my @vals;
    my $sql = 'SELECT * FROM ' . $self->db_table() . ' WHERE ';
    for my $key (keys %$args) {
        if    ($key eq 'order') { $order = ' ORDER BY ' . $args->{order}; }
        elsif ($key eq 'limit') { $limit = ' LIMIT ' . $args->{limit}; }
        else {
            push( @eqs, "$key = (?)" );
            push( @vals, $args->{$key} );
        }
    }

    push(@eqs, '1=1') unless @eqs;

    $sql .= join(' AND ', @eqs) . $order . $limit;
    return ($sql, @vals);
}

sub fetch {
    my $self = shift;
    my $args = shift // {};

    my @query = $self->build_select($args);
    my $query_res = $self->query(@query);
    my @result;
    my $class = ref($self) ? ref($self) : $self;
    while (my $res = $query_res->hash) {
        push( @result, $class->new( %$res, _loaded => 1 ) );
    }
    return \@result;
}

sub retrieve {
    my $self = shift;
    my $args = shift // {};

    return $self->fetch({ %$args, limit => 1 })->[0];
}

sub save {
    my $self = shift;
    my @fields = @{ $self->_db_fields };
    my $sql;
    if ($self->_loaded) {
        $sql = 'UPDATE ' . $self->db_table . ' SET ';
        $sql .= join(', ', map { "$_ = (?)" } @fields);
        $sql .= ' WHERE id = ' . $self->id;
    } else {
        $sql = 'INSERT INTO ' . $self->db_table . '(' . join(',', @fields) . ')';
        $sql .= 'VALUES (' . join(',', map { '(?)' } @fields) . ')';
    }
    my @vals = map { $self->$_ } @fields;

    $self->query($sql, @vals);

    unless ($self->_loaded) {
        $self->id( $self->db->db->dbh->last_insert_id('','',$self->db_table,'id') );
        $self->_loaded(1);
    }
}

1;

