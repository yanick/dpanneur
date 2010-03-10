package dpanneur::Controller::Root;

use 5.010;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(namespace => '');

=head1 NAME

cpancache::Controller::Root - Root Controller for cpancache

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=head2 index

The root page (/)

=cut

=head2 default

Standard 404 error page

=cut

use CPAN::Cache;
use Git;
use FindBin '$Bin';
use File::chdir;
use GitStore;

my $git_dir = $Bin.'/../cpan';


sub proxy :Local :Args {
    my ( $self, $c, @path ) = @_;

    state $can_proxy = dpanneur->config->{proxy};

    unless ( $can_proxy ) {
        $c->res->status(404);
        $c->res->body( 'path not found' );
    }

    state $cache = CPAN::Cache->new(
        remote_uri => 'http://search.cpan.org/CPAN/',
        local_dir => $git_dir,
    );

    state $repo = Git->repository( Directory => $git_dir );

    my $path = join '/', @path;

    $c->log->debug( $path );

    my $file = $cache->mirror( $path );

    local $CWD = $git_dir;

    # will fail if there are no update
    eval {
        $repo->command( 'add', $path );
        $repo->command( 'commit', "-m $path", );
    };
    

    open my $fh, '<', $file->path;

    $c->response->body( do{ local $/ = <$fh> } );

}

sub branch :Path :Args {
    my ( $self, $c, $branch, @path ) = @_;

    $c->log->debug( "branch is $branch" );

    state $repo = Git->repository( Directory => $git_dir );
    #my $store = GitStore->new( repo => $git_dir, branch => $branch );

    $c->res->body( join "\n", $repo->command( 'show', "$branch:".join '/', @path ) );
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {}

=head1 AUTHOR

Yanick Champoux,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
