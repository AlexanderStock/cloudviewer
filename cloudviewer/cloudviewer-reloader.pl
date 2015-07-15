#!/usr/bin/perl

use strict;
use lib "/var/lib/cloudviewer/lib";
use Data::Dumper;
use Getopt::Long;
use cloudviewer::connector;
use cloudviewer::nagios;
use VMware::VIRuntime;

my @conffilelist;
my $dir;
my $confdir;
my $mainfile;
my @lines;
my @objects;
my $pid;
my $tempobject;
my @modes;
my $oldhostgroups;
my $hostgroups;


GetOptions (
"dir=s" => \$dir,
"confdir=s" => \$confdir,
)
or die("Error in command line arguments\n");

##Checking JSON-Config Directory
if($confdir !~ /^\/((.*?)*\/?)*\/$/)
{
        $confdir=$confdir."/";
}

opendir(DIR,$confdir) or die "Could not open $confdir";
@conffilelist=readdir(DIR);
close(DIR);

for my $file (@conffilelist)
{
        if($file =~ /.json$/)
        {
		$tempobject=cloudviewer::connector->new($confdir.$file);
		$tempobject->set_updatemode;
		$tempobject->get_vcenterdata;
		@modes=$tempobject->get_modes;
		##Get Hostgroups per Objecttype
		$hostgroups=$tempobject->get_hostgroups(1);
		$oldhostgroups=$tempobject->get_hostgroups(0);
		cloudviewer::nagios::set_groups($hostgroups,$dir);
		cloudviewer::nagios::set_oldgroups($oldhostgroups,$dir);
		

		foreach my $mode (@modes)
		{
	       		##Get Data from Nagios per Objecttype and push it into vCenter Object
        		$tempobject->set_existingobjects(cloudviewer::nagios::get_nagiosdata($$hostgroups->{$mode},$dir),$mode);

        		##Get Data for Checks from Nagios per Objecttype and push it into vCenter Object
        		$tempobject->set_existingservices(cloudviewer::nagios::get_nagiosservices($$hostgroups->{$mode},$dir),$mode);
		}

		##Get new Objects and create the Nagios Config for them
		cloudviewer::nagios::set_newobjects($tempobject->get_new,$hostgroups,$dir);
		cloudviewer::nagios::set_oldobjects($tempobject->get_old,$hostgroups,$dir);

		##Get new services and create the Nagios Config for them
		cloudviewer::nagios::set_newservices($tempobject->get_newservices,$hostgroups,$dir);
		cloudviewer::nagios::set_oldservices($tempobject->get_oldservices,$hostgroups,$dir);

	}
}

#system("omd reload cloudviewer1 nagios");	
