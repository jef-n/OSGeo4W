#!/usr/bin/perl

use strict;
use warnings;

use File::Basename;
use File::Temp;
use File::Path qw/make_path remove_tree/;
use Data::Dumper;

die "OSGEO4W_REP not set" unless -d $ENV{'OSGEO4W_REP'};
chdir $ENV{OSGEO4W_REP};

die "MASTER_SCP not set" unless exists $ENV{"MASTER_SCP"};
die "MASTER_REGEN_URI not set" unless exists $ENV{"MASTER_REGEN_URI"};
die "setup.ini not found" unless -f "x86_64/setup.ini";

sub parseini {
	my $ini = shift;
	my $pkg = shift;

	my $f;
	open $f, $ini;

	my $p;
	my $sec;
	while(<$f>) {
		s/\s+$//;

		if(/^\@\s+(\S+)/) {
			$p = $pkg->{$1} = {};
			$sec = 'curr';
			next;

		} elsif(/^($|\s)/) {
			undef $p;
			undef $sec;
			next;

		} elsif(/^#/) {
			next;

		} elsif(/^(arch|setup-timestamp):/) {
			next;

		} elsif(!defined $p) {
			next;

		} elsif( my($fld) = /^([ls]desc):/) {
			if(/: "(.*)"$/) {
				$p->{$fld} = $1;
			} elsif(/: "(.*)$/) {
				$p->{$fld} = "$1\n";
				while(<$f>) {
					$p->{$fld} .= $_;
					last if /"\s*$/;
				}
				$p->{$fld} =~ s/"\s+$//;
			} else {
				die "?";
			}
			next;

		} elsif( my($k, $v) = /^(category|external-source|requires):\s+(.*)$/) {
			$p->{$k} = $v;
			next;

		} elsif(/^version:\s+(\S+)$/) {
			$p->{$sec}{version} = $1;
			next;

		} elsif(/^\[(prev|test)\]$/) {
			$sec=$1;
			next;

		} elsif( my($field, $file, $size, $md5) = /^(install|source|license): (\S+) (\d+) (\S+)$/ ) {
			die "NO MD5: $_" unless defined $md5;
			die "No section" unless defined $sec;
			die "No field" unless defined $field;

			$p->{$sec}{$field} = {
				md5 => $md5,
				size => $size,
				file => $file,
			};

			$p->{ $p->{$sec}{version} } = $p->{$sec};

			next;
		}

		die "SKIP: $_\n";
	}

	close $f;
}

sub getver {
    my $f = basename($_[0]);
    my @a = ($f =~ /^(.*?)-(\d.*)\.tar/);
    return wantarray ? @a : $a[1];
}

sub compare_versions {
	my($a, $b) = @_;

	my @a = split /\./, $a;
	my @b = split /\./, $b;

	my $n = @a < @b ? @a : @b;

	while( @a && @b ) {
		my $a = shift @a;
		my $b = shift @b;

		next if $a eq $b;

		my ($an, $ann) = $a =~ /^(\d+)(\D.*)?$/;
		my ($bn, $bnn) = $b =~ /^(\d+)(\D.*)?$/;

		return defined $an && defined $bn ? $an <=> $bn : $an cmp $bn;
	}

	return @a ? 1 : @b ? -1 : 0;
}

system("/usr/bin/rsync $ENV{'MASTER_SCP'}/x86_64/setup.ini /tmp/setup-master.ini") == 0 or die "Could not download setup.ini";

my %remote;
parseini "/tmp/setup-master.ini", \%remote;

my %local;
parseini "x86_64/setup.ini", \%local;

my %packages;
$packages{$_}=1 foreach keys %local;
$packages{$_}=1 foreach keys %remote;

my %files;
my %shints;
my %hints;

if(0) {
undef %packages;
$packages{"geos"} = 1;

open F, ">/tmp/local.pm";
print F Dumper(\%local);
close F;

open F, ">/tmp/remote.pm";
print F Dumper(\%remote);
close F;
}

open H, "/usr/bin/find x86_64/release -name setup.hint |";
while(<H>) {
	chomp;
	my($dir, $p) = m#^(\S+)/(\S+)/setup.hint$#;
	$shints{$p} = $dir;
}
close H;

my $tdir = File::Temp->newdir(CLEANUP => 0);

foreach my $p (sort keys %packages) {
	my @v;

	# skip if there is no newer local version
	next if
		(!defined $local{$p}->{curr}->{version} || ($remote{$p}->{curr}->{version} && $local{$p}->{curr}->{version} eq $remote{$p}->{curr}->{version})) &&
		(!defined $local{$p}->{prev}->{version} || ($remote{$p}->{prev}->{version} && $local{$p}->{prev}->{version} eq $remote{$p}->{prev}->{version})) &&
		(!defined $local{$p}->{test}->{version} || ($remote{$p}->{test}->{version} && $local{$p}->{test}->{version} eq $remote{$p}->{test}->{version}));

	# determine two most up to date versions
	push @v, $local{$p}->{curr}->{version};
	push @v, $local{$p}->{prev}->{version};
	push @v, $remote{$p}->{curr}->{version};
	push @v, $remote{$p}->{prev}->{version};

	my %v;
	@v = grep { defined && !$v{$_}++ } @v;
	@v = sort { compare_versions($b, $a) } @v;
	splice @v, 2;

	my $curr;
	my $prev;
	my @uploads;
	V: for my $v (@v) {
		unless(defined $curr) {
			$curr = $v;
		} else {
			$prev = $v;
		}

		# Skip already remotely available versions
		for my $sec (qw/curr prev/) {
			next V if defined $remote{$p}->{$sec}{version} && $remote{$p}->{$sec}{version} eq $v;
		}

		push @uploads, $v;
	}

	undef @v;
	push @v, $local{$p}->{test}{version};
	push @v, $remote{$p}->{test}{version};

	undef %v;
	@v = grep { defined && !$v{$_}++ } @v;
	@v = sort { compare_versions($b, $a) } @v;

	my $test;
	if(@v) {
		$test = $v[0];

		if(!defined $remote{$p}->{test}{version} || $remote{$p}->{test}{version} ne $test) {
			push @uploads, $test;
		}
	}

	die "Hint for $p not found" unless exists $shints{$p};
	my $d = $shints{$p};

	make_path("$tdir/$d/$p") unless -d "$tdir/$d/$p";
	die "Could not created " unless -d "$tdir/$d/$p";

	open O, ">$tdir/$d/$p/setup.hint";

	open I, "$d/$p/setup.hint" or die "Cannot open $d/$p/setup.hint: $1";
	while(<I>) {
		next if /^(curr|prev|test):/;
		print O;
	}
	close I;

	print O "curr: $curr\n" if defined $curr;
	print O "prev: $prev\n" if defined $prev;
	print O "test: $test\n" if defined $test;

	close O;

	for my $u (@uploads) {
		for my $f (qw/install source license/ ) {
			$files{ $local{$p}->{$u}->{$f}->{file} } = 1 if exists $local{$p}->{$u}->{$f}->{file};
		}
	}
}

unless(keys %files) {
	print STDERR "No files to update\n";
	exit 0;
}

my($host,$path) = $ENV{MASTER_SCP} =~ /^(.*):(.*)$/;

open F, "| /usr/bin/rsync --files-from=- '$ENV{OSGEO4W_REP}' '$ENV{MASTER_SCP}'";
for my $file (sort keys %files) {
	print F "$file\n";
}
close F or die "Update of files failed: $!";

if( system("/usr/bin/rsync -r '$tdir/' '$ENV{MASTER_SCP}/'") != 0 ) {
	die "Update of hints failed: $!";
}

system "/usr/bin/wget -v -O - '$ENV{MASTER_REGEN_URI}'";
