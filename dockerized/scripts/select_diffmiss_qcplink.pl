#!/usr/bin/perl

use strict;

open IN, '<', "clean_inds_qcplink_test_missing.missing" or die "Cannot open missing file \n";
open OUT, '>', "fail_diffmiss_qcplink.txt";
while(<IN>){
	s/^\s+//;
	my @fields = split /\s+/, $_;
	unless($fields[0] eq 'CHR'){
		if($fields[4] < $ARGV[0]){
			print OUT "$fields[1]\n";
		}
	}
}
