package Config::Column;
use utf8;
# use strict;
# use warnings;

our $VERSION = '2.00';

=encoding utf8

=head1 NAME

Config::Column - simply packages input and output of column oriented data files such as "BBS log file" etc. whose records are separated by any delimiter.

=head1 SYNOPSIS

	# Copy the data_list in a tab separated file to readable formatted text file.
	
	use utf8;
	use lib './lib';
	use Config::Column;
	my $order_delim = [qw(1 subject date value)];
	my $order_nodelim = ['' => 1 => ': [' => subject => '] ' => date => ' : ' => value => ''];
	my $delimiter = "\t";
	
	# MAIN file instance
	my $ccmain = Config::Column->new(
		'mainfile.dat', # the data file path (or file handle such as \*STDIN)
		'utf8', # character encoding of the data file (PerlIO ":encoding($layer)") or PerlIO layer (ex. ':encoding(utf8)')
		$order_delim, # list of key names
		$delimiter, # delimiter that separates data column
		1, # first index for data list
		"\0" # delimiter that separates data record ("lines")
	);
	# SUB file (human readable)
	my $ccsub = Config::Column->new(
		'', # this can be empty because data file will be opened externally and file handle is passed to this instance
		'', # same reason
		$order_nodelim, # list of key names and delimiters
		undef, # do not define delimiter
		1, # first index for data list
		# delimiter that separates data record ("lines") is Default
	);
	
	# Read data from MAIN file.
	my $data = $ccmain->read_data;
	# Add new data.
	push @$data,{subject => 'YATTA!', date => '2012/03/06T23:33:00+09:00', value => 'All tests passed!'};print $data;
	# Write data to MAIN file.
	$ccmain->write_data($data);
	# Write header to SUB file
	open my $file_handle,'+<:encoding(utf8)','subfile.txt';
	flock $file_handle,2;
	truncate $file_handle,0;
	seek $file_handle,0,0;
	print $file_handle 'Single line diary?',"\n";
	# Add data to SUB file. Don't close and don't truncate $file_handle.
	$ccsub->write_data($data,$file_handle,1,1);
	print $file_handle 'The end of the worl^h^h^h^hfile';
	close $file_handle;

=head1 INTRODUCTION

This module generalizes input and output of column oriented data files such as "config file" / "BBS log file".

Here is an example of column oriented data format (tab separated data).

	1	title1	new
	2	title2	second season
	3	title3	mannerism
	5	title5	never 4th season

This module treats data list as simple array reference of hash references.

	my $data_list = [
		{}, # If the first index for data list (see below section) is 1, 0th data is empty.
		{title => "hoge",value => "huga"},
		{title => "hoge2",value => "huga"},
		{title => "hoge3",value => "huga"},
	];

It manages only IO of that data list format and leaves data list manipulating to basic Perl operation.

=head1 DESCRIPTION

=head2 Constructor

=head3 new()

	my $cc = Config::Column->new(
		$file, # the data file path (or file handle such as \*STDIN)
		$layer, # character encoding of the data file (PerlIO ":encoding($layer)") or PerlIO layer (ex. ':encoding(utf8)')
		$order, # the "order" (see below section) (ARRAY REFERENCE)
		$delimiter, # delimiter that separates data column
		$index_shift, # first index for data list (may be 0 or 1 || can omit, and use 0 as default) (Integer >= 0)
		$record_delimiter, # delimiter that separates data record ("lines")(can omit, and use Perl default (may be $/ == "\n"))
		$escape # escape character for delimiters (including $record_delimiter)
	);

or with names,

	my $cc = Config::Column->new({
		file => $file,
		layer => $layer,
		order => $order,
		delimiter => $delimiter,
		index_shift => $index_shift,
		record_delimiter => $record_delimiter,
		escape => $escape
	});

C<$cc> will be instance of Config::Column if new() has succeeded.

=head4 Data file (C<$file>)

C<$file> is the data file path or file handle such as \*STDIN.

=over

=item If C<$file> is path string

File handle will be opened and closed at every timing of file operation by default.

=item If C<$file> is file handle

File handle will be kept over any file operation by default and you must close manually.

You can seek file pointer (by the method which is independent of this module) and can read/write data from/to the place that file pointer points, not the head of file.

=back

=head4 IO layer (C<$layer>)

C<$layer> is character encoding of the data file (will be converted to PerlIO layer string such as C<":encoding($layer)">) or PerlIO layer (ex. ':encoding(utf8)')

=head4 Index shift (C<$index_shift>)

C<$index_shift> is 0 or 1 in general.
For example, if C<$index_shift == 1>, you can get first data record by accessing to C<< $data_list->[1] >>, and C<< $data_list->[0] >> is empty.

=head4 Escaping (C<$escape>)

If you have defined C<$escape>, the delimiter strings in the data list are automatically escaped.
Two or more characters are permitted for C<$escape>, but if you want to use C<$escape>, delimiters should not be part of C<$escape>.

	{
		# orthodox
		$escape = "\\";
		$delimiter = "\t";
		$line_delimiter = "\n";
	}
	{
		# long
		$escape = "--";
		$delimiter = "//";
		$line_delimiter = "||";
	}
	{
		# delimiters are not part of $escape
		$escape = "aa";
		$delimiter = "aaaa";
		$line_delimiter = "\n";
	}
	{
		# FAIL: $delimiter is part of $escape
		$escape = "aaaa";
		$delimiter = "aa";
		$line_delimiter = "\n";
	}

There is two types of definition of C<$order> and C<$delimiter> for 2 following case.

=over

=head4 Delimiters and Orders (C<$delimiter>,C<$order>,C<$record_delimiter>)

=item single delimiter (You must define delimiter.)

	my $cc = Config::Column->new({
		file => './file.dat', # the data file path
		layer => 'utf8', # character encoding of the data file or PerlIO layer
		order => [qw(1 author id title date summary)], # the "order" [keys]
		delimiter => "\t", # You MUST define delimiter.
		index_shift => 1, # first index for data list
		record_delimiter => "\n", # delimiter that separates data record
		escape => "\\" # escape character for delimiters
	});

In this case, "order" is names (hash keys) of each data column.

It is for data formats such as tab/comma separated data(TSV/CSV).

=over

=item C<[qw(1 subject date article)]>

	1	This is the subject	2012/02/07	Article is there. HAHAHA!
	2	Tab separated data	2012/02/07	Tab separated data is for only computers.
	3	Escaping	2012/02/07	Tab\	is escaped by \

=back

=item multiple delimiters (Never define delimiter.)

	my $cc = Config::Column->new({
		file => './file.dat', # the data file path
		layer => 'utf8', # character encoding of the data file or PerlIO layer
		order => ['' => 1 => ': ' => 'author' => "\t" => 'id' => "\t" => 'title' => "\t" => 'date' => "\t" => 'summary'], # [delim key delim key ...]
		delimiter => undef, # NEVER define delimiter (or omit).
		index_shift => 1, # first index for data list
		record_delimiter => "\n", # delimiter that separates data record
		escape => "\\" # escape character for delimiters
	});

In this case, "order" is names (hash keys) of each data column and delimiters.

C<$order>'s 0,2,4...th (even) elements are delimiter, and 1,3,5...th (odd) elements are names (hash keys).

It is for data formats such as ...

=over

=item C<['', 1, ' [', subject, '] : ', date, ' : ', article]>

	1 [This is the subject] : 2012/02/07 : Article is there. HAHAHA!
	2 [Easy to read] : 2012/02/07 : Tab separated data is for only computers.

=item C<< ['', thread_number, '.dat<>', subject, ' (', res_number, ')'] # subject.txt (bracket delimiter is errorous) >>

	1325052927.dat<>Nurupo (988)
	1325387590.dat<>OKOTOWARI!!!!!! Part112 [AA] (444)
	1321698127.dat<>Marked For Death 18 (159)

=back

=back

=head5 Index column

The name "1" in C<$order> means the index of data records.

If the name "1" exists in C<$order>, integer in the index column will be used as array references' index.

	$delimiter = "\t";
	$order = [1,somedata1,somedata2];
	
	# data file
	1	somedata	other
	2	foobar	2000
	3	hoge	piyo
	5	English	isDifficult
	
	 |
	 | read_data()
	 v
	
	$data_list = [
		{}, # 0
		{somedata1 => 'somedata', somedata2 => 'other'}, # 1
		{somedata1 => 'foobar', somedata2 => '2000'}, # 2
		{somedata1 => 'hoge', somedata2 => 'piyo'}, # 3
		{}, # 4
		{somedata1 => 'English', somedata2 => 'isDifficult'}, # 5
	];
	
	 |               ^
	 | write_data()  | read_data()
	 v               |
	
	# data file
	1	somedata	other
	2	foobar	2000
	3	hoge	piyo
	4		
	5	English	isDifficult

=begin comment

#=head3 Definition of delimiters

C<$delimiter> is compiled to regular expressions finally.

In case of single delimiter,

	my @column = split /$delimiter/,$recordline;

In case of multiple delimiters, C<$record_delimiter> is also compiled to regular expressions.

	my $record_regexp_str = '^'.(join '(.*?)',map {quotemeta} @delimiters) . '(?:' . quotemeta($record_delimiter) . ')?$';
	my $record_regexp = qr/$record_regexp_str/;

=end comment

=cut

sub new{
	my $package = shift;
	$package = ref $package || $package;
	my ($file, $file_handle, $layer, $order, $delimiter, $index_shift, $record_delimiter, $escape);
	if(ref $_[0] eq 'HASH'){
		my $option = shift;
		$file = $option->{file};
		$layer = $option->{layer};
		$order = $option->{order};
		$delimiter = $option->{delimiter};
		$index_shift = $option->{index_shift};
		$record_delimiter = $option->{record_delimiter};
		$escape = $option->{escape};
	}else{
		$file = shift;
		$layer = shift;
		$order = shift;
		$delimiter = shift;
		$index_shift = shift;
		$record_delimiter = shift;
		$escape = shift;
	}
	if(ref $file eq 'GLOB'){
		$file_handle = $file;
		$file = undef;
	}
	$index_shift = 0 unless $index_shift;
	die 'invalid index_shift (not integer)' unless (int $index_shift) eq $index_shift && $index_shift > -1;
	return bless {
		file => $file,
		layer => $layer,
		order => $order,
		delimiter => $delimiter,
		index_shift => $index_shift,
		record_delimiter => $record_delimiter,
		escape => $escape,
		file_handle => $file_handle
	},$package;
}

=head2 Methods

=head3 C<add_data_last($data [, $file_handle_mode])>

This method adds data records to the data file after previous data in the file.
Indexes of these data records are automatically setted by reading the data file before.

	my $result = $cc->add_data_last($data,$file_handle_mode);
	my $result = $cc->add_data_last({
		data => $data, # data_list is same meaning
		file_handle_mode => $file_handle_mode # fhmode is same meaning
	});

=over

=item Arguments

C<$data> : Hash reference of single data record or array reference of hash references of multiple data records.

	$data = {title => "hoge",value => "huga"} || [
		{title => "hoge",value => "huga"},
		{title => "hoge2",value => "huga"},
		{title => "hoge3",value => "huga"},
	];

C<$file_handle_mode = ('keep' or 'close')> : If you set it, file handle treatment will be changed from default(see new()). (can omit)

=item Return values

C<$result == (1 or false)> : Succeed => 1, Fail => false.

=back

=cut

sub add_data_last{
	my $self = shift;
	my ($data_list, $file_handle_mode);
	if(ref $_[0] eq 'HASH' && ref $_[0]->{data_list}){ # ref $_[0]->{data_list} can omit data record such as {data_list => 'aaa'}
		my $option = shift;
		$data_list = $option->{data} || $option->{data_list};
		$file_handle_mode = $option->{file_handle_mode} || $option->{fhmode};
	}else{
		$data_list = shift;
		$file_handle_mode = shift;
	}
	$data_list = [$data_list] if ref $data_list eq 'HASH';
	my $data_num = $self->read_data_num('keep');
	return $self->add_data($data_list,$data_num + 1,$file_handle_mode);
}

=head3 C<add_data($data [, $start_index ,$file_handle_mode])>

This method adds data records to the data file.

	my $result = $cc->add_data($data,$start_index,$file_handle_mode);
	my $result = $cc->add_data({
		data => $data, # data_list is same meaning
		start_index => $start_index,
		file_handle_mode => $file_handle_mode # fhmode is same meaning
	});

=over

=item Arguments

C<$data> : Hash reference of single data record or array reference of hash references of multiple data records.

	$data = {title => "hoge",value => "huga"} || [
		{title => "hoge",value => "huga"},
		{title => "hoge2",value => "huga"},
		{title => "hoge3",value => "huga"},
	];

C<$start_index = NUMBER> : First index of the data record. (can omit if you don't want index numbers)

C<$file_handle_mode = ('keep' or 'close')> : If you set it, file handle treatment will be changed from default(see new()). (can omit)

=item Return values

C<$result == (1 or false)> : Succeed => 1, Fail => false.

=back

=cut

sub add_data{
	my $self = shift;
	my ($data_list, $start_index, $file_handle_mode);
	if(ref $_[0] eq 'HASH' && ref $_[0]->{data_list}){ # ref $_[0]->{data_list} can omit data record such as {data_list => 'aaa'}
		my $option = shift;
		$data_list = $option->{data} || $option->{data_list};
		$start_index = $option->{start_index};
		$file_handle_mode = $option->{file_handle_mode} || $option->{fhmode};
	}else{
		$data_list = shift;
		$start_index = shift;
		$file_handle_mode = shift;
	}
	$data_list = [$data_list] if ref $data_list eq 'HASH';
	unless(ref $self->{file_handle} eq 'GLOB'){
		die 'cannot open file because file name and file handle is invalid' unless defined $self->{file} && $self->{file} ne '';
		my $layer = $self->_layer();
		open $self->{file_handle},'+<'.$layer,$self->{file} or open $self->{file_handle},'>'.$layer,$self->{file} or die 'cannot open file [',$self->{file},']';
		flock $self->{file_handle},2;
		seek $self->{file_handle},0,2;
	}
	$self->_write_order($data_list,$start_index);
	$file_handle_mode = defined $self->{file} ? 'close' : 'keep' unless $file_handle_mode;
	if($file_handle_mode eq 'close'){
		close $self->{file_handle};
		undef $self->{file_handle};
	}elsif($file_handle_mode ne 'keep'){
		close $self->{file_handle};
		die 'file handle mode is invalid / closing file handle';
	}
	return 1;
}

=head3 C<write_data($data_list [, $file_handle_mode, $no_empty])>

This method writes data records to the data file.
Before writing data, the contents of the data file will be erased.

	my $result = $cc->write_data($data_list,$file_handle_mode,$no_empty);
	my $result = $cc->write_data({
		data_list => $data_list,
		file_handle_mode => $file_handle_mode, # fhmode is same meaning
		no_empty => $no_empty # noempty is same meaning
	});

=over

=item Arguments

C<$data_list> : Array reference of hash references of multiple data records.

	$data_list = [
		{title => "hoge",value => "huga"},
		{title => "hoge2",value => "huga"},
		{title => "hoge3",value => "huga"},
	];

C<$file_handle_mode = ('keep' or 'close')> : If you set it, file handle treatment will be changed from default(see new()). (can omit)

C<$no_empty = (1 or false)> : If it is true, the contents of the data file will not be erased, and writes data from the place current file pointer points not from the head of file.

=item Return values

C<$result == (1 or false)> : Succeed => 1, Fail => false.

=back

=cut

sub write_data{
	my $self = shift;
	my ($data_list, $file_handle_mode, $no_empty);
	if(ref $_[0] eq 'HASH'){
		my $option = shift;
		$data_list = $option->{data_list};
		$file_handle_mode = $option->{file_handle_mode} || $option->{fhmode};
		$no_empty = $option->{no_empty};
	}else{
		$data_list = shift;
		$file_handle_mode = shift;
		$no_empty = shift;
	}
	$data_list = [@{$data_list}]; # escape destructive operation
	splice @$data_list,0,$self->{index_shift};
	unless(ref $self->{file_handle} eq 'GLOB'){
		die 'cannot open file because file name and file handle is invalid' unless defined $self->{file} && $self->{file} ne '';
		my $layer = $self->_layer();
		open $self->{file_handle},'+<'.$layer,$self->{file} or open $self->{file_handle},'>'.$layer,$self->{file} or die 'cannot open file [',$self->{file},']';
		flock $self->{file_handle},2;
	}
	unless($no_empty){
		truncate $self->{file_handle},0;
		seek $self->{file_handle},0,0;
	}
	return $self->add_data($data_list,$self->{index_shift},$file_handle_mode);
}

=begin comment

#=head3 write_data_range()

範囲内のデータをファイルに書き出す。

	$cc->write_data_range($data_list,$start_index,$endindex,$file_handle,$keep_file_handle);

	my $data_list = [
		{title => "hoge",value => "huga"},
		{title => "hoge2",value => "huga"},
		{title => "hoge3",value => "huga"},
	];# 複数データの配列リファレンスのみ許される。
	my $start_index = 2; # 書き出すデータリストの最初のインデックス。0番目のデータから書き出すなら省略可能。
	my $endindex = 10; # 書き出すデータリストの最後のインデックス。最後のデータまで書き出すなら省略可能。
	my $file_handle; # 省略可能。ファイルハンドル。
	my $keep_file_handle = 1; # 真値を与えればファイルハンドルを維持する。

与えられたファイルハンドルのファイルポインタが先頭でないなら、その位置から書き出します。

成功なら第一返値に1、$keep_file_handleが真なら第二返値にファイルハンドルを返す。失敗なら偽を返す。

=end comment

=cut

=begin comment

sub write_data_range{
	my $self = shift;
	my $data_list = shift;
	my $start_index = shift;
	my $endindex = shift;
	my $file_handle = shift;
	my $keep_file_handle = shift;
	$data_list = [@{$data_list}]; # escape destructive operation
	if($start_index){
		$start_index = $#$data_list + $start_index + 1 if $start_index < 0;
		if($start_index > $#$data_list){
			warn 'start_index is out of index range';
		}
	}else{
		$start_index = $self->{index_shift};
	}
	splice @$data_list,0,$start_index > $self->{index_shift} ? $start_index : $self->{index_shift};
	if($endindex){
		$endindex = $#$data_list + $endindex + 1 if $endindex < 0;
		if($endindex > $#$data_list){
			warn 'endindex is out of index range';
		}elsif($endindex < $#$data_list){
			splice @$data_list,$endindex + 1;
		}
	}
	return $self->add_data($data_list,$start_index,$file_handle,$keep_file_handle);
}

=end comment

=cut

=head3 C<read_data([$file_handle_mode])>

This method reads data records from the data file.

	my $data_list = $cc->read_data($file_handle_mode);
	my $data_list = $cc->read_data({
		file_handle_mode => $file_handle_mode # fhmode is same meaning
	});


=over

=item Arguments

C<$file_handle_mode = ('keep' or 'close')> : If you set it, file handle treatment will be changed from default(see new()). (can omit)

=item Return values

C<$data_list> : Succeed => Data list in file (array reference of hash references), Fail => false

	$data_list = [
		{title => "hoge",value => "huga"},
		{title => "hoge2",value => "huga"},
		{title => "hoge3",value => "huga"},
	];

=back

=cut

sub read_data{
	my $self = shift;
	my $file_handle_mode;
	if(ref $_[0] eq 'HASH'){
		my $option = shift;
		$file_handle_mode = $option->{file_handle_mode} || $option->{fhmode};
	}else{
		$file_handle_mode = shift;
	}
	unless(ref $self->{file_handle} eq 'GLOB'){
		die 'cannot open file because file name and file handle is invalid' unless defined $self->{file} && $self->{file} ne '';
		open $self->{file_handle},'+<'.$self->_layer(),$self->{file} or die 'cannot open file [',$self->{file},']';
		flock $self->{file_handle},2;
		seek $self->{file_handle},0,0;
	}
	my $data = $self->_read_order();
	$file_handle_mode = defined $self->{file} ? 'close' : 'keep' unless $file_handle_mode;
	if($file_handle_mode eq 'close'){
		close $self->{file_handle};
		undef $self->{file_handle};
	}elsif($file_handle_mode ne 'keep'){
		close $self->{file_handle};
		die 'file handle mode is invalid / closing file handle';
	}
	return $data;
}

=head3 C<read_data_num([$file_handle_mode])>

This method reads data record's last index number from the data file.

	my $last_index = $cc->read_data_num($file_handle_mode);
	my $last_index = $cc->read_data_num({
		file_handle_mode => $file_handle_mode # fhmode is same meaning
	});

=over

=item Arguments

C<$file_handle_mode = ('keep' or 'close')> : If you set it, file handle treatment will be changed from default(see new()). (can omit)

=item Return values

C<$last_index == NUMBER> : Succeed => Last index of data list in file, Fail => false

=back

=cut

sub read_data_num{
	my $self = shift;
	my $file_handle_mode;
	if(ref $_[0] eq 'HASH'){
		my $option = shift;
		$file_handle_mode = $option->{file_handle_mode} || $option->{fhmode};
	}else{
		$file_handle_mode = shift;
	}
	unless(ref $self->{file_handle} eq 'GLOB'){
		die 'cannot open file because file name and file handle is invalid' unless defined $self->{file} && $self->{file} ne '';
		open $self->{file_handle},'+<'.$self->_layer(),$self->{file} or die 'cannot open file [',$self->{file},']';
		flock $self->{file_handle},2;
		seek $self->{file_handle},0,0;
	}
	my $file_handle = $self->{file_handle};
	local $/ = $self->{record_delimiter} if defined $self->{record_delimiter} && $self->{record_delimiter} ne '';
	my $data_num = $self->{index_shift} - 1;
	if($self->{delimiter}){
		my $index_column = -1;
		for my $i (0..$#{$self->{order}}){
			if($self->{order}->[$i] eq 1){$index_column = $i;last;}
		}
		if($index_column < 0){$data_num++ while <$file_handle>;}
		else{$data_num = (split /$self->{delimiter}/)[$index_column] while <$file_handle>;}
		chomp $data_num;
	}else{
		my @key = map { $_ % 2 ? $self->{order}->[$_] : () } (0..$#{$self->{order}});
		my @delim = map { $_ % 2 ? () : $self->{order}->[$_] } (0..$#{$self->{order}});
		my $record_regexp_str = '^'.(join '(.*?)',map {quotemeta} @delim) . '(?:' . quotemeta($/) . ')?$';
		my $record_regexp = qr/$record_regexp_str/;
		my $index_column = -1;
		for my $i (0..$#key){
			if($key[$i] eq 1){$index_column = $i;last;}
		}
		if($index_column < 0){$data_num++ while <$file_handle>;}
		else{$data_num = (/$record_regexp/)[$index_column] while <$file_handle>;}
	}
	$file_handle_mode = defined $self->{file} ? 'close' : 'keep' unless $file_handle_mode;
	if($file_handle_mode eq 'close'){
		close $self->{file_handle};
		undef $self->{file_handle};
	}elsif($file_handle_mode ne 'keep'){
		close $self->{file_handle};
		die 'file handle mode is invalid / closing file handle';
	}
	return $data_num;
}

=begin comment

### escaping read
my $esc = '   ';
my $escreg = quotemeta $esc;
my $delim = "\"";
my $delimreg = quotemeta $delim;
my $str1 = "start${delim}d:ads?a${esc}${delim}adada${esc}${esc}sda${esc}${delim}${esc}${esc}${esc}${esc}${delim}";
my $str2 = "start${delim}dadsa?${esc}${esc}${esc}${delim}adada\sda${esc}${esc}${esc}${delim}${delim}end${delim}";
print '1 : ',$str1,"\n";
print '2 : ',$str2,"\n";
#print 'e1: ',eval $str1,"\n";
#print 'e2: ',eval $str2,"\n";
$reg = qr/$delimreg((?:$escreg$escreg|$escreg$delimreg|[^$delimreg])*)$delimreg/;
print $reg,"\n";
print join ' / ',$str1 =~ $reg,"\n";
print join ' / ',$str2 =~ $reg,"\n";

=end comment

=cut

sub _write_order{
	my $self = shift;
	my $data_list = shift;
	my $index = shift;
	my $file_handle = $self->{file_handle};
	my $delimiter = $self->{delimiter};
	my @order = @{$self->{order}};
	local $/ = $self->{record_delimiter} if defined $self->{record_delimiter} && $self->{record_delimiter} ne '';
	if(defined $self->{delimiter} && $self->{delimiter} ne ''){ # has delimiter
		for my $data (@$data_list){
			print $file_handle (join $delimiter,map {$_ eq 1 ? $index : defined $data->{$_} ? $data->{$_} : ''} @order),$/;
			$index ++;
		}
	}else{ # no delimiter
		for my $data (@$data_list){
			print $file_handle (map {$_ % 2 ? $order[$_] eq 1 ? $index : defined $data->{$order[$_]} ? $data->{$order[$_]} : '' : $order[$_]} (0..$#order)),$/;
			$index ++;
		}
	}
}

sub _read_order{
	my $self = shift;
	my $file_handle = $self->{file_handle};
	my @key;
	my $record_regexp;
	local $/ = $self->{record_delimiter} if defined $self->{record_delimiter} && $self->{record_delimiter} ne '';
	my $delimiter_mode;
	if(defined $self->{delimiter} && $self->{delimiter} ne ''){ # has delimiter
		$delimiter_mode = 1;
		@key = @{$self->{order}};
	}else{ # no delimiter
		$delimiter_mode = 0;
		@key = map { $_ % 2 ? $self->{order}->[$_] : () } (0..$#{$self->{order}});
		my @delim = map { $_ % 2 ? () : $self->{order}->[$_] } (0..$#{$self->{order}});
		my $record_regexp_str = '^'.(join '(.*?)',map {quotemeta} @delim) . '(?:' . quotemeta($/) . ')?$';
		$record_regexp = qr/$record_regexp_str/;
	}
	my $index_column = -1;
	my $key_column = -1;
	my @ref_column = 0..$#key;
	for my $i (0..$#key){
		if($key[$i] eq 1){
			$index_column = $i;
			last;
		}elsif($key[$i] eq '0'){
			$key_column = $i;
			last;
		}
	}
	my ($c,$k);
	my $ik_mode;
	if($key_column != -1){
		splice @ref_column, $key_column, 1;
		$ik_mode = 2;
	}elsif($index_column != -1){
		splice @ref_column, $index_column, 1;
		$ik_mode = 1;
	}else{
		$c = $self->{index_shift} - 1;
		$ik_mode = 0;
	}
	my $data;
	while(<$file_handle>){
		chomp;
		my @column = $delimiter_mode ? split /$self->{delimiter}/ : /$record_regexp/;
		if($ik_mode == 2){
			$k = $column[$key_column];
			$data->{$k}->{$key[$_]} = $column[$_] for @ref_column;
		}elsif($ik_mode == 1){
			$c = $column[$index_column];
			$data->[$c]->{$key[$_]} = $column[$_] for @ref_column;
		}else{
			$c++;
			$data->[$c]->{$key[$_]} = $column[$_] for @ref_column;
		}
	}
	return $data;
}

sub _layer{
	my $self = shift;
	return $self->{layer} ? $self->{layer} =~ /:/ ? $self->{layer} : ':encoding('.$self->{layer}.')' : '';
}

1;

=head1 DEPENDENCIES

This module requires no other modules and libraries (core module ExtUtils::MakeMaker is required when you use cpan or make to install).

=head1 NOTES

=head2 OOP

This module is written in object-oriented style but treating data by naked array or file handle so you should treat data by procedural style.

For example, if you want to delete 3,6 and 8th element in data list completely, the following code will be required.

	splice @$data_list,$_,1 for sort {$b <=> $a} qw(3 6 8);

So, if you want more smart OO, it will be better to use another modules that wraps naked array or file handle in OO (such as Object::Array ... etc?), or create Config::Column::OO etc. which inherits this module and can use methods pop, shift, splice, delete, etc.

=head2 Escaping

I think current implement of the regexp of escaping (includes slow C<(..|..|..)>) is not the best.

=head2 For legacy system

Perl <= 5.6.x does not have PerlIO.
C<$layer> of this module is for character encoding and depends on PerlIO, so you should empty C<$layer> on Perl 5.6.x or older.

=head2 Compatibillity

This is Config::Column 2 and not compatible with Config::Column 1.00 by some points(mostly, file handle treatment and related arguments).

Features of file handle and its flag arguments of most methods has been replaced to constructor(C<new()>)'s file argument and most methods' C<$file_handle_mode> argument.

=head1 TODO

Odd Engrish

=head1 AUTHOR

Narazaka (http://narazaka.net/)

=head1 COPYRIGHT AND LICENSE

Copyright 2011-2012 by Narazaka, all rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
