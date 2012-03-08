use utf8;
use strict;
use warnings;
use Test::More tests => 2;
use FindBin '$Bin';
BEGIN{unshift @INC,$Bin.'/../lib';use_ok('Config::Column')};
require $Bin.'/base.pl';
our $set;

can_ok('Config::Column', qw/new adddatalast adddata writedata readdata readdatanum _setwriteorder/);
