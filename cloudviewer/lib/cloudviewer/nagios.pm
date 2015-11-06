package cloudviewer::nagios;

use strict;
use warnings;
use File::Path 'rmtree';

###################################################################
## Get already configured objects from TXT File			 ##
###################################################################
sub get_nagiosdata
{
my $hostgroup = shift;
my $nagiosdir = shift;
my @mainlines;
my @deltalines;
my %maingiveback;
my %deltagiveback;
my @temparray;

if($nagiosdir !~ /^\/((.*?)*\/?)*\/$/)
{
	$nagiosdir=$nagiosdir."/";
}
my $mainfile = $nagiosdir.$hostgroup.".txt";

## Get Lines from Mainfile
if(-e $mainfile)
{
        open(FH,"<",$mainfile) or die "Could not open file '$mainfile'";
	@mainlines=<FH>;
	close(FH);
}
else
{
	print  "$mainfile not found\n";
}

## Build Hash for each entry
for my $line (@mainlines)
{
	chomp(@temparray=split(/\|/,$line));
	$maingiveback{$temparray[0]}={ip => $temparray[1],parent => $temparray[2]};
}
## Get Lines from deltafile

return {main => \%maingiveback};
}
###################################################################
## Get already configured services from TXT File		 ##
###################################################################
sub get_nagiosservices
{
my $hostgroup = shift;
my $nagiosdir = shift;
my @mainlines;
my @deltalines;
my @temparray;
my %maingiveback;
my %deltagiveback;

if($nagiosdir !~ /^\/((.*?)*\/?)*\/$/)
{
	$nagiosdir=$nagiosdir."/";
}
my $mainfile = $nagiosdir.$hostgroup."-service.txt";

if(-e $mainfile)
{
	open(FH,"<",$mainfile) or die "Could not open file '$mainfile'";
	@mainlines=<FH>;
	close(FH);
} 
else
{
	print  "$mainfile not found\n";
}
       
## Build Hash for each entry
for my $line (@mainlines)
{
        chomp(@temparray=split(/\|/,$line));
        $maingiveback{$temparray[0]}={
				cmd => $temparray[1],
				period => $temparray[2],
                                notificationoptions => $temparray[3],
                                checkperiod => $temparray[4],
                                notificationinterval => $temparray[5],
                                notificationperiod => $temparray[6],
                                maxcheckattempts => $temparray[7],
                                contactgroups => $temparray[8]
				};
}
return {main => \%maingiveback};
}
###################################################################
## Write new nagios config and update delta TXT file		 ##
###################################################################
sub set_newobjects
{
my $objects = shift;
my $hostgroupref = shift;
my $nagiosdir = shift;
my %hostgroups=%{$$hostgroupref};
my $filecontent;
my $name;
my $ip;
my $command;
my $path;
my $config="";
my $temp;
my $parent;

my $template = 
"define host{                                           
host_name                       <name>
address                         <address>               
hostgroups                      <hostgroup>	        
check_command                   <command>               
parents				<parent>		
check_interval                  5
retry_interval                  1
max_check_attempts              5
check_period                    24x7
contact_groups                  admins
notification_interval           30
notification_period             24x7
notification_options            d,u,r
}";


if($nagiosdir !~ /^\/([a-z0-9]*\/?)*\/$/)
{
	$nagiosdir=$nagiosdir."/";
}
for my $mode (keys %$objects)
{

	if(!-d $nagiosdir.$hostgroups{$mode}."/")
	{
        	mkdir $nagiosdir.$hostgroups{$mode}."/";
	}
	my $hostfile = $nagiosdir.$hostgroups{$mode}.".txt";
	$config="";

	for my $i (@{$objects->{$mode}})
	{
		$name=$i->{name};
		$ip=$i->{ip};
		$parent=$i->{parent};
		if($mode eq 'vm' or $mode eq 'host')
		{
			$command="check-host-alive";
			#$command="check_ok";
		}
		else
		{
                	$command="check_ok";
		}
		$config=$config.$name."|".$ip."|".$parent."\n";
		$temp=$template;
		$temp=~s/<name>/$name/g;
		$temp=~s/<address>/$ip/g;
		$temp=~s/<command>/$command/g;
		$temp=~s/<hostgroup>/$hostgroups{$mode}/g;
		$temp=~s/<parent>/$parent/g;
		$path=$nagiosdir.$hostgroups{$mode}."/".$name.".cfg";

		open(FILE,">","$path") or die "Could not open Path $path .";
		print FILE $temp;
		close(FILE);
	}
	chop($config);
	open(FH,">>$hostfile") or die "Could not open file '$hostfile'";
	print FH  $config."\n";
	close(FH);
}
}
###################################################################
## Delete old config and update host and delta file		 ##
###################################################################
sub set_oldobjects
{
my $objects = shift;
my $hostgroupref = shift;
my $nagiosdir = shift;
my %hostgroups=%{$$hostgroupref};
my $file;
my @lines;
my $text;
my $textdelta;
my $temp;
my $name;


if($nagiosdir !~ /^\/((.*?)*\/?)*\/$/)
{
        $nagiosdir=$nagiosdir."/";
}

for my $mode (keys %$objects)
{
	my $hostfile = $nagiosdir.$hostgroups{$mode}.".txt";
	if(-e $hostfile)
	{
       		open(FH,"<",$hostfile) or die "Could not open file '$hostfile'";
        	@lines=<FH>;
        	close(FH);
        	$text=join("",@lines);
	}
        for my $i (@{$objects->{$mode}})
        {
		$name=$i->{name};
		$file=$nagiosdir.$hostgroups{$mode}."/".$name.".cfg";
		unlink $file;
		$text=~s/^$name,((.*?)*\/?)*\n//gm if $text;
	}
	##Write changes to main file
	if($text)
	{
        	open(FH,">",$hostfile) or die "Could not open file '$hostfile'";
        	print FH $text;
        	close(FH);
	}
}
}
###################################################################
## Delete old config and update host and delta file              ##
###################################################################
sub set_oldservices
{
my $objects = shift;
my $hostgroupref = shift;
my $nagiosdir = shift;
my %hostgroups=%{$$hostgroupref};
my $file;
my @lines;
my $temp;
my $name;
my $text;
my $textdelta;

if($nagiosdir !~ /^\/((.*?)*\/?)*\/$/)
{
        $nagiosdir=$nagiosdir."/";
}

for my $mode (keys %$objects)
{
        my $servicefile = $nagiosdir.$hostgroups{$mode}."-service.txt";
        if(-e $servicefile)
        {
                open(FH,"<",$servicefile) or  die "Could not open file '$servicefile'";
                @lines=<FH>;
                close(FH);
                $text=join("",@lines);
        }
        for my $i (@{$objects->{$mode}})
        {
                $name=$i;
                $file=$nagiosdir.$hostgroups{$mode}."/services/service-".$name.".cfg";
                unlink $file;
                $text=~s/^$name,((.*?)*\/?)*\n//gm if $text;
        }
        ##Write changes to main file
        if($text)
        {
                open(FH,">",$servicefile) or die "Could not open file '$servicefile'";
                print FH $text;
                close(FH);
        }
}
}
##################################################################
## Filter all available Metrics with he settings from JSON File ##
##################################################################
sub set_newservices
{
my $objects = shift;
my $hostgroupref = shift;
my $nagiosdir = shift;
my %hostgroups=%{$$hostgroupref};
my $path;
my $temp;
my $config="";
my $servicefile;

my $templatepassiv =  
"define service{
hostgroups          <hostgroup>
service_description     <desc>
check_command		check_passiv
passive_checks_enabled  1
active_checks_enabled   0
notification_options    <notificationoptions>
check_period            <checkperiod>
notification_interval   <notificationinterval>
notification_period     <notificationperiod>
max_check_attempts      <maxcheckattempts>
contact_groups          <contactgroups>
}";


my $templateactive =  
"define service{
hostgroups          <hostgroup>
service_description     <desc>
check_command		<command>
passive_checks_enabled  1
active_checks_enabled   1
notification_options    <notificationoptions>
check_period            <checkperiod>
notification_interval   <notificationinterval>
notification_period     <notificationperiod>
max_check_attempts      <maxcheckattempts>
check_interval          <period>
contact_groups          <contactgroups>
}";

if($nagiosdir !~ /^\/((.*?)*\/?)*\/$/)
{
        $nagiosdir=$nagiosdir."/";
}

for my $mode (keys %$objects)
{
	$servicefile = $nagiosdir.$hostgroups{$mode}."-service.txt";
	if(!-d $nagiosdir.$hostgroups{$mode}."/services")
        {
                mkdir $nagiosdir.$hostgroups{$mode}."/services";
        }
        for my $i (@{$objects->{$mode}})
        {
		if($i->{cmd})
		{
			$temp=$templateactive;
                        $config=$config.
				$i->{name}."|".
				$i->{cmd}."|".
				$i->{period}."|".
				$i->{notificationoptions}."|".
				$i->{checkperiod}."|".
				$i->{notificationinterval}."|".
				$i->{notificationperiod}."|".
				$i->{maxcheckattempts}."|".
				$i->{contactgroups}."|".
				"\n";
                        $temp=~s/<hostgroup>/$hostgroups{$mode}/g;
                        $temp=~s/<desc>/$i->{name}/g;
			$temp=~s/<command>/$i->{cmd}/g;
			$temp=~s/<period>/$i->{period}/g;
                        $temp=~s/<notificationoptions>/$i->{notificationoptions}/g;
                        $temp=~s/<checkperiod>/$i->{checkperiod}/g;
                        $temp=~s/<notificationinterval>/$i->{notificationinterval}/g;
                        $temp=~s/<notificationperiod>/$i->{notificationperiod}/g;
                        $temp=~s/<maxcheckattempts>/$i->{maxcheckattempts}/g;
                        $temp=~s/<contactgroups>/$i->{contactgroups}/g;
                        $path=$nagiosdir.$hostgroups{$mode}."/services/service-".$i->{name}.".cfg";

		}
		else
		{
                	$temp=$templatepassiv;
                	$config=$config.
                                $i->{name}.
				"|".
                                "|".
                                "|".
                                $i->{notificationoptions}."|".
                                $i->{checkperiod}."|".
                                $i->{notificationinterval}."|".
                                $i->{notificationperiod}."|".
                                $i->{maxcheckattempts}."|".
                                $i->{contactgroups}."|".
                                "\n";
			$temp=~s/<hostgroup>/$hostgroups{$mode}/g;
               		$temp=~s/<desc>/$i->{name}/g;
                        $temp=~s/<checkperiod>/$i->{checkperiod}/g;
                        $temp=~s/<notificationoptions>/$i->{notificationoptions}/g;
                        $temp=~s/<notificationinterval>/$i->{notificationinterval}/g;
                        $temp=~s/<notificationperiod>/$i->{notificationperiod}/g;
                        $temp=~s/<maxcheckattempts>/$i->{maxcheckattempts}/g;
                        $temp=~s/<contactgroups>/$i->{contactgroups}/g;
			$path=$nagiosdir.$hostgroups{$mode}."/services/service-".$i->{name}.".cfg";
		}
                open(FILE,">","$path") or die "Could not open Path $path .";
                print FILE $temp;
                close(FILE);
	}
	chop($config);
	open(FH,">>$servicefile") or die "Could not open file '$servicefile'";
	print FH  $config."\n";
	close(FH);
	$config="";
}
}
###################################################################
## Write all needed Hostgroups                                   ##
###################################################################
sub set_groups
{
my $hostgroupref = shift;
my $nagiosdir = shift;
my %hostgroups=%{$$hostgroupref};
my $groupdir;
my $servicefile;
my $hostfile;
my $modedir;
my $temp;

my $templatehost =  "
define hostgroup{
        hostgroup_name          <hostgroup>
        alias                   <hostgroup>
        }";

if($nagiosdir !~ /^\/([a-z0-9]*\/?)*\/$/)
{
        $nagiosdir=$nagiosdir."/";
}

for my $mode (keys %hostgroups)
{
	$modedir=$nagiosdir.$hostgroups{$mode}."/";
	$hostfile = $modedir.$hostgroups{$mode}.".cfg";
        if(!-d $modedir)
        {
                mkdir $modedir;
        }

	$temp=$templatehost;
        $temp=~s/<hostgroup>/$hostgroups{$mode}/g;
        open(FILE,">","$hostfile") or die "Could not open Path $hostfile .";
        print FILE $temp;
        close(FILE);
}
}
###################################################################
## Delete all old objecttypes		                         ##
###################################################################
sub set_oldgroups
{
my $hostgroupref = shift;
my $nagiosdir = shift;
my %hostgroups;
if($hostgroupref)
{
	%hostgroups=%{$$hostgroupref};
}
my $servicefile;
my $hostfile;
my $dir;

if($nagiosdir !~ /^\/((.*?)*\/?)*\/$/)
{
        $nagiosdir=$nagiosdir."/";
}

foreach my $group (keys %hostgroups)
{
	
	$servicefile=$nagiosdir.$hostgroups{$group}."-service.txt";
	$hostfile=$nagiosdir.$hostgroups{$group}.".txt";
	$dir=$nagiosdir.$hostgroups{$group};

	if(-e $hostfile)
	{
		unlink $hostfile;
	}
	if(-e $servicefile)
	{
		unlink $servicefile;
	}
	if(-d $dir)
	{
		rmtree($dir);
	}
}
}  
###################################################################
## Write data to nagios command socket				 ##
###################################################################
sub write_result
{
my $results=shift;
my $nagioscmd="";
my $date=time();
my $command_file=shift;

for my $result (@{$results})
{
	$nagioscmd="[$date] PROCESS_SERVICE_CHECK_RESULT;$result->{name};$result->{service};$result->{status};".listTOscalar($result->{message})."$result->{service} = $result->{performance}\n";
	open(CMDFILE,">>$command_file") or die "Could not open CMD-File: $command_file";
	print CMDFILE $nagioscmd;
	close(CMDFILE);
}
}
###################################################################
## Helperfunction to format the output for nagios		 ##
###################################################################
sub listTOscalar
{
my $array=shift;
my $scalar="";
foreach my $i (@{$array})
{
        $scalar=$scalar.$i."\\n";
}

$scalar=$scalar."|";
return $scalar;
}	

1;
