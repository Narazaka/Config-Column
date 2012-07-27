use utf8;
use strict;
use warnings;
use Test::More;
use FindBin '$Bin';
BEGIN{unshift @INC,$Bin.'/../lib';use_ok('Config::Column')};
require $Bin.'/single.pl';

#for my $opt (@$options){
#	Config::Column::Test::Single::new($opt,1);
#}
use Data::Dumper;
#Config::Column::Test::Single::new_options('valid',sub{print Dumper shift});
#print "---"x10,"\n";
	Config::Column::Test::Single::add_data_last(
		{
			file=>'aa.txt',
			index_shift=>0,
			order=>[qw/a b/],
			delimiter=>"\t"
		},
#		[{a=>1,b=>10},{a=>2,b=>20},{a=>3,b=>30}],
		[{a=>1,b=>10}],
		undef,
		undef,
		undef,
		"1\t10\n"
	);

done_testing;
