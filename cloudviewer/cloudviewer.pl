#!/usr/bin/perl -w

use strict;
no strict 'subs';
no strict 'refs';
use lib "/usr/lib/cloudviewer/lib";
use diagnostics;
use cloudviewer::connector;
use cloudviewer::nagios;
use cloudviewer::performance;
use cloudviewer::clusterchecks;
use cloudviewer::hostchecks;
use cloudviewer::datastorechecks;
use cloudviewer::vmchecks;
use cloudviewer::math;
use VMware::VIRuntime;
use Data::Dumper;
use Getopt::Long;

my $file;
my $dir;
my $hostgroups;
my $vcid;
my $checker;
my $checks;
my $checks_perf;
my $check;
my $func;
my $cluster;
my $hosts;
my $datastores;
my $vms;
my @result_checks_perf;
my @result_checks;
my $data;
my $methodchecker;
my $configuredhosts;
my $prefix;
my $error=0;
my %errors;
my @modes;
my @header;
my $domainsocket;
my $whitecheck;
my 	$blackcheck;
my @message;

GetOptions (
"file=s" => \$file,
"dir=s" => \$dir,
)
or die("Error in command line arguments\n");

my $vcenter=cloudviewer::connector->new($file);

##Get initial Data from vCenter
$vcenter->get_vcenterdata;
@modes=$vcenter->get_modes;

##Get Hostgroups per Objecttype
$hostgroups=$vcenter->get_hostgroups(1);
$vcid=$vcenter->get_vcid;
$domainsocket=$vcenter->get_domainsocket;

foreach my $mode (@modes)
{

	##Get Data from Nagios per Objecttype and push it into vCenter Object
	$vcenter->set_existingobjects(cloudviewer::nagios::get_nagiosdata($$hostgroups->{$mode},$dir),$mode);

	##Get Data for Checks from Nagios per Objecttype and push it into vCenter Object
	$vcenter->set_existingservices(cloudviewer::nagios::get_nagiosservices($$hostgroups->{$mode},$dir),$mode);
}

##Get all available Data which is already availabel in the monitoring system
$data=$vcenter->get_alldata;
$configuredhosts=$vcenter->get_configuredhosts;
$checks=$vcenter->get_currentchecks;
$checks_perf=$vcenter->get_currentchecks_perf;

my $counter=0;
for my $mode (@modes)
{

	for my $check (@{$checks->{$mode}})
	{
		$func="cloudviewer::".$mode."checks::$check->{function}";
		if(!defined(&{$func}))
		{
			$error=2;
			print "Error:   Function $func is not defined.\n";
		}
	}
	$counter=0;
	$prefix=$vcid."-".$mode."-";
       	for my $object (@{$data->{$mode}})
       	{
          	$checker=0;
		if($configuredhosts->{$mode}->{$object->{name}})
		{
			##Build the Check Header
			@header=(
				"----------INFO----------",
				"Name: ".$object->{configuration}->name,
				"vCenter: $vcid",
				"Monitoring-Parent: ".$object->{parent},
				"----------MESSAGE----------");
			##Working on the checks
		        for my $check (@{$checks->{$mode}})
		        {
				$whitecheck=0;
				$blackcheck=0;
				if(@{$check->{whitelist}})
				{
					$whitecheck=1;
					foreach my $whiteobject (@{$check->{whitelist}})
					{
						if($whiteobject eq $object->{configuration}->name)
						{
							$whitecheck=0;
							last;
						}
					}
				}
				if(@{$check->{blacklist}})
				{
					foreach my $blackobject (@{$check->{blacklist}})
					{
						if($blackobject eq $object->{configuration}->name)
						{
							$blackcheck=1;
							last;
						}
					}
				}
				if($whitecheck eq 0 and $blackcheck eq 0)
				{
			        	$func="cloudviewer::".$mode."checks::$check->{function}";
					if(defined(&{$func}))
					{
						eval{push(@result_checks,&$func($object,$check,\$prefix,\@header))};
						if($@)
						{
							print "Error while executing function $func.\n";
							print "$@ \n";
						}
					}
				}
				else
				{
					@message=@header;
					push(@message,"OK: Host is not on Whitelist or is on Blacklist.");
					push(@result_checks, {'name' => $object->{name},'message' => \@message, 'status' => 0, 'service' => $prefix.$check->{name}, performance => 0 });
				}					
			}

			##Working on the Performance Checks
			for my $perfcheck (@{$checks_perf->{$mode}})
			{
				$whitecheck=0;
				$blackcheck=0;
				if(@{$perfcheck->{whitelist}})
				{
					$whitecheck=1;
					foreach my $whiteobject (@{$perfcheck->{whitelist}})
					{
						if($whiteobject eq $object->{configuration}->name)
						{
							$whitecheck=0;
							last;
						}
					}
				}
				if(@{$perfcheck->{blacklist}})
				{
					foreach my $blackobject (@{$perfcheck->{blacklist}})
					{
						if($blackobject eq $object->{configuration}->name)
						{
							$blackcheck=1;
							last;
						}
					}
				}
				if($whitecheck eq 0 and $blackcheck eq 0)
				{
					push(@result_checks_perf,cloudviewer::performance::check_perf($object,\$prefix,$perfcheck,\@header));
				}
				else
				{
					@message=@header;
					push(@message,"OK: Host is not on Whitelist or is on Blacklist.");
					push(@result_checks, {'name' => $object->{name},'message' => \@message, 'status' => 0, 'service' => $prefix.$check->{name}, performance => 0 });
				}	
			}
		}
	$counter+=1;
	}
}
#Write checkresults to nagios
cloudviewer::nagios::write_result(\@result_checks,$domainsocket);
cloudviewer::nagios::write_result(\@result_checks_perf,$domainsocket);	
exit $error;
