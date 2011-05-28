#!/usr/bin/perl 

my $infile = $ARGV[0];
my $filename = $infile;
my $outfile = $infile;
$outfile =~ s{^.*/}{};
$outfile = "out/$outfile";

my $info = `pdfinfo -f 1 -l 2 "$infile"`;
my($pages) = $info =~ m/Pages:\s*(\d+)/;

if ($pages == 1) {
# one page.  process to fix cropping damage
my($p1x,$p1y) = $info =~ m/Page\s+1\s+size:\s*(\d+)\s*x\s*(\d+)\s*pt/;
open NUP,'>','nup.tex' or die $!;
print NUP <<"END";
\\documentclass[]{article}
\\usepackage[paperwidth=${p1x}pt,paperheight=${p1y}pt,margin=0pt,nohead,nofoot]{geometry}
\\usepackage{pdfpages}
\\setlength{\\pdfpagewidth}{${p1x}pt}
\\setlength{\\pdfpageheight}{${p1y}pt}
\\begin{document}
\\includepdf[frame=false,fitpaper=false,trim=0 0 0 0,delta=0pt 0pt,offset=0pt 0pt,scale=1.0,turn=true,noautoscale=true]{$filename}
\\end{document}
END
close NUP;

system("pdflatex nup.tex");
system(qq{cp "nup.pdf" $outfile});

exit;

}

my($p1x,$p1y) = $info =~ m/Page\s+1\s+size:\s*(\d+)\s*x\s*(\d+)\s*pt/;
my($p2x,$p2y) = $info =~ m/Page\s+2\s+size:\s*(\d+)\s*x\s*(\d+)\s*pt/;
die("Cannot parse page sizes") unless $p1x && $p1y && $p2x && $p2y;

my $ty = $p1y+$p2y;
my $diffy = $p2y-$p1y;
my $deltay = ($p2y-$p1y)/2;
my $offsety = ($p2y-$p1y)/4;

if ($p2y > $p1y) {
# second page bigger than first: causes second page to shrink
	print STDERR "second page $diffy bigger than first!\n";
	open PDF,'<',$filename or die $!;
	local $/ = undef;
	my $pdf = <PDF>;
	close PDF;

	$pdf =~ s/(CropBox\s*\[\s*\d+\s+)(\d+)/$1.($2-$diffy)/e;

	open PDF,'>','nuptemp.pdf' or die $!;
	print PDF $pdf;
	close PDF;

	$filename = 'nuptemp.pdf';
	$deltay = -$diffy;
	$offsety = -$offsety;
}

open NUP,'>','nup.tex' or die $!;
print NUP <<"END";
\\documentclass[]{article}
\\usepackage[paperwidth=${p1x}pt,paperheight=${ty}pt,margin=0pt,nohead,nofoot]{geometry}
\\usepackage{pdfpages}
\\setlength{\\pdfpagewidth}{${p1x}pt}
\\setlength{\\pdfpageheight}{${ty}pt}
\\begin{document}
\\includepdfmerge[nup=1x2,frame=false,fitpaper=false,trim=0 0 0 0,delta=0pt ${deltay}pt,offset=0pt ${offsety}pt,scale=1.0,turn=true,noautoscale=true,column=false,columnstrict=false,openright=false]{$filename,1-2}
\\end{document}
END
close NUP;

system("pdflatex nup.tex");
system(qq{cp "nup.pdf" $outfile});


