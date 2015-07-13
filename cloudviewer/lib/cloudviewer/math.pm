package cloudviewer::math;

use strict;
use warnings;
use Data::Dumper;

sub cpuready
{
my $value=shift;
my $return=($value / (20  * 1000)) * 100;

return $return;
}

1