package cloudviewer::vmchecks;

use strict;
use warnings;
use Time::Piece;

sub GuestDisks
{
my $object=shift;
my $checkdata=shift;
my $prefix=shift;
my $header=shift;
my @message=@{$header};
my $status=0;
my @dependencies=("guest.disk");

if(cloudviewer::helper::checkdependency(\@dependencies,$checkdata->{properties}) eq 0)
{
	my $Disks=$object->{configuration}->get_property("guest.disk");
	my $stdvalues=$checkdata->{stdvalues};
	my $filledspace;
	my $diskname;

	foreach my $Disk (@$Disks)
	{
		$filledspace=(($Disk->capacity - $Disk->freeSpace)/$Disk->capacity)*100;
		$diskname=$Disk->diskPath;
		if(!$stdvalues->{'critical'} and !$stdvalues->{'warn'})
		{
					push(@message,"OK:      Diskspace is green but no values defined. Filled space for $diskname : ".$filledspace);
		}
		else
		{

				if($filledspace lt $stdvalues->{'warn'})
				{
					push(@message,"OK:      Diskspace is green. Filled space for $diskname : ".$filledspace);
				}
				elsif($filledspace gt $stdvalues->{'warn'} and $filledspace  lt $stdvalues->{'critical'})
				{
					$status=1;
					push(@message,"Warn:      Diskspace is yellow. Filled space for $diskname : ".$filledspace);
				}
				else
				{
					$status=2;
					push(@message,"Critical:      Diskspace is red. Filled space for $diskname : ".$filledspace);
				}
		}
	}
}
else
{
	$status=2;
	push(@message,"Error:	Configuration Item  not defined.");
}

return {'name' => $object->{name},'message' => \@message, 'status' => $status, 'service' => $$prefix.$checkdata->{name}, performance => $status};
}

sub GuestConnectionState
{
my $object=shift;
my $checkdata=shift;
my $prefix=shift;
my $header=shift;
my @message=@{$header};
my $status=0;
my @dependencies=("summary.runtime.connectionState");

if(cloudviewer::helper::checkdependency(\@dependencies,$checkdata->{properties}) eq 0)
{
	my $constate=$object->{configuration}->{"summary.runtime.connectionState"};
	if($constate->val  ne "connected")
	{
		$status=2;
	 	push(@message,"Critical:      VM is not connected. VM is in state : ".$constate);
	}
	else
	{
		push(@message,"OK:      VM is  connected. ");
	}
}
else
{
	$status=2;
	push(@message,"Error:	Configuration Items  is not defined.");
}
	
return {'name' => $object->{name},'message' => \@message, 'status' => $status, 'service' => $$prefix.$checkdata->{name}, performance => $status};
}

sub GuestInstallermount
{
my $object=shift;
my $checkdata=shift;
my $prefix=shift;
my $header=shift;
my @message=@{$header};
my $status=0;
my @dependencies=("summary.runtime.toolsInstallerMounted");

if(cloudviewer::helper::checkdependency(\@dependencies,$checkdata->{properties}) eq 0)
{
	my $installermount=$object->{configuration}->{"summary.runtime.toolsInstallerMounted"};
	if($installermount  ne "false")
	{
		$status=1;
	 	push(@message,"Critical:      VM has Installer mounted. ");
	}
	else
	{
		push(@message,"OK:      VM has no installer mounted. ");
	}
}
else
{
	$status=2;
	push(@message,"Error:	Configuration Items  is not defined.");
}

return {'name' => $object->{name},'message' => \@message, 'status' => $status, 'service' => $$prefix.$checkdata->{name}, performance => $status};
}

sub GuestSnapshots
{
my $object=shift;
my $checkdata=shift;
my $prefix=shift;
my $header=shift;
my @message=@{$header};
my $status=0;
my @dependencies=("snapshot.rootSnapshotList");

if(cloudviewer::helper::checkdependency(\@dependencies,$checkdata->{properties}) eq 0)
{
	my $snapshots=$object->{configuration}->{"snapshot.rootSnapshotList"};
	my $stdvalues=$checkdata->{stdvalues};
	my @temparray;
	my @returnlist;

	if($snapshots)
	{
		@returnlist=GuestSnapshots_recursiv_helper($snapshots);
		foreach my $snapshot (@returnlist)
		{
			if(!$stdvalues->{'critical'} and !$stdvalues->{'warn'})
			{
				push(@message,"OK:      Snapshot is green but no values defined. Days for $snapshot->{name} : ".$snapshot->{days});
			}
			else
			{
				if($snapshot->{days} lt $stdvalues->{'warn'})
				{
					push(@message,"OK:      Snapshot $snapshot->{name} is ok. Days : ".$snapshot->{days});
				}
				elsif($snapshot->{days} gt $stdvalues->{'warn'} and $snapshot->{days}  lt $stdvalues->{'critical'})
				{
					$status=1;
					push(@message,"Warn:      Snapshot $snapshot->{name} is in state warning. Days : ".$snapshot->{days});
				}
				else
				{
					$status=2;
					push(@message,"Critical:      Snapshot $snapshot->{name} is too old. Days : ".$snapshot->{days});
				}
			}
		}	
	}
	else
	{
		push(@message,"OK:      No Snapshots found. ");
	}
}
else
{
	$status=2;
	push(@message,"Error:	Configuration Items  is not defined.");
}
return {'name' => $object->{name},'message' => \@message, 'status' => $status, 'service' => $$prefix.$checkdata->{name}, performance => $status};
}

sub GuestSnapshots_recursiv_helper
{
my $snaplist=shift;
my @templist;
my $before;
my $diff;
my $intdays;
my @returnlist;
my $snapshotdate;
my $snapshotname;
my @temparray;
my $currentdate=localtime;
	
foreach my $snapshot (@$snaplist)
{
	if($snapshot->childSnapshotList)
	{
		@returnlist=GuestSnapshots_recursiv_helper($snapshot->childSnapshotList);
		@templist=(@templist,@returnlist);
	}
	$snapshotdate=$snapshot->createTime;
	$snapshotname=$snapshot->name;
	@temparray=split(/T/,$snapshotdate);
	@temparray=split(/-/,$temparray[0]);
	$before = Time::Piece->strptime("$temparray[0]/$temparray[1]/$temparray[2]", "%Y/%m/%d");
	$diff = $currentdate - $before;
	$intdays=int($diff->days);
	push(@templist,{'name'=>$snapshotname,'days'=>$intdays});
}
return @templist;
}

sub Issues
{
my $object=shift;
my $checkdata=shift;
my $prefix=shift;
my $header=shift;
my @message=@{$header};
my $status=0;
my @dependencies=("configIssue");

if(cloudviewer::helper::checkdependency(\@dependencies,$checkdata->{properties}) eq 0)
{
	my $Issues=$object->{configuration}->{"configIssue"};
	if($Issues)
	{
		$status=2;

		for my $issue (@{$Issues})
		{
			push(@message,"ERROR:	".$issue);
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

if(cloudviewer::helper::checkdependency(\@dependencies,$checkdata->{properties}) eq 0)
{
	my $Alarms=$object->{configuration}->{"triggeredAlarmState"};
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
}
else
{
	$status=2;
	push(@message,"Error:	Configuration Items  is not defined.");
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
my @dependencies=("overallStatus");

if(cloudviewer::helper::checkdependency(\@dependencies,$checkdata->{properties}) eq 0)
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
