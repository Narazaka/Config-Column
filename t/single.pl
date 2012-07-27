package Config::Column::Test::Single;
use utf8;
use strict;
use warnings;
use Test::More;

my %buf;

my $new_options = {
	file => {
		valid => [
			'file.dat',
			\*STDOUT,
#			$fh,
		],
		invalid => [
			{},
			[],
			sub{},
			'',
			undef,
		],
	},
	layer => {
		valid => [
			'utf8',
			'euc-jp',
			'sjis',
			':encoding(utf8)',
			':utf8',
			'',
			undef,
		],
	},
	order_delimiter_escape => { # invalid は一部の指定の場合validのにかぶせて使用?
		valid => [
			{
				order => [],
				delimiter => [''],
				record_delimiter => ["\n",chr(0),'-----','##',undef,''],
				escape => ['\\','aaaa'],
			},
			{
				order => [],
				delimiter => [],
				record_delimiter => [],
				escape => [],
			},
		],
		invalid => [
			{
				order => [[],{},sub{},'',undef],
			},
			{
				order => [[1,1]],
				delimiter => ['',undef],
			},
		],
	},
	index_shift => {
		valid => [
			0,1,2,'',undef
		],
		invalid => [
			-273,'009',42.195,'config'
		],
	},
};

sub new_options{
	my $mode = shift;
	my $callback = shift;
	my @option_names = qw/file layer index_shift/; # option names
	my $option_sets = []; # 使用するoptionの組(set)を格納
	if($mode eq 'valid'){ # ::VALID
		push @$option_sets,{}; # new option set
		my $set = $option_sets->[-1]; # current $set = new option set
		for my $name (@option_names){
			$set->{$name} = $new_options->{$name}->{valid}; # option set にvalidな使用オプションを追加してゆく
		}
	}elsif($mode eq 'invalid'){ # ::INVALID
		my $false_num_max = @option_names; # invalid(false)にするoptionの数の最大値
		# ↓ 例 : option 数 = 3 の場合
		# ↓ false option 数 = 0 -> [], false option 数 = 1 -> [1,0,0],[0,1,0],[0,0,1] (1 = false option flag)
		my $false_option_sets = {0 => [[]]};
		for my $false_num (1..$false_num_max){ # false option 数 = 1 ～ Max
			for my $set (@{$false_option_sets->{$false_num - 1}}){ # 現在求めたいものより1少ない false option 数 の set を参照する
				my @rest_options = grep {$#$set < $_} 0..$#option_names; # 重複よけのためsetの中の最大番号のfalse optionより大きい番号のoptionを当てはめてゆく
				for my $i (@rest_options){ # 使えるoptionの番号についてループ
					my $new_set = [@$set]; # 元の(false option 数が1少ない)setをコピー
					$new_set->[$i] = 1; # 新たに1つfalse option flagを立てる
					push @{$false_option_sets->{$false_num}},$new_set; # false_option_setsに保存
				}
			}
		}
		for my $false_num (1..$false_num_max){ # false option 数 = 1 ～ Max
			for my $false_set (@{$false_option_sets->{$false_num}}){ # false option 数 = $false_num である set について
				push @$option_sets,{}; # new option set
				my $set = $option_sets->[-1]; # current $set = new option set
				for my $i (0..$#option_names){
					my $name = $option_names[$i];
					$set->{$name} = $new_options->{$name}->{$false_set->[$i] ? 'invalid' : 'valid'}; # option set にfalse option 数だけinvalidなもののある使用オプションを追加してゆく
				}
			}
		}
	}
	my $option_hashs = all_option_value_set($option_sets,\@option_names);
	$callback->($_) for @$option_hashs;
}

sub all_option_value_set{
	my $option_sets = shift; # []
	my $option_names = shift; # []
	my $option_hashs = [];
	for my $set (@$option_sets){
		my @option_index_max;
		my $option_type_num = $#$option_names; # option の種類数
		for my $i (0..$option_type_num){
			$option_index_max[$i] = $#{$set->{$option_names->[$i]}};
		}
		my @option_index = map {0} @$option_names;
		ALL: while(1){
			push @$option_hashs,{map {$option_names->[$_] => $set->{$option_names->[$_]}->[$option_index[$_]]} 0..$option_type_num};
			for my $i (0..$option_type_num){
				$option_index[$i] ++;
				if($option_index_max[$i] >= $option_index[$i]){
					last;
				}else{
					last ALL if $i == $option_type_num;
					$option_index[$i] = 0;
				}
			}
		}
	}
	return $option_hashs;
}

sub all_option_name_set{
	my $option_names = shift; # [[],[],...]
	my $option_values = shift; # []
	my $option_hashs = [];
	my @option_index_max;
	my $option_type_num = $#$option_names; # option の種類数
	for my $i (0..$option_type_num){
		$option_index_max[$i] = $#{$option_names->[$i]};
	}
	my @option_index = map {0} @$option_names;
	ALL: while(1){
		push @$option_hashs,{map {$option_names->[$_]->[$option_index[$_]] => $option_values->[$_]} 0..$option_type_num};
		for my $i (0..$option_type_num){
			$option_index[$i] ++;
			if($option_index_max[$i] >= $option_index[$i]){
				last;
			}else{
				last ALL if $i == $option_type_num;
				$option_index[$i] = 0;
			}
		}
	}
	return $option_hashs;
}

sub new{
	my $new_opt = shift;
	my $is_valid = shift;
	my $cc1 = eval{Config::Column->new($new_opt)};
	my $err_cc1 = $@;
	my $cc2 = eval{Config::Column->new(map {$new_opt->{$_}} qw/file layer order delimiter index_shift record_delimiter escape/)};
	my $err_cc2 = $@;
	is_deeply($cc1,$cc2,'new() 2 ways arguments');
	is($err_cc1,$err_cc2,'new() 2 ways arguments eval error');
	if($is_valid){
		is($err_cc1,'');
	}else{
		isnt($err_cc1,'');
	}
	return $cc1;
}

=pod

		file => $file,
		layer => $layer,
		order => $order,
		delimiter => $delimiter,
		index_shift => $index_shift,
		record_delimiter => $record_delimiter,
		escape => $escape

=cut

sub add_data_last{
	my $new_opt = shift;
	my $cc = Config::Column->new($new_opt);
	my $data_list = shift;
	my $file_handle_mode = shift;
	my $no_seek = shift;
	my $like = shift;
	my $str = shift;
	my $result = shift;
	eval{$cc->add_data_last($data_list, $file_handle_mode, $no_seek)};
	$like ? like($@,$like,'add_data_last eval') : is($@,'','add_data_last eval');
	my $option_sets = all_option_name_set(
		[
			[qw/data data_list/],
			[qw/file_handle_mode fhmode/],
			[qw/no_seek noseek/]
		],
		[
			$data_list,
			$file_handle_mode,
			$no_seek
		]
	);
	use Data::Dumper;
	for my $opt (@$option_sets){
		eval{$cc->add_data_last($opt)};
		$like ? like($@,$like,'add_data_last eval') : is($@,'','add_data_last eval');
#		warn Dumper $opt;
	}
		is_deeply(get_last($cc,($#$option_sets + 1)),$result,'add_data_last data compare');
}

sub get_last{
	my $cc = shift;
	my $n = shift;
	return $cc->read_data();
	#return join '',map {$lines[$_]} ($#lines - $n + 1) .. $#lines;
}

1;
