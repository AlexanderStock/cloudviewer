package cloudviewer::datastorechecks;

use strict;
use warnings;

sub Issues
{
my $object=shift;
my $checkdata=shift;
my $prefix=shift;
my $header=shift;
my @message=@{$header};
my $status=0;
my @dependencies=("configIssue");

if(cloudviewer::helper::checkdependency(\@dependencies,$checkdata->{properties},$object) eq 0)
{
	my $Issues=$object->{configuration}->{"configIssue"};
	if($Issues)
	{
		$status=2;

		for my $issue (@{$Issues})
		{
			push(@message,"ERROR:	".$issue->fullFormattedMessage."  Date: ".$issue->createdTime);
		}
	}
	else
	{
		push(@message,"OK:	No configuration Issues found on this object. Everything looks fine.");
	}
}
else
{
	$status=2;
	push(@message,"Error:	Configuration Items  is not defined.");
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
my @dependencies=("triggeredAlarmState");

if(cloudviewer::helper::checkdependency(\@dependencies,$checkdata->{properties},$object) eq 0)
{
	my $Alarms=$object->{configuration}->{"triggeredAlarmState"};
	if($Alarms)
	{
        	$status=1;

        	for my $alarm (@{$Alarms})
        	{
                	push(@message,"ERROR:       ".$object->{alerts}->{$alarm->alarm->value}->{desc});
        	}
	}
	else
	{
        	push(@message,"OK:	No alarms found on this object. Everything looks fine.");
	}
}
else
{
	$status=2;
	push(@message,"Error:	Configuration Items  is not defined.");
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
my $filledspacepercent=0;
my @dependencies=("summary.capacity","summary.freeSpace");

if(cloudviewer::helper::checkdependency(\@dependencies,$checkdata->{properties},$object) eq 0)
{
	my $capacity=$object->{configuration}->{"summary.capacity"};
	my $freespace=$object->{configuration}->{"summary.freeSpace"};
	my $stdvalues=$checkdata->{stdvalues};
	$filledspacepercent=(($capacity-$freespace)/$capacity)*100;

	if(!$stdvalues->{'critical'} and !$stdvalues->{'warn'})
	{
		push(@message,"OK:      Space is green but no values defined. Filed space for  $object->{name} : ".$filledspacepercent);
	}
	else
	{
		if($filledspacepercent < $stdvalues->{'warn'})
		{
			push(@message,"OK:      Space is green. Filled space for  $object->{name} : ".$filledspacepercent);
		}
		elsif($filledspacepercent >= $stdvalues->{'warn'} and $filledspacepercent  < $stdvalues->{'critical'})
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
}
else
{
	$status=2;
	push(@message,"Error:	Configuration Item  is not defined.");
}

return {'name' => $object->{name},'message' => \@message, 'status' => $status, 'service' => $$prefix.$checkdata->{name}, performance => $filledspacepercent};
}

sub OverallStatus
{
my $object=shift;
my $checkdata=shift;
my $prefix=shift;
my $header=shift;
my @message=@{$header};
my $status=0;
my @dependencies=("overallStatus");

if(cloudviewer::helper::checkdependency(\@dependencies,$checkdata->{properties},$object) eq 0)
{
	my $ostatus=$object->{configuration}->{"overallStatus"};
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
}
else
{
	$status=2;
	push(@message,"Error:	Configuration Item  not defined.");
}

return {'name' => $object->{name},'message' => \@message, 'status' => $status, 'service' => $$prefix.$checkdata->{name}, performance => $status};
}

1
