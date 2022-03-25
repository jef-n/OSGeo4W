#!/usr/bin/perl

use strict;
use warnings;
use Storable qw(dclone);
use Data::Dumper;

my %src;
my %bin;
my $pkg;

system("/usr/bin/rsync download.osgeo.org:/osgeo/download/osgeo4w/v2/x86_64/setup.ini /tmp/setup-master.ini") == 0 or die "Could not download setup.ini";

$src{"openjpeg-tools"} = "openjpeg";
$src{"alkis-import"} = "alkis-import";
$src{"qtkeychain"} = "qtkeychain-libs";

# collect package from source relations
for my $f ("/tmp/setup-master.ini", "x86_64/setup.ini") {
	open F, $f;
	while(<F>) {
		if(/^@ (\S+)\s+$/) {
			$pkg = $1

		# source: x86_64/release/avce00/avce00-2.0.0-3-src.tar.bz2 1316 1225e82b0adbb05fdee034c206992d28
		} elsif( /^source:\s+(\S+)\s+\d+\s+\S+\s+$/ ) {
			next if exists $src{$pkg};

			my ($src, $ver, $bin) = $1 =~ m#^.+/([^/]+)/\1-(.*)-(\d+)-src.tar.bz2$#;
			die "invalid $1" unless defined $src && defined $ver && defined $bin;

			$src = "qtkeychain" if $src eq "qtkeychain-libs";

			die "src/$src [$ver:$bin] not found" unless -f "src/$src/osgeo4w/package.sh";

			$src{$pkg} = $src;
			push @{ $bin{$src} }, $pkg;
		}
	}
	close F;
}

my %fdep;
my %rdep;

# collect build dependencies
open F, "git grep BUILDDEPENDS= -- '*/package.sh' |";
while(<F>) {
	s/\s*#.*$//;

	my($pkg, $deps) = m#src/([^/]+)/osgeo4w/package.sh:export BUILDDEPENDS=(.*\S)\s+$#;
	die "invalid $_" unless defined $pkg;

	next if $pkg =~ /^python3-(mathlib|virtualenv)$/;  # n/a

	if(exists $src{"$pkg-devel"} && !exists $src{$pkg}) {
		#print STDERR "use $pkg-devel for $pkg\n";
		$pkg = "$pkg-devel";
	}

	unless(exists $src{$pkg}) {
		warn "no src for $pkg";
		next;
	}

	$pkg = $src{$pkg};

	next if $deps eq "none";

	$deps =~ s/\s+$//;
	$deps =~ s/^"(.*)"$/$1/;

	my @deps = split (/\s+/, $deps);
	@deps = map { die "src for $_ not found" unless exists $src{$_}; $src{$_}; } @deps;

	foreach my $d (@deps) {
		$rdep{$d}{$pkg} = 1;
		$fdep{$pkg}{$d} = 1;
	}
}
close F;

my @arg = grep !/-$/, @ARGV;

my %skip;
foreach (grep /-$/, @ARGV) {
	s/-$//;
	$skip{$_} = 1;
}

my @todo;
while(my $p = shift @arg) {
	unless(exists $src{$p}) {
		die "Source for $p not found" unless exists $src{$p};
		$p = $src{$p};
	}
	push @todo, $p;
}

my %todo;
while(my $p = shift @todo) {
	next if exists $skip{$p};

	$todo{$p} = 1;

	for my $d (keys %{ $rdep{$p} }) {
		next if exists $skip{$d};
		next if exists $todo{$d};

		$todo{$d} = 1;

		unshift @todo, $d;
	}
}

my @inorder;
while(keys %todo) {
	my @p;
	TODO: foreach my $p (keys %todo) {
		foreach my $q (keys %{ $fdep{$p} }) {
			next TODO if exists $todo{$q};
		}
		push @p, $p;
	}

	last unless @p;

	push @inorder, @p;

	foreach my $p (@p) {
		delete $todo{$p};
		foreach my $d (keys %{ $rdep{$p} }) {
			delete $rdep{$p}{$d};
			delete $fdep{$d}{$p};
		}
	}
}

push @inorder, keys %todo;

print join(" ", @inorder) . "\n";
