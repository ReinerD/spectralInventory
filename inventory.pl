#!perl -w
use strict;
use warnings FATAL => qw(uninitialized);
my $dir=shift;
my @files=`ls -1 $dir | grep jdx`;
my %inventory;
my $_silent=1;
foreach my $file(@files){
	chomp $file;
	my ($catalogID, $batchID, $nmrID, $dummy, $dummy2, $pulprog);
	#analyse filename
	if ($file=~/([BD]?\d+.\d+)_(.*)-(\d+)\.jdx/){
		($catalogID, $batchID, $nmrID)=($1,$2,$3);
	}else{
		print "no match for $file\n";
	}
	unless (`ls -l "$dir/$file" | awk '{print \$5}'` > 0){
#		print `ls -l $dir/$file`,"\n";
		next;
	}
	my $ppLine=`grep " PULPROG" "$dir/$file"`;
	($dummy, $dummy2, $pulprog)=split /\s+/, $ppLine;
	unless ($ppLine){
		$ppLine=`grep "PULPROG" "$dir/$file"`;
		($dummy, $pulprog)=split /\s+/, $ppLine;
	}
	#($dummy, $dummy2, $pulprog)=split /\s+/, $ppLine;
	unless ($_silent){
		print "$catalogID, $batchID, $nmrID, ";
		if (defined $pulprog and $pulprog =~/\w/) {
			print $pulprog;
		
		}else{
			print "- $ppLine";
		}
		print "\n";
	}
	#TODO:catch $pulprog undefined 
	if (! defined $pulprog){
		print "no pulprog for $file\n";
		print LOG "no pulprog for $file\n";
	}else{
		$inventory{$catalogID}{$batchID}{$nmrID}=$pulprog;
		if($pulprog =~ /^<?zg/){
			$inventory{$catalogID}{$batchID}{hasZG}=1;
		}elsif($pulprog =~ /^<?cosy/){
			$inventory{$catalogID}{$batchID}{hasCOSY}=1;
		}elsif($pulprog =~ /^<?hsqc/){
			$inventory{$catalogID}{$batchID}{hasHSQC}=1;
		}elsif($pulprog =~ /^<?hmbc/){
			$inventory{$catalogID}{$batchID}{hasHMBC}=1;
		}
	}	
}
my ($cmpdCnt, $spcCnt,$cntComplete)=(0,0,0);
while (my ($catalogID,$cv) =each %inventory){
	print "$catalogID\t";
	if (length($catalogID)<8){
		print "\t";
	}
	my $bCnt=0;
	while (my ($batchID,$bv) =each %$cv){
		unless ($bCnt==0){
				print "\t\t" ;
		}
		print "$batchID\t";
		$cmpdCnt+=1;$bCnt+=1;
		my $nmrCnt=0;
		while (my ($nmrID,$nv) =each %$bv){
			unless ($nmrID =~/\d+/){
				next;
			}
			unless ($nmrCnt==0){
				print "\t\t\t" ;
			}
			print "$nmrID\t$nv\n";


			$spcCnt+=1;$nmrCnt+=1;
		}
		my $item=$inventory{$catalogID}{$batchID};
		if($$item{hasZG} && $$item{hasCOSY} && $$item{hasHSQC} && $$item{hasHMBC} ){
			$cntComplete+=1;
		}
	}
} 
print "found $spcCnt spectra for $cmpdCnt compounds of which $cntComplete are complete!\n";


