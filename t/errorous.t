use utf8;
use strict;
use warnings;
use Test::More tests => 5;
use FindBin '$Bin';
BEGIN{unshift @INC,$Bin.'/../lib';use_ok('Config::Column')};
require $Bin.'/base.pl';
our $set;

my $datafile = 'errorous';
my $encoding = 'utf8';
my $order = [qw(1 name subject date value mail url key host addr)];
my $delimiter = "\t";
{
	my $cc = Config::Column->new($FindBin::Bin.'/'.$datafile,$encoding,$order,$delimiter,42);
	isa_ok($cc,'Config::Column','valid index');
	my $cc1 = $cc->new($FindBin::Bin.'/'.$datafile,$encoding,$order,$delimiter,42);
	isa_ok($cc1,'Config::Column','re bless');
}
{
# can valid ?
	my $cc = eval{Config::Column->new($FindBin::Bin.'/'.$datafile,$encoding,$order,$delimiter,-1)};
	isnt($@,'','invalid index');
	isnt(ref $cc,'Config::Column','invalid index');
}
{
# can valid
	my $cc = eval{Config::Column->new($FindBin::Bin.'/'.$datafile,$encoding,$order,$delimiter,'001')};
	isnt($@,'','invalid index');
	isnt(ref $cc,'Config::Column','invalid index');
}
{
	my $cc = eval{Config::Column->new($FindBin::Bin.'/'.$datafile,$encoding,$order,$delimiter,'42.195')};
	isnt($@,'','invalid index');
	isnt(ref $cc,'Config::Column','invalid index');
}
{
	my $cc = eval{Config::Column->new($FindBin::Bin.'/'.$datafile,$encoding,$order,$delimiter,'宇宙')};
	isnt($@,'','invalid index');
	isnt(ref $cc,'Config::Column','invalid index');
}
{
	my $cc = eval{Config::Column::new(undef,$FindBin::Bin.'/'.$datafile,$encoding,$order,$delimiter,0)};
	is($@,'','invalid initialize');
	isnt(ref $cc,'Config::Column','invalid initialize');
}
