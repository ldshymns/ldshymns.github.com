#!/usr/bin/perl

sub slurp {
	local $/ = undef;
	my $file = shift;
	open INNI,'<',$file or die $!;
	my $data = <INNI>;
	close INNI;
	return $data;
}

sub hurl {
	my $file = shift;
	my $data = shift;
	open OUTI,'>',$file or die $!;
	print OUTI $data;
	close OUTI;
}


sub extract {
print <<"END";
<?xml version="1.0" encoding="utf-8"?>
<cropbox-data>
END

for my $file (glob "crop/*") {
	my $data = slurp $file;
	my $filename = $file;
	$filename =~ s{^.*/}{};

	my @cropbox = $data =~ m{ /CropBox \s* \[ (.*?) \] }simxg;

	print <<"END";
  <file src="$filename">
END
	for my $crop (@cropbox) {
		print <<"END";
    <cropbox data="$crop" />
END
	}
	print <<"END";
  </file>
END
}

print <<"END";
</cropbox-data>
END
}


sub inject {
	my $injectfile = shift;
	my $xml = slurp $injectfile;

	my @files = $xml =~ m{ (<file.*?</file>) }smixg;

	for my $filetag (@files) {
		my($filename) = m{ src="(.*?)" }smixg;
		my $data = slurp("orig/$filename");
		my @cropbox = $filetag =~ m{ <cropbox \s+ data="(.*?)" }smixg;
	
		my $n = 0;
		$data =~ s{ </CropBox \s* \[ \K .*? (?= \] ) }{$cropbox[$n++]}gesimx;
		hurl($filename,$data);
	}
}
