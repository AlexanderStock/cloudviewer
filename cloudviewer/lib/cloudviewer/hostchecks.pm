package cloudviewer::hostchecks;

use strict;
use warnings;
use Data::Dumper;

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
	my $Issues=$object->{configuration}->get_property("configIssue");
	my $Maintenance=$object->{configuration}->get_property('runtime.inMaintenanceMode');
	if($Maintenance eq "false")
	{
		if($Issues)
		{
        		$status=2;
        		for my $issue (@{$Issues})
        		{
                		push(@message,"ERROR:   ".$issue->fullFormattedMessage."  Date: ".$issue->createdTime);
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
}
else
{
	$status=2;
	push(@message,"Error:	Configuration Item  not defined.");
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
	my $Maintenance=$object->{configuration}->get_property('runtime.inMaintenanceMode');
	if($Maintenance eq "false")
	{
		if($Alarms)
		{
        		$status=2;

        		for my $alarm (@{$Alarms})
        		{
                		push(@message,"ERROR:       ".$object->{alerts}->{$alarm->alarm->value}->{desc});
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
}
else
{
	$status=2;
	push(@message,"Error:	Configuration Item  not defined.");
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
my @dependencies=("runtime.connectionState");

if(cloudviewer::helper::checkdependency(\@dependencies,$checkdata->{properties},$object) eq 0)
{
	my $connection=$object->{configuration}->{"runtime.connectionState"};
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
}
else
{
	$status=2;
	push(@message,"Error:	Configuration Item  not defined.");
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
my @dependencies=("summary.runtime.healthSystemRuntime.systemHealthInfo.numericSensorInfo","summary.runtime.healthSystemRuntime.hardwareStatusInfo");

if(cloudviewer::helper::checkdependency(\@dependencies,$checkdata->{properties},$object) eq 0)
{
	my $sensor=$object->{configuration}->{"summary.runtime.healthSystemRuntime.systemHealthInfo.numericSensorInfo"};
	my $hardware=$object->{configuration}->{"summary.runtime.healthSystemRuntime.hardwareStatusInfo"};
	my $Maintenance=$object->{configuration}->get_property('runtime.inMaintenanceMode');
	my $errorcounter=0;
	
	if($Maintenance eq "false")
	{
		foreach my $component (@$sensor)
		{
			if($component->healthState->key eq "Red")
			{
				 push(@message,"ERROR:  Component".$component->name."is critical");
				 $errorcounter+=1;
				 $status=2;
			}
			elsif($component->healthState->key eq "Yellow")
			{
				 push(@message,"WARN:  Component".$component->name."is warning");
			 	$errorcounter+=1;
			 	$status=1;
			}
		}

                if($hardware->cpuStatusInfo)
                {
                	foreach my $component (@{$hardware->cpuStatusInfo})
                	{
                        	if($component->status->key eq "Red")
                        	{
                                	 push(@message,"ERROR:  Component".$component->name."is critical");
                                 	$errorcounter+=1;
                                 	$status=2;
                        	}
                        	elsif($component->status->key eq "Yellow")
                        	{
                                	 push(@message,"WARN:  Component".$component->name."is warning");
                                	$errorcounter+=1;
                                	$status=1;
                        	}
                	}
		}
		if($hardware->memoryStatusInfo)
		{
                	foreach my $component (@{$hardware->memoryStatusInfo})
                	{
                       	if($component->status->key eq "Red")
                        	{
                                	 push(@message,"ERROR:  Component".$component->name."is critical");
                                 	$errorcounter+=1;
                                	 $status=2;
                        	}
                        	elsif($component->status->key eq "Yellow")
                        	{
                               	  	push(@message,"WARN:  Component".$component->name."is warning");
                               		 $errorcounter+=1;
                                	$status=1;
                        	}
                	}
		}
                if($hardware->storageStatusInfo)
                {
                	foreach my $component (@{$hardware->storageStatusInfo})
                	{
                        	if($component->status->key eq "Red")
                        	{
                               		 push(@message,"ERROR:  Component".$component->name."is critical");
                                 	$errorcounter+=1;
                                 	$status=2;
                        	}
                        	elsif($component->status->key eq "Yellow")
                        	{
                                	 push(@message,"WARN:  Component".$component->name."is warning");
                                	$errorcounter+=1;
                                	$status=1;
                        	}
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
}
else
{
	$status=2;
	push(@message,"Error:	Configuration Item  not defined.");
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
my $servicename;
my $status=0;
my $overallstatus=0;
my @dependencies=("config.service.service");

if(cloudviewer::helper::checkdependency(\@dependencies,$checkdata->{properties},$object) eq 0)
{
	my $services=$object->{configuration}->{$checkdata->{properties}[0]};
	my $Maintenance=$object->{configuration}->get_property('runtime.inMaintenanceMode');
	my $errorcounter=0;
	my $stdvalues=$checkdata->{stdvalues};
	if($Maintenance eq "false")
	{
        	foreach my $service (@$services)
        	{
			$servicename=$service->key;
			if(defined($stdvalues->{$servicename}))
			{
                		if($service->running eq $stdvalues->{$servicename} )
                		{
                       		 	push(@message,"--> Configured Service OK:  Service ".$service->label." is in wanted state.");
                       		 	$status=0;
             		 	 }
               			else
                		{
                         		push(@message,"--> Configured Service ERROR:  Service ".$service->label." is not in wanted state.");
                       			$status=2;
               			 }
			}
			else
			{
                		if($service->running eq "1" )
                		{
                       			 push(@message,"OK:  Service ".$service->label." is running");
                       		 	$status=0;
             		   	}
               			else
                		{
                         		push(@message,"Warn:  Service ".$service->label." is not running");
                       			$status=1;
               		 	}
      		  	}
      		  if($status gt $overallstatus)
		  {
		      $overallstatus=$status;
		  }
		}
	}
	else
	{
        	push(@message,"OK:      Host is in Maintenance. Not checking.");
	}
}
else
{
	$status=2;
	push(@message,"Error:	Configuration Item  not defined.");
}

return {'name' => $object->{name},'message' => \@message, 'status' => $overallstatus, 'service' => $$prefix.$checkdata->{name}, performance => $status};
}

sub NetworkState
{
my $object=shift;
my $checkdata=shift;
my $prefix=shift;
my $header=shift;
my @message=@{$header};
my $status=0;
my @dependencies=("config.network.vswitch","config.network.vnic","config.network.proxySwitch","config.network.pnic");
my @dependencies_std=("switchmtu");

if(cloudviewer::helper::checkdependency(\@dependencies,$checkdata->{properties},$object) eq 0 and cloudviewer::helper::checkdependencystd(\@dependencies_std,$checkdata->{stdvalues}) eq 0)
{
	my $vswitches=$object->{configuration}->{"config.network.vswitch"};
	my $vnic=$object->{configuration}->{"config.network.vnic"};
	my $dvswitches=$object->{configuration}->{"config.network.proxySwitch"};
	my $pnic=$object->{configuration}->{"config.network.pnic"};
	my $Maintenance=$object->{configuration}->get_property("runtime.inMaintenanceMode");
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
}
else
{
        $status=2;
        push(@message,"Error:   Configuration Item  not defined.");
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

if(cloudviewer::helper::checkdependency(\@dependencies,$checkdata->{properties},$object) eq 0)
{
	my $ostatus=$object->{configuration}->{$checkdata->{properties}[0]};
	my $Maintenance=$object->{configuration}->get_property('runtime.inMaintenanceMode');

	if($Maintenance eq "false")
	{
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
        	push(@message,"OK:      Host is in Maintenance. Not checking.");
	}
}
else
{
        $status=2;
        push(@message,"Error:   Configuration Item  not defined.");
}


return {'name' => $object->{name},'message' => \@message, 'status' => $status, 'service' => $$prefix.$checkdata->{name}, performance => $status};
}						
	
sub ComponentCheck
{
my $object=shift;
my $checkdata=shift;
my $prefix=shift;
my $header=shift;
my $status=0;
my @message= @{$header};
my @dependencies=("summary.runtime.healthSystemRuntime.systemHealthInfo.numericSensorInfo");

if(cloudviewer::helper::checkdependency(\@dependencies,$checkdata->{properties},$object) eq 0)
{
	my $components=$object->{configuration}->{$checkdata->{properties}[0]};
	my $Maintenance=$object->{configuration}->get_property('runtime.inMaintenanceMode');
	my $errorcounter=0;
	my %errorlist;
	my $stdcomponents=$checkdata->{stdvalues};
	if($Maintenance eq "false")
	{
		foreach my $stdcomponent (keys %$stdcomponents)
		{
			foreach my $component (@$components)
			{
				if(($component->name) eq $stdcomponents->{$stdcomponent})
				{
					push(@message,"OK:  Component: ".$component->name."was found");
					$errorlist{$stdcomponents->{$stdcomponent}}=0;
					last;
				}
				else
				{
					$errorlist{$stdcomponents->{$stdcomponent}}=1;
				}
			}
		}
		foreach my $error (keys %errorlist)
		{
			if($errorlist{$error} eq 1)
			{
				push(@message,"Error:  Component: ".$error."was not found");
				$status=1;
			}
		}
	}
	else
	{
        	push(@message,"OK:      Host is in Maintenance. Not checking.");
	}
}
else
{
	$status=2;
	push(@message,"Error:	Configuration Item  not defined.");
}
#print Dumper(@message);
return {'name' => $object->{name},'message' => \@message, 'status' => $status, 'service' => $$prefix.$checkdata->{name}, performance => $status};
}


1
