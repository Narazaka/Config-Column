use utf8;
use strict;
use warnings;
use Test::More;

our $set = {
datafile => 'column.pson',
};

sub initdata{
	my $datafile = shift;
	my $data;
	open my $fh,'<:encoding(utf8)',$Bin.'/'.$datafile;
	flock $fh,1;
	{
		local $/ = undef;
		$data = eval <$fh>;
	}
	close $fh;
	return $data;
}

sub testmulticond{
	my $initdatafile = shift;
	my $datafilename = shift;
	my $encoding = shift;
	my $order = shift;
	my $delimiter = shift;
	note('type '.$datafilename);
	for my $index (0,1,'',undef){
		for my $linedelimiter ("\n","\r","\0",'|-|',':_','',undef){
			my $datafile = $datafilename .
				'_index-' . (defined $index ? $index ne '' ? $index : 'empty' : 'undef') .
				'_linedelimiter-' . (defined $linedelimiter ? $linedelimiter ne '' ? ord $linedelimiter : 'empty' : 'undef') .
				'.dat';
			testmain($initdatafile,$datafile,$encoding,$order,$delimiter,$index,$linedelimiter);
		}
	}
}

sub testmain{
	my $initdatafile = shift;
	my $datafile = shift;
	my $encoding = shift;
	my $order = shift;
	my $delimiter = shift;
	my $index = shift;
	my $linedelimiter = shift;
	note('-- set start');
	my $sdata = initdata($initdatafile);
	is(ref $sdata,'ARRAY','sample data loaded.');
	unshift @$sdata,{} if defined $index && $index eq 1;
	is($#$sdata,2+(defined $index && $index =~ /^\d+$/ ? $index : 0),'sample data condition.');
	my $cc = Config::Column->new($FindBin::Bin.'/'.$datafile,$encoding,$order,$delimiter,$index,$linedelimiter);
	$index = 0 unless defined $index && $index =~ /^\d+$/;
	isa_ok($cc,'Config::Column','new()');
	is($cc->writedata($sdata),1,'writedata(sample data)');
	my $data = $cc->readdata();
	is(ref $data,'ARRAY','readdata()');
	#return;
	is($#$data,2+$index,'readdata()');
	is($data->[0]->{host},undef,'data check') if $index eq 1;
	is($data->[0+$index]->{host},'localhost','data check');
	is($data->[0+$index]->{subject},'Config::Columnリリース','data check');
	is($data->[2+$index]->{mail},'info/at/narazaka.net','data check');
	is($cc->writedata($data),1,'writedata()');
	is($cc->adddatalast({name => '編集', subject => '', date => '2013/03/05 (月) 18:33:00', value => '一年ぶりか……。', mail => '', url => '', key => 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', host => 'narazaka.net', addr => '192.168.0.1'}),1,'adddatalast() and readdatanum()');
	is($cc->adddatalast([
		{name => 'さくら', subject => '', date => '2013/03/07 (月) 08:16:17', value => 'そうだね。', mail => '', url => '', key => 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', host => 'narazaka.net', addr => '192.168.0.1'},
		{name => '編集', subject => '', date => '2013/03/09 (月) 18:15:02', value => '誰やねん。', mail => '', url => '', key => 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', host => 'narazaka.net', addr => '192.168.0.1'},
	]),1,'adddatalast() and readdatanum()');
	$data = $cc->readdata();
	is(ref $data,'ARRAY','readdata()');
	is($#$data,5+$index,'readdata()');
	is($data->[0]->{host},undef,'data check') if $index eq 1;
	is($data->[0+$index]->{host},'localhost','data check');
	is($data->[0+$index]->{subject},'Config::Columnリリース','data check');
	is($data->[2+$index]->{mail},'info/at/narazaka.net','data check');
	is($data->[3+$index]->{name},'編集','data check');
	is($data->[4+$index]->{name},'さくら','data check');
	is($data->[5+$index]->{value},'誰やねん。','data check');
	splice @$data,2+$index,1;
	is($#$data,4+$index,'after splice');
	my ($ret,$fh) = $cc->writedata($data,undef,1);
	is($#$data,4+$index,'after writedata()');
	is($data->[2+$index]->{value},'一年ぶりか……。','after writedata()');
	is($ret,1,'writedata()');
	is(ref $fh,'GLOB','keep file handle');
	seek $fh,0,0;
	my ($data2) = $cc->readdata($fh,1);
	seek $fh,0,0;
	my $data3 = $cc->readdata($fh,1);
	seek $fh,0,0;
	my ($ret2,$fh2) = $cc->readdata($fh,1);
	is(ref $data2,'ARRAY','readdata()');
	is(ref $data3,'GLOB','readdata()');
	is(ref $ret2,'ARRAY','readdata()');
	is(ref $fh2,'GLOB','readdata()');
	truncate $fh2,0;
	seek $fh2,3,0;
	my ($ret3,$fh3) = $cc->writedata($data2,$fh2,1,1);
	is($ret3,1,'writedata()');
	is(ref $fh3,'GLOB','writedata() noempty');
	isnt(getc $fh3,1,'writedata() noempty');
	seek $fh3,3,0;
	my ($ret4) = $cc->readdata($fh3,1);
	is($ret4->[2+$index]->{value},'一年ぶりか……。','after writedata() noempty');
	pop @$data2;
	is($#$data2,3+$index,'poped');
	is($cc->writedata($data2,$fh),1,'writedata()');
	is($cc->readdatanum(),3+$index,'readdatanum()');
	is($cc->adddata({name => 'うにゅう', subject => '', date => '2013/03/10 (月) 08:17:27', value => 'ぐんにょり。', mail => '', url => '', key => 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', host => 'narazaka.net', addr => '192.168.0.1'},$cc->readdatanum + 1),1,'adddata()');
	my ($data4,$fh4) = $cc->readdata(undef,1);
	is($#$data4,4+$index,'readdata()');
	is(ref $fh4,'GLOB','readdata()');
	seek $fh4,0,0;
	is($cc->readdatanum($fh4),4+$index,'readdatanum()');
	is($data4->[4+$index]->{value},'ぐんにょり。','data check');
	$data4->[0+$index] = {};
	is($cc->writedata($data4),1,'writedata(sample data)');
	my $data5 = $cc->readdata();
	is(ref $data5,'ARRAY','readdata()');
	is($data5->[2+$index]->{name},'編集','data check');
	note('-- set end');
}

1;
