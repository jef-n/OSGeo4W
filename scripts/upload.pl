#!/usr/bin/perl

use strict;
use warnings;

use File::Basename;
use File::Temp;
use File::Path qw/make_path remove_tree/;
use Data::Dumper;

die "OSGEO4W_REP not set" unless -d $ENV{'OSGEO4W_REP'};
chdir $ENV{OSGEO4W_REP};

die "still uploading" if -f ".uploading";

open F, ">.uploading";
print F "$$\n";
close F;

die "MASTER_SCP not set" unless exists $ENV{"MASTER_SCP"};
die "MASTER_REGEN_URI not set" unless exists $ENV{"MASTER_REGEN_URI"};
die "setup-lic.ini not found" unless -f "x86_64/setup-lic.ini";

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

        while( @a && @b ) {
                my $a = shift @a;
                my $b = shift @b;
                next if $a eq $b;

		# a
		# 1
		# 1a
		# 1rc1
		while($a && $b) {
			# print "a:$a b:$b\n";
			my ($an) = $a =~ /^(\d+)/;
			my ($bn) = $b =~ /^(\d+)/;

			if(defined $an && defined $bn) {
				# print "N: $an <=> $bn\n";
				return $an <=> $bn unless $an == $bn;
				$a =~ s/^\d+//;
				$b =~ s/^\d+//;
			} elsif($an || $bn) {
				warn "Invalid version compare: $a vs $b";
				return undef;
			}

			($an) = $a =~ /^(\D+)/;
			($bn) = $b =~ /^(\D+)/;

			if($an && $bn) {
				# print "L: $an <=> $bn\n";
				return $an cmp $bn unless $an eq $bn;
				$a =~ s/^\D+//;
				$b =~ s/^\D+//;
			} elsif($an || $bn) {
				return -1 if defined $an && $an =~ /^-?rc$/i;	# rc* < ""
				return 1 if defined $bn && $bn =~ /^-?rc$/i;	# "" > rc*
				return $an ? 1 : -1;				# a > ""  | "" < a
			}
		}

		return 1 if $a;
		return -1 if $b;
        }

        return @a ? 1 : @b ? -1 : 0;
}

system("/usr/bin/rsync $ENV{'MASTER_SCP'}/x86_64/setup.ini /tmp/setup-master.ini") == 0 or die "Could not download setup.ini";

my %remote;
parseini "/tmp/setup-master.ini", \%remote;

my %local;
parseini "x86_64/setup-lic.ini", \%local;

my %packages;
$packages{$_}=1 foreach keys %local;
$packages{$_}=1 foreach keys %remote;

my %files;
my %shints;
my %hints;

open H, "/usr/bin/find x86_64/release -name setup.hint |";
while(<H>) {
	chomp;
	my($dir, $p) = m#^(\S+)/(\S+)/setup.hint$#;
	$shints{$p} = $dir;
}
close H;

my $tdir = File::Temp->newdir(CLEANUP => 0);
print STDERR "Temporary directory: $tdir\n";

open D, ">$tdir/diff";

foreach my $p (sort keys %packages) {
	my @v;

	# print D "# $p\n";

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
			next V if defined $remote{$p}->{$sec}->{version} && $remote{$p}->{$sec}->{version} eq $v;
		}

		push @uploads, $v;
	}

	undef @v;
	push @v, $local{$p}->{test}->{version};
	push @v, $remote{$p}->{test}->{version};

	undef %v;
	@v = grep { defined && !$v{$_}++ } @v;
	@v = sort { compare_versions($b, $a) } @v;

	my $test;
	if(@v) {
		$test = $v[0];

		if(!defined $remote{$p}->{test}->{version} || $remote{$p}->{test}->{version} ne $test) {
			push @uploads, $test;
		}
	}

	die "Hint for $p not found" unless exists $shints{$p};
	my $d = $shints{$p};

	die "$p: curr $curr equals test $test\nLocal:" . Dumper($local{$p})  . "\nRemote: " . Dumper($remote{$p}) if defined $curr && defined $test && $curr eq $test;
	die "$p: curr $curr equals prev $prev\nLocal:" . Dumper($local{$p})  . "\nRemote: " . Dumper($remote{$p}) if defined $curr && defined $prev && $curr eq $prev;
	die "$p: prev $prev equals test $test\nLocal:" . Dumper($local{$p})  . "\nRemote: " . Dumper($remote{$p}) if defined $prev && defined $test && $prev eq $test;

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

	my $uploads = 0;
	for my $u (@uploads) {
		for my $f (qw/install source license/ ) {
			next unless exists $local{$p}->{$u}->{$f}->{file};
			$files{ $local{$p}->{$u}->{$f}->{file} } = 1;
			$uploads = 1;
		}
	}

	if($uploads) {
		my @v;
		push @v, "c:$curr" if defined $curr;
		push @v, "p:$prev" if defined $prev;
		push @v, "t:$test" if defined $test;
		print STDERR "updated hint: $tdir/$d/$p/setup.hint [" . join(" ", @v) . "]\n";

		if( $remote{$p}{curr}->{version} ne $curr ) {
			my $ov = $remote{$p}{curr}->{version};
			my $nv = $curr;
			my ($ouv, $opv) = split /-/, $ov;
			my ($nuv, $npv) = split /-/, $nv;
			my @ov = split /\./, $ouv;
			my @nv = split /\./, $nuv;

			if($ouv eq $nuv) {
				print D "$p:$ov:$nv:REBUILD\n";
			} else {

				if(@ov == 3 && @nv == 3) {
					if($ov[0] == $nv[0] && $ov[1] == $nv[1] && $ov[2] ne $nv[2]) {
						print D "$p:$ov:$nv:PATCH\n";
					} else {
						print D "$p:$ov:$nv:UPDATE\n";
					}
				} else {
					print D "$p:$ov:$nv:UPDATEM\n";
				}
			}
		}
	} else {
		unlink "$tdir/$d/$p/setup.hint";
	}
}

close D;

unless(keys %files) {
	print STDERR "No files to update\n";
	unlink ".uploading";
	exit 0;
}

my $opt = $ENV{OSGEO4W_RSYNC_OPT} || "";

my($host,$path) = $ENV{MASTER_SCP} =~ /^(.*):(.*)$/;

open F, "| /usr/bin/rsync $opt -vtuO --chmod=D775,F664 --files-from=- '$ENV{OSGEO4W_REP}' '$ENV{MASTER_SCP}'";
print F "acceptable.lst\n";
for my $file (sort keys %files) {
	print F "$file\n";
}
close F or die "Update of files failed: $!";

if( system("/usr/bin/rsync $opt -vtuO --chmod=D775,F664 -r '$tdir/' '$ENV{MASTER_SCP}/'") != 0 ) {
	die "Update of hints failed: $!";
}

system "/usr/bin/curl '$ENV{MASTER_REGEN_URI}'";

unlink ".uploading";
