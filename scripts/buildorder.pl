#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;

my %dep;
my %fdep;
my %rdep;
my %pkg;
my %done;

open F, "x86_64/setup.ini";
while(<F>) {
	chomp;
	next unless /^@ (\S+)$/;
	$done{$1} = 1;
}

close F;

open F, "doc/build-dependencies";
while(<F>) {
	chomp;
	next if /^#|^\s*$/;

	my($a, $b) = split /\t/;

	die "invalid $_" unless defined $a && defined $b;

	$dep{$a}{$b} = 1;
	$fdep{$a}{$b} = 1;
	$rdep{$b}{$a} = 1;
	$pkg{$a} = 1;
	$pkg{$b} = 1;
}

close F;

my $l = 0;

while(keys %pkg) {
	my @done;
	foreach my $b (keys %pkg) {
		next if exists $dep{$b};
		push @done, $b;
	}

	last unless @done;

	foreach my $b (sort @done) {
		delete $pkg{$b};

		foreach my $a (keys %dep) {
			next unless exists $dep{$a}{$b};

			delete $dep{$a}{$b};
			delete $dep{$a} unless keys %{ $dep{$a} };
		}

		my $t;
		if($done{$b}) {
			$t = "\e[32m$b\e[0m";
		} else {
			my $u = 0;
			foreach( keys %{ $fdep{$b} } ) {
				$u++ unless $done{$_};
			}
			$t .= $u > 0 ? "\e[31m$b\e[0m" : "\e[33m$b\e[0m";
		}

		if( keys %{ $fdep{$b} } ) {
			$t .= " <=";

			for my $c (keys %{ $fdep{$b} }) {
				if($done{$c}) {
					$t .= " \e[32m$c\e[0m";
				} else {
					my $u = 0;
					foreach ( keys %{ $fdep{$c} } ) {
						$u++ unless $done{$_};
					}
					$t .= $u == 0 ? " \e[33m$c\e[0m" : " \e[31m$c($u)\e[0m";
				}
			}
		}

		print "    " x $l . $t . "\n";
	}

	$l++;
}

exit unless keys %pkg;

print "Remaining packages: " . join(", ", keys %pkg) . "\n";

foreach my $a (keys %pkg) {
	print "$a: " . join(", ", keys %{ $dep{$a} }) . "\n";
}
