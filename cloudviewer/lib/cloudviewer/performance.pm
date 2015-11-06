package cloudviewer::performance;

use strict;
use warnings;
use Data::Dumper;

sub check_perf
{
my $object=shift;
my $prefix=shift;
my $check=shift;
my $header=shift;
my $status=0;
my @message=@{$header};
my $perfarray;
my $checker=0;
my $table=${$object->{performance_table}};
my $key=$table->{$check->{type}}->{$check->{nameinfo}}->{key};
my $checkdata=$check->{name};
my $performance=0;
my $value;
my $unit=$table->{$check->{type}}->{$check->{nameinfo}}->{unit};
my $func;
my $lastvalue;
my @tempvalue;


if((scalar @{$object->{performance}}) gt 0)
{
	$perfarray=$object->{performance}[0]->value;
	for my $metric (@$perfarray)
	{
		if($metric->id->counterId eq $key)
		{
			$checker=1;
			## Small Hack because Clusters return too much values
			@tempvalue=split(/,/,$metric->value);
			$lastvalue=(scalar @tempvalue)-1;
			$performance=$tempvalue[$lastvalue];
			$value=$tempvalue[$lastvalue];

			## Converting value with wanted function
			if($check->{nameinfo} eq "ready")
			{
				$value=($value / (20  * 1000)) * 100;
				$unit="%";
			}

			
			if(!$check->{'critical'} and !$check->{'warn'})
			{
				push(@message,"OK:      Performancecounter:$check->{type}:$check->{nameinfo} is green but no values defined. Value: ".$value.$unit);
			}
			else
			{

				if($value < $check->{'warn'})
				{
					push(@message,"OK:      Performancecounter:$check->{type}:$check->{nameinfo} is green. Value: $value $unit");	
				}
				elsif($value >= $check->{'warn'} and $value < $check->{'critical'})
				{
					$status=1;
			 		push(@message,"Warn:      Performancecounter:$check->{type}:$check->{nameinfo} is yellow. Value: $value $unit");
				}
				else
				{
					$status=2;
					push(@message,"Critical:      Performancecounter:$check->{type}:$check->{nameinfo} is Red. Value: $value $unit");
				}
			}
		}		
	}
	if($checker ne 1)
	{
        	$status=2;
        	push(@message,"Warning:      Wanted counter not delivered.");
	}
}
else
{
	$status=0;
	push(@message,"Warning:      No counters delivered.");
}
return {'name' => $object->{name},'message' => \@message, 'status' => $status, 'service' => $$prefix.$checkdata, performance => $performance };
}


1
