package cloudviewer::clusterchecks;

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
my $Issues=$object->{configuration}->{$checkdata->{properties}[0]};
if($Issues)
{
	$status=1;

	for my $issue (@{$Issues})
	{
		push(@message,"ERROR:	".$issue);
	}
}
else
{
	push(@message,"OK:	No configuration Issues found on this object. Everything looks fine.");
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
        $status=1;

        for my $alarm (@{$Alarms})
        {
                push(@message,"ERROR:       ".$alarm);
        }
}
else
{
        push(@message,"OK:	No alarms found on this object. Everything looks fine.");
}

return {'name' => $object->{name},'message' => \@message, 'status' => $status, 'service' => $$prefix.$checkdata->{name}, performance => $status};
}
sub DRSstate
{
my $object=shift;
my $checkdata=shift;
my $prefix=shift;
my $header=shift;
my @message=@{$header};
my $status=0;
my $drsobj=$object->{configuration}->{$checkdata->{properties}[0]};
my $stdvalues=$checkdata->{stdvalues};
if($drsobj->vmotionRate eq $stdvalues->{vmotionRate})
{
	push(@message,"OK:	vMotionRate set like expected");
}
else
{
        push(@message,"Error:	vMotionRate not set like expected");
	$status=1;
}
if($drsobj->enableVmBehaviorOverrides eq $stdvalues->{enableVmBehaviorOverrides})
{
        push(@message,"OK:	enableVmBehaviorOverrides set like expected");
}
else
{
        push(@message,"Error:	enableVmBehaviorOverrides not set like expected");
        $status=1;
}
if($drsobj->enabled eq $stdvalues->{enabled})
{
        push(@message,"OK:	Enabled set like expected");
}
else
{
        push(@message,"Error:	Enabled not set like expected");
        $status=1;
}
return {'name' => $object->{name},'message' => \@message, 'status' => $status, 'service' => $$prefix.$checkdata->{name}, performance => $status};
}
sub DASstate
{
my $object=shift;
my $checkdata=shift;
my $prefix=shift;
my $status=0;
my $header=shift;
my @message=@{$header};
my $dasobj=$object->{configuration}->{$checkdata->{properties}[0]};
my $stdvalues=$checkdata->{stdvalues};
if($dasobj->admissionControlEnabled eq $stdvalues->{admissionControlEnabled})
{
        push(@message,"OK:	admissionControlEnabled set like expected");
}
else
{
        push(@message,"Error:	admissionControlEnabled not set like expected");
        $status=1;
}
if($dasobj->hostMonitoring eq $stdvalues->{hostMonitoring})
{
        push(@message,"OK:	hostMonitoring set like expected");
}
else
{
        push(@message,"Error:	hostMonitoring not set like expected");
        $status=1;
}
if($dasobj->enabled eq $stdvalues->{enabled})
{
        push(@message,"OK:	Enabled set like expected");
}
else
{
        push(@message,"Error:	Enabled not set like expected");
        $status=1;
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
