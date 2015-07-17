package cloudviewer::performance;

use strict;
use warnings;

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
my $checkdata=$check->{type}."-".$check->{nameinfo};
my $performance=0;
my $value;
my $unit=$table->{$check->{type}}->{$check->{nameinfo}}->{unit};
my $func;

if((scalar @{$object->{performance}}) gt 0)
{
	$perfarray=$object->{performance}[0]->value;
	for my $metric (@$perfarray)
	{
		if($metric->id->counterId eq $key)
		{
			$checker=1;
			$performance=$metric->value;
			$value=$metric->value;

			## Converting value with wanted function
			if($unit eq "Millisecond")
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

				if($value lt $check->{'warn'})
				{
					push(@message,"OK:      Performancecounter:$check->{type}:$check->{nameinfo} is green. Value: $value $unit");	
				}
				elsif($value gt $check->{'warn'} and $metric->value lt $check->{'critical'})
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
	$status=2;
	push(@message,"Warning:      No counters delivered.");
}

return {'name' => $object->{name},'message' => \@message, 'status' => $status, 'service' => $$prefix.$checkdata, performance => $performance };
}


1
