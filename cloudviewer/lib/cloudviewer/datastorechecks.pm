package cloudviewer::datastorechecks;

use strict;
use warnings;
use Data::Dumper;
use Switch;

sub Issues
{
my $object=shift;
my $checkdata=shift;
my $prefix=shift;
my $header=shift;
my @message=@{$header};
my $status=0;
my $Issues=$object->{configuration}->get_property($checkdata->{properties}[0]);

	if($Issues)
	{
        	$status=2;
        	for my $issue (@{$Issues})
        	{
                	push(@message,"ERROR:   ".$issue);
        	}
	}
	else
	{
        	push(@message,"OK:      No configuration Issues found on this object. Everything looks fine.");
	}

return {'name' => $object->{name},'message' => \@message, 'status' => $status, 'service' => $$prefix.$checkdata->{name}, performance => $status};
}

sub Alarmstate
{
my $object=shift;
my $checkdata=shift;
my $prefix=shift;
my $header=shift;
my @message=@{$header};
my $status=0;
my $Alarms=$object->{configuration}->{$checkdata->{properties}[0]};

	if($Alarms)
	{
        	$status=2;

        	for my $alarm (@{$Alarms})
        	{
                	push(@message,"ERROR:       ".$alarm);
        	}
	}
	else
	{
        	push(@message,"OK:      No alarms found on this object. Everything looks fine.");
	}


return {'name' => $object->{name},'message' => \@message, 'status' => $status, 'service' => $$prefix.$checkdata->{name}, performance => $status};
}

sub Capacity
{
my $object=shift;
my $checkdata=shift;
my $prefix=shift;
my $header=shift;
my @message=@{$header};
my $status=0;
my $capacity=$object->{configuration}->{$checkdata->{properties}[0]};
my $freespace=$object->{configuration}->{$checkdata->{properties}[1]};
my $stdvalues=$checkdata->{stdvalues};

my $filledspacepercent=(($capacity-$freespace)/$capacity)*100;

if(!$stdvalues->{'critical'} and !$stdvalues->{'warn'})
{
	push(@message,"OK:      Space is green but no values defined. Filed space for  $object->{name} : ".$filledspacepercent);
}
else
{
	if($filledspacepercent lt $stdvalues->{'warn'})
	{
		push(@message,"OK:      Space is green. Filled space for  $object->{name} : ".$filledspacepercent);
	}
	elsif($filledspacepercent gt $stdvalues->{'warn'} and $filledspacepercent  lt $stdvalues->{'critical'})
	{
		$status=1;
		push(@message,"Warn:      Space is yellow. Filled space for  $object->{name} : ".$filledspacepercent);
	}
	else
	{
		$status=2;
		push(@message,"Critical:      Space is red. Filled space for  $object->{name}: ".$filledspacepercent);
	}
}

return {'name' => $object->{name},'message' => \@message, 'status' => $status, 'service' => $$prefix.$checkdata->{name}, performance => $status};
}

sub OverallStatus
{
my $object=shift;
my $checkdata=shift;
my $prefix=shift;
my $header=shift;
my @message=@{$header};
my $status=0;
my $ostatus=$object->{configuration}->{$checkdata->{properties}[0]};

if($ostatus->val eq "red")
{
	$status=2;
	push(@message,"Critical:      Overall Status is Red!");
}
if($ostatus->val eq "yellow")
{
	$status=1;
	push(@message,"Warn:      Overall Status is Yellow!");
}
if($ostatus->val eq "green")
{
	$status=0;
	push(@message,"OK:      Overall Status is green!");
}

return {'name' => $object->{name},'message' => \@message, 'status' => $status, 'service' => $$prefix.$checkdata->{name}, performance => $status};
}

1
