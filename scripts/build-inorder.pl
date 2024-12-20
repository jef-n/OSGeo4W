#!/usr/bin/perl

use strict;
use warnings;

my @removed = qw/libjpeg grass8 saga9 python3-clcache python3-pyuv python3-attrdict python3-jupyter/;
my @srcless = qw/alkis-import alkis-import-gid7 alkis-import-gid7i/;

my $OSGEO4W_REP = $ENV{OSGEO4W_REP};

unless(defined $OSGEO4W_REP && $OSGEO4W_REP ne "") {
	my $b = `git branch --show-current`;
	chomp $b;

	if($b eq "master") {
                $OSGEO4W_REP = "/d/src/osgeo4w";
	} else {
                $OSGEO4W_REP = "/temp/repo-$b";
	}
}


# collect packages

my %src;
open F, "git grep '^export PACKAGES=' -- '*/osgeo4w/package.sh' |";
while(<F>) {
	my($pkg, $pkgs) = m#src/([^/]+)/osgeo4w/package.sh:export PACKAGES=(.*\S)\s+$#;
	die "PACKAGES invalid $_" unless defined $pkg;

	$pkgs =~ s/\s+$//;
	$pkgs =~ s/^"(.*)"$/$1/;
	$pkgs =~ s/^'(.*)'$/$1/;

	$src{$_} = $pkg foreach split(/\s+/, $pkgs);
}

# collect build dependencies

my %fdep;
my %rdep;
open F, "git grep '^export BUILDDEPENDS=' -- '*/osgeo4w/package.sh' |";
while(<F>) {
	s/\s*#.*$//;

	my($pkg, $deps) = m#src/([^/]+)/osgeo4w/package.sh:export BUILDDEPENDS=(.*\S)\s+$#;
	die "BUILDDEPENDS invalid $_" unless defined $pkg;

	next if $deps eq "none";

	$deps =~ s/\s+$//;
	$deps =~ s/^"(.*)"$/$1/;
	$deps =~ s/^'(.*)'$/$1/;

	foreach my $d (map { $src{$_}; } split (/\s+/, $deps)) {
		next unless defined $d;
		$rdep{$d}{$pkg} = 1;
		$fdep{$pkg}{$d} = 1;
	}
}
close F;

$fdep{"python3-pip"}{"python3"} = 1;
$rdep{"python3"}{"python3-pip"} = 1;

delete $fdep{"python3-pip"}{"python3-pip"};
delete $rdep{"python3-pip"}{"python3-pip"};

delete $fdep{"python3-pip"}{"python3-setuptools"};
delete $rdep{"python3-setuptools"}{"python3-pip"};

$fdep{"python3-setuptools"}{"python3"} = 1;
$rdep{"python3"}{"python3-setuptools"} = 1;

delete $fdep{"python3-setuptools"}{"python3-pip"};
delete $rdep{"python3-pip"}{"python3-setuptools"};

my @arg = grep !/-$/, @ARGV;

my %skip;
foreach (grep /-$/, @ARGV) {
	s/-$//;
	$skip{$_} = 1;
}

@arg = keys %src unless @arg;

my @todo;
while(my $p = shift @arg) {
	unless(-f "src/$p/osgeo4w/package.sh") {
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
	TODO: foreach my $p (sort keys %todo) {
		foreach my $q (keys %{ $fdep{$p} }) {
			next TODO if exists $todo{$q};
		}
		push @p, $p;
	}

	last unless @p;

	push @inorder, sort @p;

	foreach my $p (@p) {
		delete $todo{$p};
		foreach my $d (keys %{ $rdep{$p} }) {
			delete $rdep{$p}{$d};
			delete $fdep{$d}{$p};
		}
	}
}

die "Remaining packages: " . join(" ", sort keys %todo) if %todo;

print join("\n", @inorder), "\n";
