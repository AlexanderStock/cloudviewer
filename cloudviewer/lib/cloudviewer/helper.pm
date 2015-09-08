package cloudviewer::helper;

use strict;
use warnings;

sub checkdependency
{
my $firsttemp=shift;
my $secondtemp=shift;
my @firstarray=sort(@$firsttemp);
my @secondarray=sort(@$secondtemp);
my $checker=0;

for(my $item=0;$item<=@firstarray-1;$item++)
{
	if($firstarray[$item] ne $secondarray[$item])
	{
		$checker=1;
	}
}

return $checker;
}

sub checkdependencystd
{
my $firstarray=shift;
my $hash=shift;
my $checker=0;

foreach  my $item (@$firstarray)
{
	if(!$hash->{$item})
	{
		$checker=1;
	}
}

return $checker;
}

1
