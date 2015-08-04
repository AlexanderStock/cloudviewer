# cloudviewer

What is Cloudviewer?
Cloudviewer is a scriptcollection for monitoring VMWare based Clusters,Hosts,Datastores and VMs with Nagios (OMD). Cloudviewer depends on the 5.5 Version of the VMWare Perl SDK. It is working with one active check per vCenter which pulls the data from the vcenter and putting it into passiv checks after inspecting it.

Possible checks you can use for your objects are: You can also build dynamic checks for performance data and for external checks like check_http.

The Nagiosinventory is created automatically by the second cloudviewer script which runs as a cronjob and queries all vCenter Objects periodically and configures the nagios objects for it.
Installation (a dependencie here is a working nagios installation)

# Installation

## The VMware SDK:

[Official Howto for Linux](https://developercenter.vmware.com/doc/preview?id=157#https%3A%2F%2Fvdc-repo.vmware.com%2Fvmwb-repository%2Fdcr-public%2F55a8bd37-3cb5-47bf-b523-cdc55a9d29c6%2F0a25a243-2c31-4093-b351-ae2065dc490f%2Fdoc%2Fcli_install.3.5.html%231106926)

## Cloudviewer:

- Download the Zip File from Github
- Unpack the Zip on you nagios Host with: "unzip cloudviewer-master.zip"
- Go to the source directory: "cd cloudviewer-master/cloudviewer-master"
- Copy Directories: "cp -R cloudviewer /usr/lib/ && cp -R cloudviewer-data /var/lib/"
- Give Nagios user write access: "chown nagios /var/lib/cloudviewer-data/cloudviewer-automated  && chown nagios /var/lib/cloudviewer-data/sessions"
- Add the cronjob: 

_*/30 * * * *   /usr/lib/cloudviewer/cloudviewer-reloader.pl --dir /var/lib/cloudviewer-data/cloudviewer-automated/ --confdir /var/lib/cloudviewer-data/config/ && chown -R cloudviewer1 /var/lib/cloudviewer-data/ && (YOUR NAGIOS RELOAD COMMAND HERE)_

- Add the cloudviewer folder to your nagios.cfg file:

_cfg_dir=/var/lib/cloudviewer-data_

- Create your JSON configurations under _/var/lib/cloudviewer-data/config_
(you can use the given files as template)
- Add your vCenter to _/var/lib/cloudviewer-data/cloudviewer-vcenter_
(you can use the given files as template)
