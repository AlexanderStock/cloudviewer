package cloudviewer::connector;

use strict;
use warnings;
use JSON;

sub new
{

my $class=shift;
my $configfile=shift;

my $self={
	updatemode=>"0",
	dependencies=>{},
	config=>{},
	cluster=>[],
	host=>[],
	datastore=>[],
	vm=>[],
	nagios=>{
		cluster=>[],
		host=>[],
		datastore=>[],
		vm=>[],
		services=>{
			  cluster=>[],
               		  host=>[],
                	  datastore=>[],
                	  vm=>[],
			  },
		},
	};
bless $self, $class;
$self->{config}=$self->set_config(\$configfile);
return $self;
}

###############################################################
## Transform JSON Data from File to a Perlhash and return it ##
###############################################################
sub set_config
{
my $self=shift;
my $configfile=shift;
my $json;

{
	local $/;
	open(FILE,$$configfile) or die "Error while opening file $$configfile";
	$json=<FILE>;
	close(FILE);
}

return decode_json($json);
}

###############################################################
## Set Update Mode.                       		     ##
###############################################################
sub set_updatemode
{
my $self=shift;
$self->{updatemode}=1;
}

###############################################################
## Giveback all available modes				     ##
###############################################################
sub get_modes
{
my $self=shift;
my @giveback;
foreach my $mode (sort keys %{$self->{config}->{Monitoring}})
{
	if($mode ne "vcenterdata" and $$self{config}{Monitoring}{$mode}{enabled} eq 1)
	{
		push(@giveback,$mode);
	}
}
return @giveback;
}
##############################################################################
## Get informations about not neede objecttypes                             ##
##############################################################################
sub get_oldmodes
{
my $self=shift;
my @giveback;
foreach my $mode (sort keys %{$self->{config}->{Monitoring}})
{
        if($mode ne "vcenterdata" and $$self{config}{Monitoring}{$mode}{enabled} eq 0)
        {
                push(@giveback,$mode);
        }
}
return @giveback;
}

################################################################
## Connect to vCenter and get all configured data for Objects ##
################################################################
sub get_vcenterdata
{
my $self=shift;
my @modes=$self->get_modes();
my $url=$$self{config}{Monitoring}{vcenterdata}{vcenterurl};
my $user=$$self{config}{Monitoring}{vcenterdata}{vcenteruser};
my $pw=$$self{config}{Monitoring}{vcenterdata}{vcenterpasswd};
my $vcid=$$self{config}{Monitoring}{vcenterdata}{vcenterID};
my $sessiondir=$$self{config}{Monitoring}{vcenterdata}{sessiondir};
my $checks;
my $config;
my $properties;
my $metrics;
my $perf_query_spec;
my $perf_data;
my $view;
my $content;
my $view_type;
my $interval;
my $perfmgr_view;
my $perf_metrics_all;
my $perf_metric_ids;
my $perf_metric_table;
my %dependenciehash;
my $parent;
my $item;
my $tempname;
my $alarmMgr;
my $alarmList;
my %alarmdesc;
my $tempalert;

if($sessiondir !~ /^\/([a-z0-9]*\/?)*\/$/)
{
	$sessiondir=$sessiondir."/";
}

my $vcname=join("",$url =~ /\/\/([\d|\D]+)\:/);
my $sessionfile_name=$sessiondir.$vcname;

if(-e $sessionfile_name)
{
	eval {Vim::load_session(session_file => $sessionfile_name)}; ##Testing the connection with a sessionfile
	if ($@ =~ /The session is not authenticated/gi)
	{
		unlink $sessionfile_name;
		eval{Util::connect($url,$user,$pw)}; ##Testing the connection without a sessionfile
		if ($@)
		{
			die "Connect-Error: $@";
		}
		Vim::save_session(session_file => $sessionfile_name)or die "Could not save session";
	}
}
else
{
		eval{Util::connect($url,$user,$pw)}; ##Testing the connection without a sessionfile
		if ($@)
		{
			die "Connect-Error: $@";
		}
		eval{Vim::save_session(session_file => $sessionfile_name)} or die "Could not save session";
		print $@;
}
## Get content object
$content = Vim::get_service_content();
## Get Performance Manager Object
$perfmgr_view = Vim::get_view(mo_ref => Vim::get_service_content()->perfManager);
##Get all available metrics
$perf_metrics_all=$perfmgr_view->perfCounter;
##Get all Alertdefinitions
$alarmMgr  = Vim::get_view(mo_ref => Vim::get_service_content()->alarmManager);

foreach my $mode (@modes)
{
       	if($mode eq "cluster")
        {
               	$view_type="ClusterComputeResource";
               	$interval=300;
		$config={"name"=>"name"};
        }
        elsif($mode eq "datastore")
        {
               	$view_type="Datastore";
               	$interval=300;
		$config={"name"=>"name"};
        }
        elsif($mode eq "host")
        {
               	$view_type="HostSystem";
              	$interval=20;
		$config={"name"=>"name","ip"=>"summary.managementServerIp","maintenance"=>"runtime.inMaintenanceMode","parent"=>"parent","power"=>"runtime.powerState"};
        }	
        elsif($mode eq "vm")
        {
               	$view_type="VirtualMachine";
               	$interval=20;
		$config={"name"=>"name","ip"=>"guest.ipAddress","parent"=>"runtime.host","storage"=>"datastore","power"=>"runtime.powerState"};
        }
        if($$self{updatemode} eq 0)
      	{
                $checks=$$self{config}{Monitoring}{$mode}{checks};
                $properties=$self->get_propertielist($checks,$config);
                $metrics=$$self{config}{Monitoring}{$mode}{performancemetrics};
                $alarmList = $alarmMgr->GetAlarm();

		for my $alert (@$alarmList)
		{
		  $tempalert=Vim::get_view(mo_ref => $alert);
		  $alarmdesc{$alert->value}={desc => $tempalert->info->description};
		}

		## Getting data from vcenter
		eval{
		$view = Vim::find_entity_views(view_type => $view_type, properties => $properties);
		print scalar @$view." items from type $mode found.\n";

		##Get PerfMetrics from first Object of each view
		($perf_metric_ids,$perf_metric_table)	 	= $self->filter_metric($perf_metrics_all,$metrics);
		};
		if ($@)
		{
        		die "Error: $@";
		}

		##Get Performance data for all Objecttypes
		foreach my $i (@$view)
		{
			$tempname=$i->name;
			if($i->name =~ /[^A-Za-z0-9#\.\-_]/g)
			{
				$tempname=~s/[^A-Za-z0-9#\.\-_]/ /g;
			}
				
			$perf_query_spec = PerfQuerySpec->new(entity => $i,metricId => $perf_metric_ids, format => 'csv', intervalId => $interval, maxSample => 1);
			$perf_data = $perfmgr_view->QueryPerf(querySpec => $perf_query_spec);
			if($mode eq "cluster")
			{
				$parent="";
				$dependenciehash{cluster}{$i->{mo_ref}->value}={name => $tempname." in ".$vcid};
			}
                        if($mode eq "host")
                        {
				$item="parent";
                                $parent=$dependenciehash{cluster}{$i->get_property($item)->value}{name};
                                $dependenciehash{host}{$i->{mo_ref}->value}={name => $tempname." in ".$vcid};
                        }
                        if($mode eq "vm")
                        {
				$item="runtime.host";
				#Set ID of VM in Hostname
				$tempname=$tempname." ++".$i->{'mo_ref'}->value."++";
                                $parent=$dependenciehash{host}{$i->get_property($item)->value}{name};
                        }


			push(@{$self->{$mode}},{performance_table=>$perf_metric_table,performance=>$perf_data,name=>$tempname." in $vcid",configuration=>$i,parent => $parent,alerts => \%alarmdesc});
		}
	}
	else
	{
                $checks=[];
                $properties=$self->get_propertielist($checks,$config);
                
		eval{
                $view = Vim::find_entity_views(view_type => $view_type, properties => $properties);
                };
                if ($@)
                {
                        die "Error: $@";
                }
		foreach my $i (@$view)
                {
			$tempname=$i->name;
			if($i->name =~ /[^A-Za-z0-9#\.\-_]/g)
			{
				$tempname=~s/[^A-Za-z0-9#\.\-_]/ /g;
			}
                        if($mode eq "cluster")
                        {
                                $parent="";
                                $dependenciehash{cluster}{$i->{mo_ref}->value}={name => $tempname." in ".$vcid};
                        }
                        if($mode eq "host")
                        {
                                $item="parent";
                                $parent=$dependenciehash{cluster}{$i->get_property($item)->value}{name};
                                $dependenciehash{host}{$i->{mo_ref}->value}={name => $tempname." in ".$vcid};
                        }
                        if($mode eq "vm")
                        {
                                $item="runtime.host";
				#Set ID of VM in Hostname
				$tempname=$tempname." ++".$i->{'mo_ref'}->value."++";
                                $parent=$dependenciehash{host}{$i->get_property($item)->value}{name};
                        }

                        push(@{$self->{$mode}},{performance_table=>"",performance=>"",name=>$tempname." in $vcid",configuration=>$i,parent => $parent});
                }
	}
}

Util::disconnect();
}
##########################################################################
## Get all needed Properties for the checks and give them back as array ##
##########################################################################
sub get_propertielist
{
my $self = shift;
my $checks = shift;
my $config = shift;
my @array;
my %temphash;
my $temp;

my %tempconfig=%$config;

foreach my $i (keys %tempconfig)
{
	$temp=$tempconfig{$i};
	push(@array,$temp);
}

foreach my $y (@$checks)
{
	$temp=$y->{properties};
	foreach my  $x (@{$temp})
	{
		if(! $temphash{$x})
		{
			push(@array,$x);	
			$temphash{$x}=1;
		}
	}
}
return \@array;
}
##################################################################
## Filter all available Metrics with he settings from JSON File ##
##################################################################
sub filter_metric
{
my $self = shift;
my $array = shift;
my $filterlist = shift;
my @newarray;
my $newhash;
my $idobj;


foreach my $i (@$filterlist)
{
	for my $y (@$array)
	{
		if($i->{type} eq $y->groupInfo->label and $i->{rolluptype} eq $y->rollupType->val and $i->{nameinfo} eq $y->nameInfo->key)
		{	
			$idobj=PerfMetricId->new(counterId => $y->key,instance => '' ); 
			push(@newarray,$idobj);
			##Creating an extra Hashref because PerfMetricId does not support a Label attribute
			$newhash->{$i->{type}}->{$i->{nameinfo}}={key => $y->key,unit=>$y->unitInfo->label};
		}
	}
}
return (\@newarray,\$newhash);
}
##############################################################################
## Get informations about hostgroups of each object type		    ##
##############################################################################
sub get_hostgroups
{
my $self=shift;
my $modus=shift;
my $id=$$self{config}{Monitoring}{vcenterdata}{vcenterID};
my @modes;
if($modus eq 1)
{
	@modes=$self->get_modes();
}
elsif($modus eq 0)
{
	@modes=$self->get_oldmodes();
}
my $giveback={};

foreach my $mode (@modes)
{
	$giveback->{$mode}=$id."-".$mode;
}
return \$giveback;
}

##############################################################################
## Get he internal VCenter ID				                    ##
##############################################################################
sub get_vcid
{
my $self=shift;
my $id=$$self{config}{Monitoring}{vcenterdata}{vcenterID};

return $id;
}
##############################################################################
## Get the path for Nagios Domainsocket				                    ##
##############################################################################
sub get_domainsocket
{
my $self=shift;
my $socket=$$self{config}{Monitoring}{vcenterdata}{domainsocket};

return $socket;
}
##############################################################################
## Get informations about hostgroups of each object type                    ##
##############################################################################
sub get_checks
{
my $self=shift;
my @modes=$self->get_modes();
my $id=$$self{config}{Monitoring}{vcenterdata}{vcenterID};
my $arrays;
my $checks;
my $external;
my $metrics;

foreach my $mode (@modes)
{
	$checks=$$self{config}{Monitoring}{$mode}{checks};
	$metrics=$$self{config}{Monitoring}{$mode}{performancemetrics};
	$external=$$self{config}{Monitoring}{$mode}{externalchecks};

	foreach my $y (@$checks)
	{
        	push(@{$arrays->{$mode}},{name => $id."-".$mode."-".$y->{name},cmd => "",period => ""});
	}
	foreach my $x (@$metrics)
	{
        	push(@{$arrays->{$mode}},{name => $id."-".$mode."-".$x->{'name'},cmd => "",period => ""});
	}
        foreach my $z (@$external)
        {
                push(@{$arrays->{$mode}},{name => $id."-".$mode."-".$z->{name},cmd => $z->{cmd},period => $z->{period}} );
        }

}

return $arrays;
}
###################################################################################################
## Get Informations about existing hosts from Monitorig System and Filter it with note attribute ##
###################################################################################################
sub set_existingobjects
{
my $self=shift;
my $hash=shift;
my $type=shift;
my $mainhash=$hash->{main};

$self->{nagios}->{$type}=$mainhash;
}
#############################################################################################
## Get Informations about services from Monitorig System and Filter it with note attribute ##
#############################################################################################
sub set_existingservices
{
my $self=shift;
my $hash=shift;
my $type=shift;
my $mainhash=$hash->{main};

$self->{nagios}->{services}->{$type}=$mainhash;
}
########################################################################
## Get a list of objects which are not configured in vcenter anymore  ##
########################################################################
sub get_old
{
my $self=shift;
my $mode=shift;
my $tester=0;
my %giveback;
my @modes=$self->get_modes();
my $temp;
my $item;
my $ip;


foreach my $mode (@modes)
{
	if($self->{nagios}->{$mode})
	{
		foreach  my $i (keys %{$self->{nagios}->{$mode}})
		{
			$tester=0;
			foreach  my $y (@{$self->{$mode}})
			{
	                        $temp=$y->{'configuration'};
				if($mode eq 'vm')
				{
					$item="guest.ipAddress";
				}
				elsif($mode eq 'host')
				{
					$item="summary.managementServerIp";
				}
                	        ## Check if objects which should have an ip have it and set the value
                        	if($mode eq 'vm' or $mode eq 'host')
                        	{
                                	if($temp->{$item})
                                	{
                                        	$ip=$temp->{$item};
                                	}
                                	else
                                	{
                                        	$ip=$y->{name};
                                	}
                        	}
                        	else
                        	{
                                	$ip=$y->{name};
                        	}

				if($i eq $y->{name} and $self->{nagios}->{$mode}->{$i}->{parent} eq $y->{parent} and $self->{nagios}->{$mode}->{$i}->{ip} eq $ip)
				{
					$tester=1;
					last;
				}
				
			}
                        if($tester eq 0)
                        {
                                push(@{$giveback{$mode}},{name => $i});
                        }
                }
	}
}
return \%giveback;
}
###############################################################################
## Get a list of objects which are not yet defined in the monitoring system  ##
###############################################################################
sub get_new
{
my $self=shift;
my $ip="";
my $name;
my $temp;
my %giveback;
my $checker;
my $item;
my @modes=$self->get_modes();

foreach my $mode (@modes)
{
	if($self->{nagios}->{$mode})
	{
		foreach my $i (@{$self->{$mode}})
		{
			$temp=$i->{'configuration'};
                        $checker=1;
			if($mode eq 'vm')
			{
				$item="guest.ipAddress";
			}
			elsif($mode eq 'host')
			{
				$item="summary.managementServerIp";
			}
			## Check if objects which should have an ip have it and set the value
                        if($mode eq 'vm' or $mode eq 'host')
			{
				if($temp->{$item})
				{
                        		$ip=$temp->{$item};
				}
				else
				{
					$ip=$i->{name};
				}
                        }
			else
			{
				$ip=$i->{name};
			}
			## Check if object name and object ip is already configured
               		if($self->{nagios}->{$mode}->{$i->{name}} and $self->{nagios}->{$mode}->{$i->{name}}->{parent} eq $i->{parent} and $self->{nagios}->{$mode}->{$i->{name}}->{ip} eq $ip)
                	{
				$checker=0;
                	}
			if($checker eq 1)
			{
				push(@{$giveback{$mode}},{name => $i->{name}, ip => $ip, parent => $i->{parent}});
			}
		}
	}
	else
	{
		foreach my $i (@{$self->{$mode}})
        	{
			$temp=$i->{'configuration'};
                        $checker=1;
                        $item=$$self{config}{Monitoring}{$mode}{configurationitems}{ip};
                        ## Check if objects which should have an ip have it and set the value
                        if($mode eq 'vm' or $mode eq 'host')
                        {
                                if($temp->{$item})
                                {
                                        $ip=$temp->{$item};
                                }
                                else
                                {
                                        $ip=$i->{name};
                                }
                        }
                        else
                        {
                                $ip=$i->{name};
                        }
			push(@{$giveback{$mode}},{name => $i->{name}, ip => $ip, parent => $i->{parent}});
		}
	}
}
return \%giveback;
}
###############################################################################
## Get a list of services which are not yet defined in the monitoring system ##
###############################################################################
sub get_newservices
{
my $self=shift;
my $checker;
my %giveback;
my @modes=$self->get_modes();
my $jsonchecks=$self->get_checks;

foreach my $mode (@modes)
{
        if($self->{nagios}->{services}->{$mode})
        {
                foreach my $i (@{$jsonchecks->{$mode}})
                {
			 $checker=1;
			 if($self->{nagios}->{services}->{$mode}->{$i->{name}}  and $self->{nagios}->{services}->{$mode}->{$i->{name}}->{cmd} eq $i->{cmd} and $self->{nagios}->{services}->{$mode}->{$i->{name}}->{period} eq $i->{period})
                         {
                                 $checker=0;
                         }

			if($checker eq 1)
			{
				push(@{$giveback{$mode}},$i);	
			}
		}
	}
	else
	{
                foreach my $i (@{$jsonchecks->{$mode}})
                {
			push(@{$giveback{$mode}},$i);
		}
	}
}									
return \%giveback;		
}
###############################################################################
## Get a list of services which are not defined in vcenter anymore	     ##
###############################################################################
sub get_oldservices
{
my $self=shift;
my $checker;
my %giveback;
my @modes=$self->get_modes();
my $jsonchecks=$self->get_checks;

foreach my $mode (@modes)
{
        if($self->{nagios}->{services}->{$mode})
        {
                foreach my $i (keys %{$self->{nagios}->{services}->{$mode}})
                {
                        $checker=1;
                        foreach my $x (@{$jsonchecks->{$mode}})
                        {
                                if($x->{name} eq $i  and $x->{cmd} eq $self->{nagios}->{services}->{$mode}->{$i}->{cmd} and  $x->{period} eq $self->{nagios}->{services}->{$mode}->{$i}->{period})
                                {
                                        $checker=0;
                                        last;
                                }
                        }
                        if($checker eq 1)
                        {
                                push(@{$giveback{$mode}},$i);
                        }
                }
        }
}
return \%giveback;
}
###############################################################################
## Get a hash of objects which are configured in the monitoring system       ##
###############################################################################
sub get_configuredhosts
{
my $self=shift;
my $configuredhosts=$self->{nagios};

return $configuredhosts;
}
###############################################################################
## Get all data from the object 		                             ##
###############################################################################
sub get_alldata
{
my $self=shift;
my %giveback;
my @modes=$self->get_modes();

for my $mode(@modes)
{
	$giveback{$mode}=$self->{$mode};
}

return \%giveback;
}
###############################################################################
## Get all configured services without the old ones                          ##
###############################################################################
sub get_currentchecks
{
my $self=shift;
my $newchecks=$self->get_newservices;
my %giveback;
my $checker;
my @modes=$self->get_modes();

for my $mode (@modes)
{
	for my $current (@{$self->{config}->{Monitoring}->{$mode}->{checks}})
	{
		$checker=0;
		for my $old (@{$newchecks->{$mode}})
		{
			if($current->{name} eq $old)	
			{
				$checker=1;
				last;
			}
		}
		if($checker eq 0)
		{
			push(@{$giveback{$mode}},$current);
		}
	}
}
return \%giveback;
}
###############################################################################
## Get all configured performance services without the old ones              ##
###############################################################################
sub get_currentchecks_perf
{
my $self=shift;
my $newchecks=$self->get_newservices;
my %giveback;
my $checker;
my @modes=$self->get_modes();


for my $mode (@modes)
{
        for my $current (@{$self->{config}->{Monitoring}->{$mode}->{performancemetrics}})
        {
                $checker=0;
                for my $old (@{$newchecks->{$mode}})
                {
                        if($current->{nameinfo} eq $old)
                        {
                                $checker=1;
                                last;
                        }
                }
                if($checker eq 0)
                {
                        push(@{$giveback{$mode}},$current);
                }
        }
}
return \%giveback;
}

1;
