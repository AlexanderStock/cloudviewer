package cloudviewer::hostchecks;

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
my $Maintenance=$object->{configuration}->get_property('runtime.inMaintenanceMode');
if($Maintenance eq "false")
{
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
}
else
{
	push(@message,"OK:      Host is in Maintenance. Not checking.");
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
my $Maintenance=$object->{configuration}->get_property('runtime.inMaintenanceMode');
if($Maintenance eq "false")
{
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
}
else
{
        push(@message,"OK:      Host is in Maintenance. Not checking.");
}

return {'name' => $object->{name},'message' => \@message, 'status' => $status, 'service' => $$prefix.$checkdata->{name}, performance => $status};
}

sub ConnectionState
{
my $object=shift;
my $checkdata=shift;
my $prefix=shift;
my $header=shift;
my @message=@{$header};
my $status=0;
my $connection=$object->{configuration}->{$checkdata->{properties}[0]};
my $Maintenance=$object->{configuration}->get_property('runtime.inMaintenanceMode');
if($Maintenance eq "false")
{
        if($connection->val eq "disconnected")
        {
                $status=2;

                 push(@message,"ERROR:	Host is in State ".$connection->val);
        }
        else
        {
                push(@message,"OK:	Host is in State ".$connection->val);
        }
}
else
{
        push(@message,"OK:      Host is in Maintenance. Not checking.");
}

return {'name' => $object->{name},'message' => \@message, 'status' => $status, 'service' => $$prefix.$checkdata->{name}, performance => $status};
}

sub Hardware
{
my $object=shift;
my $checkdata=shift;
my $prefix=shift;
my $header=shift;
my $status=0;
my @message= @{$header};
my $hardware=$object->{configuration}->{$checkdata->{properties}[0]};
my $Maintenance=$object->{configuration}->get_property('runtime.inMaintenanceMode');
my $errorcounter=0;
if($Maintenance eq "false")
{
	foreach my $component (@$hardware)
	{
		if($component->healthState->key eq "red")
		{
			 push(@message,"ERROR:  Component".$component->name."is critical");
			 $errorcounter+=1;
			 $status=2;
		}
		elsif($component->healthState->key eq "yellow")
		{
			 push(@message,"WARN:  Component".$component->name."is warning");
			 $errorcounter+=1;
			 $status=1;
		}
	}
	if($errorcounter eq 0)
	{
		push(@message,"OK:  All components working normal");
		$status=0;
	}
}
else
{
        push(@message,"OK:      Host is in Maintenance. Not checking.");
}

return {'name' => $object->{name},'message' => \@message, 'status' => $status, 'service' => $$prefix.$checkdata->{name}, performance => $status};
}

sub ServiceState
{
my $object=shift;
my $checkdata=shift;
my $prefix=shift;
my $header=shift;
my @message=@{$header};
my $status=0;
my $services=$object->{configuration}->{$checkdata->{properties}[0]};
my $Maintenance=$object->{configuration}->get_property('runtime.inMaintenanceMode');
my $errorcounter=0;
if($Maintenance eq "false")
{
        foreach my $service (@$services)
        {
                if($service->running eq "1")
                {
                         push(@message,"OK:  Service".$service->label." is running");
                         $status=0;
                }
                else
                {
                         push(@message,"ERROR:  Service".$service->label." is not running");
                         $status=2;
                }
        }
}
else
{
        push(@message,"OK:      Host is in Maintenance. Not checking.");
}
return {'name' => $object->{name},'message' => \@message, 'status' => $status, 'service' => $$prefix.$checkdata->{name}, performance => $status};
}

sub NetworkState
{
my $object=shift;
my $checkdata=shift;
my $prefix=shift;
my $header=shift;
my @message=@{$header};
my $status=0;
my $vswitches=$object->{configuration}->{$checkdata->{properties}[0]};
my $vnic=$object->{configuration}->{$checkdata->{properties}[1]};
my $dvswitches=$object->{configuration}->{$checkdata->{properties}[2]};
my $pnic=$object->{configuration}->{$checkdata->{properties}[3]};
my $Maintenance=$object->{configuration}->get_property('runtime.inMaintenanceMode');
my $errorcounter=0;
my %NIC;
my @switches;
my $nic_key;
my $stdvalues=$checkdata->{stdvalues};
if($Maintenance eq "false")
{
       foreach my $nic (@{$pnic})
       {
       $NIC{$nic->key} = $nic;
       }

               foreach my $switch (@{$vswitches})
               {
			if($switch->mtu ne $stdvalues->{switchmtu})
			{
				push(@message,"ERROR:  Switch-MTU not correct for ". $switch->name .".Given value:". $switch->mtu .". Standard value:". $stdvalues->{switchmtu});	
				$status=2;
			}
			          foreach $nic_key (@{$switch->pnic})
                                  {
					#print Dumper($nic_key);
					if(!$NIC{$nic_key}->linkSpeed)
					{
						push(@message,"ERROR:  Network-Card ".$NIC{$nic_key}->device." is down.");
						$status=2;
					}
					else
					{
						push(@message,"OK:  Network-Card ".$NIC{$nic_key}->device." is up.");
					}
				}
		}

               foreach my $switch (@{$dvswitches})
               {
			if($switch->mtu ne $stdvalues->{switchmtu})
			{
				push(@message,"ERROR:  Switch-MTU not correct for ". $switch->dvsName .".Given value:". $switch->mtu .". Standard value:". $stdvalues->{switchmtu});	
				$status=2;
			}
			          foreach $nic_key (@{$switch->pnic})
                                  {
					#print Dumper($nic_key);
					if(!$NIC{$nic_key}->linkSpeed)
					{
						push(@message,"ERROR:  Network-Card ".$NIC{$nic_key}->device." is down.");
						$status=2;
					}
					else
					{
						push(@message,"OK:  Network-Card ".$NIC{$nic_key}->device." is up.");
					}
				}
		}
	
}
else
{
        push(@message,"OK:      Host is in Maintenance. Not checking.");
}
#print Dumper(@message);
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
