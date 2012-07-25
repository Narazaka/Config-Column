use utf8;
use strict;
use warnings;
use Test::More tests => 13;
use FindBin '$Bin';
BEGIN{unshift @INC,$Bin.'/../lib';use_ok('Config::Column')};

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
	my $cc = eval{Config::Column->new($FindBin::Bin.'/'.$datafile,$encoding,$order,$delimiter,-1)};
	isnt($@,'','invalid index (negative)');
	isnt(ref $cc,'Config::Column','invalid index (negative)');
}
{
# can valid
	my $cc = eval{Config::Column->new($FindBin::Bin.'/'.$datafile,$encoding,$order,$delimiter,'001')};
	isnt($@,'','invalid index (zero padding)');
	isnt(ref $cc,'Config::Column','invalid index (zero padding)');
}
{
	my $cc = eval{Config::Column->new($FindBin::Bin.'/'.$datafile,$encoding,$order,$delimiter,'42.195')};
	isnt($@,'','invalid index (not integer)');
	isnt(ref $cc,'Config::Column','invalid index (not integer)');
}
{
	my $cc = eval{Config::Column->new($FindBin::Bin.'/'.$datafile,$encoding,$order,$delimiter,'宇宙')};
	isnt($@,'','invalid index (not number)');
	isnt(ref $cc,'Config::Column','invalid index (not number)');
}
{
	my $cc = eval{Config::Column::new(undef,$FindBin::Bin.'/'.$datafile,$encoding,$order,$delimiter,0)};
	is($@,'','invalid initialize');
	isnt(ref $cc,'Config::Column','invalid initialize');
}
