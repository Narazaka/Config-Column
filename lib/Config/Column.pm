package Config::Column;
use utf8;

our $VERSION = '1.00';

=head1 NAME

Config::Column - simply packages config/log file IO divided by any delimiter.

=head1 SYNOPSIS

	# Copy the datalist in a tab separated file to readable formatted text file.
	
	use utf8;
	use lib './lib';
	use Config::Column;
	my $order_delim = [qw(1 subject date value)];
	my $order_nodelim = ['' => 1 => ': [' => subject => '] ' => date => ' : ' => value => ''];
	my $delimiter = "\t";
	
	# MAIN file instance
	my $ccmain = Config::Column->new(
		'mainfile.dat', # data file
		'utf8', # data file encoding
		$order_delim, # list of key names
		$delimiter, # delimiter of records
		1, # index offset
		"\0" # delimiter of "lines"
	);
	# SUB file (human readable)
	my $ccsub = Config::Column->new(
		'', # this can be empty because data file will be opened externally and file handle is passed to this instance
		'', # same reason
		$order_nodelim, # list of key names
		undef, # do not define delimiter
		1, # index offset
		# delimiter of "lines" is Default
	);
	
	# Read data from MAIN file.
	my $data = $ccmain->readdata;
	# Add new data.
	push @$data,{subject => 'YATTA!', date => '2012/03/06T23:33:00+09:00', value => 'All tests passed!'};print $data;
	# Write data to MAIN file.
	$ccmain->writedata($data);
	# Write header to SUB file
	open my $fh,'+<:encoding(utf8)','subfile.txt';
	flock $fh,2;
	truncate $fh,0;
	seek $fh,0,0;
	print $fh 'Single line diary?',"\n";
	# Add data to SUB file. Don't close and don't truncate $fh.
	$ccsub->writedata($data,$fh,1,1);
	print $fh 'The end of the worl^h^h^h^hfile';
	close $fh;

=head1 INTRODUCTION

This module generalizes the list of keys and delimiters that is common in "config" / "BBS log" file format and package-izes data list input and output of these files.

扱うデータリストは単純なキーとデータの組み合わせでできた各1データのハッシュのリストである。

	my $datalist = [
		{}, # 最初のインデックスが1(インデックスのシフトが1)の場合、0番目に空の情報が入っているとして扱われる。
		{title => "hoge",value => "huga"},
		{title => "hoge2",value => "huga"},
		{title => "hoge3",value => "huga"},
	];

その単純なデータリストの操作は基本的なPerlの操作に任せることにしてそのフォーマットの入出力のみを司ることにする。

=head1 DESCRIPTION

=head2 new

=head3 デリミタを全て同じにする場合(delimiterを必ず記述する)

	my $cc = Config::Column->new(
		'filename.dat', # データファイル
		'utf8', # データファイルの文字コード
		[qw(1 author id title date summary)], # キー名のリスト *order
		"\t", # デリミタ(必須)
		1, # インデックスのシフト(省略可能 省略した場合0(インデックスは0から)が使われる。) *index
		"\n" # 行デリミタ(省略可能 省略した場合Perlデフォルト(おそらく"\n")が使われる。)
	);

orderは各キーの名前

indexは最初のデータナンバー(0または1からはじめるなど。デフォルトは0)

=head3 デリミタを違える場合(delimiterは必ず空)

	my $cc = Config::Column->new(
		'filename.dat', # データファイル
		'utf8', # データファイルの文字コード
		[qw('' 1 ': ' author "\t" id "\t" title "\t" date "\t" summary)], # [delim key delim key ...] *order
		"", # デリミタ(必ず空)
		1, # インデックスのシフト(省略可能 省略した場合0(インデックスは0から)が使われる。) *index
		"\n" # 行デリミタ(省略可能 省略した場合Perlデフォルト(おそらく"\n")が使われる。)
	);

orderは偶数番目がデリミタ(最初と最後も)、奇数番目がキーの名前

indexは最初のデータナンバー(0または1からはじめるなど。デフォルトは0)

=head2 Methods

=cut

sub new{
	my $package = shift;
	my $filename = shift;
	my $encoding = shift;
	my $order = shift;
	my $delimiter = shift;
	my $index = shift;
	my $linedelimiter = shift;
	$package = ref $package || $package;
	$index = 0 unless $index;
	return unless $index =~ /^\d+$/;
	return bless {
		filename => $filename,
		encoding => $encoding,
		order => $order,
		delimiter => $delimiter,
		index => $index,
		linedelimiter => $linedelimiter,
		writeorder => _setwriteorder($order,$delimiter,$linedelimiter)
	},$package;
}

=head3 adddatalast()

データをそれまでのデータに続くものとしてファイルに追記する。インデックスはファイルから最後のインデックスを自動的に読んで使う。

	$cc->adddatalast($data,$fh,$fhflag);

	my $data = {title => "hoge",value => "huga"} || [...]; # 1データのハッシュリファレンスか、複数データの配列リファレンスが許される。
	my $fh; # 省略可能。ファイルハンドル。
	my $fhflag = 1; # 真値を与えればファイルハンドルを維持する。

与えられたファイルハンドルのファイルポインタが先頭でないなら、その位置から書き出します。

成功なら第一返値に1、$fhflagが真なら第二返値にファイルハンドルを返す。失敗なら偽を返す。

=cut

sub adddatalast{
	my $self = shift;
	my $datalist = shift;
	my $fh = shift;
	my $fhflag = shift;
	$datalist = [$datalist] if ref $datalist eq 'HASH';
	my $datanum;
	($datanum,$fh) = $self->readdatanum($fh,1);
	return $self->adddata($datalist,$datanum + 1,$fh,$fhflag);
}

=head3 adddata()

データをファイルに書き出す。

	$cc->adddata($datalist,$startindex,$fh,$fhflag);

	my $datalist = {title => "hoge",value => "huga"} || [
		{title => "hoge",value => "huga"},
		{title => "hoge2",value => "huga"},
		{title => "hoge3",value => "huga"},
	];# 1データのハッシュリファレンスか、複数データの配列リファレンスが許される。
	my $startindex = 12; # 書き出すデータリストの最初のインデックス。インデックスがいらない場合省略可能。
	my $fh; # 省略可能。ファイルハンドル。
	my $fhflag = 1; # 真値を与えればファイルハンドルを維持する。

与えられたファイルハンドルのファイルポインタが先頭でないなら、その位置から書き出します。

成功なら第一返値に1、$fhflagが真なら第二返値にファイルハンドルを返す。失敗なら偽を返す。

=cut

sub adddata{
	my $self = shift;
	my $datalist = shift;
	my $startindex = shift;
	my $fh = shift;
	my $fhflag = shift;
	$datalist = [$datalist] if ref $datalist eq 'HASH';
	unless(ref $fh eq 'GLOB'){
		my $encoding = $self->{encoding} ? ':encoding('.$self->{encoding}.')' : '';
		open $fh,'+<'.$encoding,$self->{filename} or open $fh,'>'.$encoding,$self->{filename} or return;
		flock $fh,2;
		seek $fh,0,2;
	}
	$self->{writeorder}->($fh,$datalist,$startindex);
	close $fh unless $fhflag;
	return $fhflag ? (1,$fh) : 1;
}

=head3 writedata()

データをファイルに書き出す。

	$cc->writedata($datalist,$fh,$fhflag,$noempty);

	my $datalist = [
		{title => "hoge",value => "huga"},
		{title => "hoge2",value => "huga"},
		{title => "hoge3",value => "huga"},
	];# 複数データの配列リファレンスのみ許される。
	my $fh; # 省略可能。ファイルハンドル。
	my $fhflag = 1; # 真値を与えればファイルハンドルを維持する。
	my $noempty = 1; # 真値を与えればファイルを空にせず、与えられたファイルハンドルのファイルポインタが先頭でないなら、その位置から書き出します。

ファイルを空にしてから新たにデータを書き出します。

成功なら第一返値に1、$fhflagが真なら第二返値にファイルハンドルを返す。失敗なら偽を返す。

=cut

sub writedata{
	my $self = shift;
	my $datalist = shift;
	my $fh = shift;
	my $fhflag = shift;
	my $noempty = shift;
	$datalist = [@{$datalist}]; # escape destructive operation
	splice @$datalist,0,$self->{index};
	unless(ref $fh eq 'GLOB'){
		my $encoding = $self->{encoding} ? ':encoding('.$self->{encoding}.')' : '';
		open $fh,'+<'.$encoding,$self->{filename} or open $fh,'>'.$encoding,$self->{filename} or return;
		flock $fh,2;
	}
	unless($noempty){
		truncate $fh,0;
		seek $fh,0,0;
	}
	return $self->adddata($datalist,$self->{index},$fh,$fhflag);
}

=begin comment

#=head3 writedatarange()

範囲内のデータをファイルに書き出す。

	$cc->writedatarange($datalist,$startindex,$endindex,$fh,$fhflag);

	my $datalist = [
		{title => "hoge",value => "huga"},
		{title => "hoge2",value => "huga"},
		{title => "hoge3",value => "huga"},
	];# 複数データの配列リファレンスのみ許される。
	my $startindex = 2; # 書き出すデータリストの最初のインデックス。0番目のデータから書き出すなら省略可能。
	my $endindex = 10; # 書き出すデータリストの最後のインデックス。最後のデータまで書き出すなら省略可能。
	my $fh; # 省略可能。ファイルハンドル。
	my $fhflag = 1; # 真値を与えればファイルハンドルを維持する。

与えられたファイルハンドルのファイルポインタが先頭でないなら、その位置から書き出します。

成功なら第一返値に1、$fhflagが真なら第二返値にファイルハンドルを返す。失敗なら偽を返す。

=end comment

=cut

=begin comment

sub writedatarange{
	my $self = shift;
	my $datalist = shift;
	my $startindex = shift;
	my $endindex = shift;
	my $fh = shift;
	my $fhflag = shift;
	$datalist = [@{$datalist}]; # escape destructive operation
	if($startindex){
		$startindex = $#$datalist + $startindex + 1 if $startindex < 0;
		if($startindex > $#$datalist){
			warn 'startindex is out of index range';
		}
	}else{
		$startindex = $self->{index};
	}
	splice @$datalist,0,$startindex > $self->{index} ? $startindex : $self->{index};
	if($endindex){
		$endindex = $#$datalist + $endindex + 1 if $endindex < 0;
		if($endindex > $#$datalist){
			warn 'endindex is out of index range';
		}elsif($endindex < $#$datalist){
			splice @$datalist,$endindex + 1;
		}
	}
	return $self->adddata($datalist,$startindex,$fh,$fhflag);
}

=end comment

=cut

=head3 readdata()

データをファイルから読み出す。

	$cc->readdata($fh,$fhflag);

	my $fh; # 省略可能。ファイルハンドル。
	my $fhflag = 1; # 真値を与えればファイルハンドルを維持する。

与えられたファイルハンドルのファイルポインタが先頭でないなら、その位置から読み出します。

成功なら第一返値にデータリストのリファレンス、$fhflagが真なら第二返値にファイルハンドルを返す。失敗なら偽を返す。

=cut

sub readdata{
	my $self = shift;
	my $fh = shift;
	my $data;
	my $fhflag = shift;
	unless(ref $fh eq 'GLOB'){
		$self->{encoding} ? open $fh,"+<:encoding($self->{encoding})",$self->{filename} : open $fh,'+<',$self->{filename} or return;
		seek $fh,0,0;
		flock $fh,2;
	}
	local $/ = $self->{linedelimiter} if $self->{linedelimiter};
	if($self->{delimiter}){
		my $indexcolumn = -1;
		my @key = @{$self->{order}};
		for my $i (0..$#key){
			if($key[$i] eq 1){$indexcolumn = $i;last;}
		}
		my $cnt = $self->{index} - 1;
		while(<$fh>){
			chomp;
			my @column = split /$self->{delimiter}/;
			$indexcolumn >= 0 ? $cnt = $column[$indexcolumn] : $cnt++;
			for my $i (0..$#column){
				$data->[$cnt]->{$key[$i]} = $column[$i] unless $key[$i] eq '1';
			}
		}
	}else{
		my @key = map { $_ % 2 ? $self->{order}->[$_] : () } (0..$#{$self->{order}});
		my @delim = map { $_ % 2 ? () : $self->{order}->[$_] } (0..$#{$self->{order}});
		my $lineregexpstr = '^'.(join '(.*?)',map {quotemeta} @delim) . '(?:' . quotemeta($/) . ')?$';
		my $lineregexp = qr/$lineregexpstr/;
		my $indexcolumn = -1;
		for my $i (0..$#key){
			if($key[$i] eq 1){$indexcolumn = $i;last;}
		}
		my $cnt = $self->{index} - 1;
		while(<$fh>){
			chomp;
			my @column = /$lineregexp/;
			$indexcolumn >= 0 ? $cnt = $column[$indexcolumn] : $cnt++;
			for my $i (0..$#column){
				$data->[$cnt]->{$key[$i]} = $column[$i] unless $key[$i] eq '1';
			}
		}
	}
	close $fh unless $fhflag;
	return $fhflag ? ($data,$fh) : $data;
}

=head3 readdatanum()

データをファイルから読む操作を省略し、そのインデックスのみを数える。

	$cc->readdatanum($fh,$fhflag);

	my $fh; # 省略可能。ファイルハンドル。
	my $fhflag = 1; # 真値を与えればファイルハンドルを維持する。

成功なら第一返値にデータリストの最大のインデックスまたはデータ数、$fhflagが真なら第二返値にファイルハンドルを返す。失敗なら偽を返す。

=cut

sub readdatanum{
	my $self = shift;
	my $fh = shift;
	my $fhflag = shift;
	unless(ref $fh eq 'GLOB'){
		$self->{encoding} ? open $fh,"+<:encoding($self->{encoding})",$self->{filename} : open $fh,'+<',$self->{filename} or return;
		seek $fh,0,0;
		flock $fh,2;
	}
	seek $fh,0,0;
	local $/ = $self->{linedelimiter} if $self->{linedelimiter};
	my $datanum = $self->{index} - 1;
	if($self->{delimiter}){
		my $indexcolumn = -1;
		for my $i (0..$#{$self->{order}}){
			if($self->{order}->[$i] eq 1){$indexcolumn = $i;last;}
		}
		if($indexcolumn < 0){$datanum++ while <$fh>;}
		else{$datanum = (split /$self->{delimiter}/)[$indexcolumn] while <$fh>;}
		chomp $datanum;
	}else{
		my @key = map { $_ % 2 ? $self->{order}->[$_] : () } (0..$#{$self->{order}});
		my @delim = map { $_ % 2 ? () : $self->{order}->[$_] } (0..$#{$self->{order}});
		my $lineregexpstr = '^'.(join '(.*?)',map {quotemeta} @delim) . '(?:' . quotemeta($/) . ')?$';
		my $lineregexp = qr/$lineregexpstr/;
		my $indexcolumn = -1;
		for my $i (0..$#key){
			if($key[$i] eq 1){$indexcolumn = $i;last;}
		}
		if($indexcolumn < 0){$datanum++ while <$fh>;}
		else{$datanum = (/$lineregexp/)[$indexcolumn] while <$fh>;}
	}
	close $fh unless $fhflag;
	return $fhflag ? ($datanum,$fh) : $datanum;
}

=begin comment

#=head3 _setwriteorder()

	$cc->_setwriteorder($order,$delimiter,$linedelimiter);
	$order = [1 title summary];
	$delimiter = "\n";
	$linedelimiter = "\n";

=end comment

=cut

sub _setwriteorder{
	my $order = shift;
	my $delimiter = shift;
	my $linedelimiter = shift;
	if($delimiter){
		return sub{
			my $fh = shift;
			my $datalist = shift;
			my $index = shift;
			local $/ = $linedelimiter if $linedelimiter;
			for my $data (@$datalist){
				print $fh (join $delimiter,map {$_ eq 1 ? $index : defined $data->{$_} ? $data->{$_} : ''} @$order),$/;
				$index ++;
			}
		};
	}else{
		return sub{
			my $fh = shift;
			my $datalist = shift;
			my $index = shift;
			local $/ = $linedelimiter if $linedelimiter;
			for my $data (@$datalist){
				print $fh (map {$_ % 2 ? $order->[$_] eq 1 ? $index : defined $data->{$order->[$_]} ? $data->{$order->[$_]} : '' : $order->[$_]} (0..$#{$order})),$/;
				$index ++;
			}
		};
	}
}

1;

=head1 DEPENDENCIES

This module requires no other modules and libraries.

=head1 NOTES

This module is written in object-oriented style but treating data by naked array or file handle so you should treat data by procedural style.

For example, if you want to delete 3,6 and 8th element in data list completely, the following code will be required.

	splice @$datalist,$_,1 for sort {$b <=> $a} qw(3 6 8);

So, if you want more smart OO, it will be better to use another modules that wraps naked array or file handle in OO (such as Object::Array ... etc?), or create Config::Column::OO etc. which inherit this module and can use methods pop, shift, splice, delete, etc.

=head1 AUTHOR

Narazaka (http://narazaka.net/)

=head1 COPYRIGHT AND LICENSE

Copyright 2011-2012 by Narazaka, all rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
