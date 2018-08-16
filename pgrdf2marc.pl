#!/usr/bin/perl -w
# 
# pgrdf2marc.pl converts one or more items from the Project Gutenberg RDF
# catalog into MARC format record(s).
#
# Detailed POD-style documentation is at the end of this file.

use strict;
use Getopt::Long;
use Fcntl;

#-----------------------------------------------------------------------
# Configurables:

# Organisation code
my $org = 'PGUSA';

my $publisher = 'Project Gutenberg';

my $root = "/ebooks/web/meta/pg/marc";

#-----------------------------------------------------------------------
# NON-Configurables:

# ISO 639 Language Codes

# populate a hash mapping 639-1 (2-letter) codes to 639-2 (3-letter) codes

my %map639 = qw(
	ab  abk aa  aar af  afr sq  alb am  amh ar  ara hy  arm as  asm
	ay  aym az  aze ba  bak eu  baq bn  ben bh  bih bi  bis be  bre
	bg  bul my  bur be  bel ca  cat zh  chi co  cos hr  scr cs  cze
	da  dan nl  dut dz  dzo en  eng eo  epo et  est fo  fao fj  fij
	fi  fin fr  fre fy  fry gl  glg ka  geo de  ger el  gre kl  kal
	gn  grn gu  guj ha  hau he  heb hi  hin hu  hun is  ice id  ind
	ia  ina iu  iku ik  ipk ga  gle it  ita ja  jpn jv  jav kn  kan
	ks  kas kk  kaz km  khm rw  kin ky  kir ko  kor ku  kur oc  oci
	lo  lao la  lat lv  lav ln  lin lt  lit mk  mac mg  mlg ms  may
	ml  mlt mi  mao mr  mar mo  mol mn  mon na  nau ne  nep no  nor
	or  ori om  orm pa  pan fa  per pl  pol pt  por ps  pus qu  que
	rm  roh ro  rum rn  run ru  rus sm  smo sg  sag sa  san sr  scc
	sh  scr sn  sna sd  snd si  sin ss  ssw sk  slo sl  slv so  som
	st  sot es  spa su  sun sw  swa sv  swe tl  tgl tg  tgk ta  tam
	tt  tat te  tel th  tha bo  tib ti  tir to  tog ts  tso tn  tsn
	tr  tur tk  tuk tw  twi ug  uig uk  ukr ur  urd uz  uzb vi  vie
	vo  vol cy  wel wo  wol xh  xho yi  yid yo  yor za  zha zu  zul
);

$/ = "</rdf:RDF>\n";

# %cat is a temporary hash for the data extracted from RDF for each item.
my %cat;

my %options = ( debug => 0 );
GetOptions(\%options, 'debug!', 'help');

if ($options{'help'}) {
    print qq!
pgrdf2marc.pl converts the Project Gutenberg RDF/XML format catalog into
MARC21 format records. RDF is read from STDIN, and MARC output to STDOUT.

Usage: pgrdf2marc.pl [ --help | --debug ]

	--debug will dump the RDF and the MARC in text form

	--help prints this message

!;
    exit;
}

my $today = today();

#-----------------------------------------------------------------------

my $rdfrecs = 0;
my $marcrecs = 0;
my $changes = 0;
my $newrecs = 0;
my %MARCDB = ();

while (<>) {

	next unless /rdf:about="ebooks\/(\d+)"/;

	$rdfrecs++;

	tr/\r/ /; # remove CR (if any)

	# convert commonly used character entities
	s/ &amp; / and /sg;
	s/&amp;/&/sg;
	s/&#x2014;/--/sg;

	if (parse_rdf($_)) {
		my @trec = build_trec();

		my $marc = array2marc(@trec);
		my $id = $cat{id};

		$MARCDB{$id} = $marc;

		$marcrecs++;
	}
}

# now write out the MARC records to files, in bundles of 1000

my $outlimit = 0;

foreach my $id ( sort {$a <=> $b} keys %MARCDB ) {
	if ( $id > $outlimit ) {
		close OUT if $outlimit;
		$outlimit += 1000;
		my $outfile = sprintf "$root/%06d.mrc", $outlimit;
		open OUT, ">$outfile" or die "Cannot open $outfile, $!\n";
	}
	print OUT $MARCDB{$id};
}

close OUT;

print STDERR qq|
	$rdfrecs RDF records processed
	$marcrecs MARC records written
|;

exit(0);

#-----------------------------------------------------------------------

sub parse_rdf {
    # parse an rdf entry and store the data in our catalogue hash

    # discard any whitespace between xml tags
    s/>\s+</></gs;

    # clear %cat;
    %cat = ();

    $cat{title} = [];

    $cat{created} = '||||-||-||';
    
    # record must have an id ...
    #if (/rdf:ID="etext(\d+)"/)
    if ( /rdf:about="ebooks\/(\d+)"/ ) 
    { $cat{id} = $1; } else { return 0; }

    # ... and a title ...
    unless (/<dcterms:title.*?>(.*?)<\/dcterms:title>/s) {
	print STDERR "$cat{id} has no title!\n";
	return 0;
    }

    s/<dcterms:hasFormat.*?>(.*?)<\/dcterms:hasFormat>//sg;
    s/<rdf:Description rdf:about.*?>(.*?)<\/rdf:Description>//isg;
    s/&#13;/ /g;

    while (s/<dcterms:title.*?>(.*?)<\/dcterms:title>//s) {
	push @{$cat{title}}, $1;
    }

    if (/<dcterms:issued.*?>(.*)<\/dcterms:issued>/) {
	$cat{created} = $1;
    }

#    <dcterms:language>
#        <rdf:Description rdf:nodeID="Nddaff0422306417f9aab0354ea9e9cec">
#	    <rdf:value rdf:datatype="http://purl.org/dc/terms/RFC4646">fi</rdf:value>
#	</rdf:Description>
#    </dcterms:language>
    if (m!<dcterms:language><rdf:Description.*?><rdf:value.*?>(.+)</rdf:value></rdf:Description></dcterms:language>!) {
	$cat{language} = $1;
    }

#    <dcterms:type>
#      <rdf:Description rdf:nodeID="N9285a4dda32d407ea903661fa99df989">
#        <rdf:value>MovingImage</rdf:value>
#        <dcam:memberOf rdf:resource="http://purl.org/dc/terms/DCMIType"/>
#      </rdf:Description>
#    </dcterms:type>
    if (m{<dcterms:type>.*?<rdf:value.*?>(.*)</rdf:value>.*?</dcterms:type>}) {
	$cat{type} = $1;
    }

    if (/<dcterms:rights>(.*)<\/dcterms:rights>/) {
	$cat{rights} = $1;
    }

    if (/<dcterms:creator.*?>(.+?)<\/dcterms:creator>/s) {
	my ($name) = (/<pgterms:name>(.+?)<\/pgterms:name>/);
	my ($birth) = (/<pgterms:birthdate.*?>(.+?)<\/pgterms:birthdate>/);
	my ($death) = (/<pgterms:deathdate.*?>(.+?)<\/pgterms:deathdate>/);
	$birth = '' unless $birth;
	$death = '' unless $death;
	if ($birth or $death) { $name .= ", $birth-$death"; }
	push @{$cat{author}}, $name;
	#$cat{author} = [ split_field($1) ];
    }

    if (/<dcterms:contributor.*?>(.*?)<\/dcterms:contributor>/s) {
	push @{$cat{contributor}}, $1;
    }

#    <dcterms:subject>
#      <rdf:Description rdf:nodeID="N43d1b37d59924030a921ee7ada41e4e9">
#        <dcam:memberOf rdf:resource="http://purl.org/dc/terms/LCSH"/>
#        <rdf:value>Netherlands -- History -- Eighty Years' War, 1568-1648</rdf:value>
#      </rdf:Description>
#    </dcterms:subject>

#    <dcterms:subject>
#      <rdf:Description rdf:nodeID="N338916d4ddc8460ab151abfd1952601f">
#        <rdf:value>DH</rdf:value>
#        <dcam:memberOf rdf:resource="http://purl.org/dc/terms/LCC"/>
#      </rdf:Description>
#    </dcterms:subject>

    while (/<dcterms:subject>(.+?)<\/dcterms:subject>/sg) {
	my $s = $1;
	my ($v) = ($s =~ /<rdf:value>(.+?)<\/rdf:value>/s);
	my ($t) = ($s =~ m{<dcam:memberOf rdf:resource="http://purl.org/dc/terms/(.+?)"/>});
	push @{$cat{subject}}, $v if $t eq 'LCSH';
	push @{$cat{call}}, $v if $t eq 'LCC';
    }

    while (/<dcterms:alternative.*?>(.*?)<\/dcterms:alternative>/isg) {
	my $string = $1;
	$string =~ s/\s+/ /gs;
	push @{$cat{alternative}}, $string;
    }

    if (/<dcterms:description.*?>(.*?)<\/dcterms:description>/is) {
	my $string = $1;
	$string =~ s/\s+/ /gs;
	push @{$cat{description}}, $string;
    }

    if (/<dcterms:tableOfContents.*?>(.*?)<\/dcterms:tableOfContents>/is) {
	my $string = $1;
	$string =~ s/\n/ -- /gs;
	$string =~ s/\s+/ /gs;
	push @{$cat{contents}}, $string;
    }

    # experimental kludge to determine genre 
    # genre is the 'Literary form' specified in the 008 character pos. 33
    GENRE: {
	if (/other (stories|tales)/i) { $cat{genre} = 'j'; last; }
	if (/(poems|poetry)/i) { $cat{genre} = 'p'; last; }
	if (/essays/i) { $cat{genre} = 'e'; last; }
	if (/letters/i) { $cat{genre} = 'i'; last; }
	if (/plays/i) { $cat{genre} = 'd'; last; }
	if (/fiction/i) { $cat{genre} = '1'; last; }
	$cat{genre} = '|';
    }

    return 1;
}

sub split_field {
    # split a (possibly) multivalued field, returning values as an array.
    my $field = shift;
    # join multiple lines
    $field =~ s/>\s+<//gs;
    $field =~ s/&quot;/"/g;
    my @array;
    if ($field =~ /rdf:/i) {
        while ($field =~ s/>([^<]+)<//s) {
            push @array, $1;
        }
    } else {
        push @array, $field;
    }
    return @array;
}

#-----------------------------------------------------------------------

sub build_trec {
    # use %cat to build a text array of the MARC record
    my @trec = ();

    my ($ind2, $resp, $pubyear, $temp);
    my ($name, $q, $d, $role);

    my $id		= $cat{id};
    my $created		= $cat{created};
    my $language    	= $cat{language};
    my $genre 		= $cat{genre};
    my $type 		= $cat{type};
    my $rights 		= $cat{rights};

    my @titles    	= @{ $cat{title} };
    my @alternative	= @{ $cat{alternative} } if $cat{alternative};
    my @authors    	= @{ $cat{author} }	 if $cat{author};
    my @contribs	= @{ $cat{contributor} } if $cat{contributor};
    my @subjects   	= @{ $cat{subject} }	 if $cat{subject};
    my @call    	= @{ $cat{call} }	 if $cat{call};
    my @description    	= @{ $cat{description} } if $cat{description};
    my @contents    	= @{ $cat{contents} }	 if $cat{contents};

    
    # created is formatted as "yyyy-mm-dd" ...
    $created = '||||-||-||' unless defined $created;

    # extract a publication date (year only)
    $pubyear = substr $created, 0, 4;

    # reformat creation date as "yymmdd" for 008
    $created =~ s/-//g;
    $created = substr $created, 2, 6;
    # (N.B. the 008 date is the create date for the MARC record.
    # We're pretending that this is the same as the etext. Otherwise,
    # this could just be today's date.)

    $language = 'en' if (! defined $language);
    my $lang639 = $map639{$language};
    $lang639 = '|||' unless defined $lang639;

    unless ($type) { $type = "Electronic text"; }
    if ($type =~ /(.*), (.*)/) { $type = "$2 $1"; }
    $type =~ s/(Still|Moving)Image/$1 Image/;

    # start building the marc text array
    push @trec, "000 00568cam a22001693a 4500";

    push @trec, "001 $id";
    push @trec, "003 $org";
    
    # time stamp -- this is the date the record was created, not the PG item
    push @trec, sprintf "005 %s", timestamp();

    push @trec, sprintf "008 %6ss%4s||||xxu|||||s|||||000 %1s %3s d",
        $created, $pubyear, $genre, $lang639;

    push @trec, sprintf "040   |a%s|b%s", $org, $lang639;
    push @trec, "042   |adc";

    foreach (@call) {
        push @trec, sprintf "050  4|a%s", $_;
    }

    if (@authors) {

        my ($tag, $name, $d, $q, $c, undef) = munge_author( shift @authors );
	unless ($name =~ /(Various|Anonymous)/i) {
	    $temp = sprintf "$tag 1 |a%s", $name;
	    $temp .= "|c$c" if $c;
	    $temp .= "|q$q" if $q;
	    $temp .= ",|d$d" if $d;
	    push @trec, $temp;
	}
    }

    my $ut = @alternative;
    if ( $ut == 1 and $alternative[0] =~
	    /(Catalan|Czech|Dutch|English|Esperanto|Finnish|French|German|Greek|Polish|Portuguese|Romany|Spanish)$/ )
    {
	my $title = shift @alternative;
	my $ind2 = nonfilingIndicator( $title, $language );
	$title =~
	    s{ (Catalan|Czech|Dutch|English|Esperanto|Finnish|French|German|Greek|Polish|Portuguese|Romany|Spanish)$}
	     {|l$1};
	push @trec, sprintf "240 1%1d|a%s", $ind2, $title;
	$ut = 0;
    }

    # PG records can have 1 or 2 titles
    # If there are 2, the first one is a Uniform title
    $ut = $#titles;
    print STDERR "$id has $ut too many titles\n" if $ut > 1;

    foreach my $title (@titles) {

	# if the title contains line breaks, then the first marks the start of a subtitle, and
	# any others are a mistake.
	$title =~ s/\n/ : /s;
	$title =~ s/\n/ /gs;

	$ind2 = nonfilingIndicator( $title, $language );

	if ( $ut ) { # Uniform title

	    $title =~
	    s{ (Catalan|Czech|Dutch|English|Esperanto|Finnish|French|German|Greek|Polish|Portuguese|Romany|Spanish)$}
	     {|l$1};
	    push @trec, sprintf "240 1%1d|a%s", $ind2, $title;
	    $ut = 0;

	} else { # main title

	    $title =~ s/Other Stories/other stories/i;
	    for ($title) {
		my ($a, $b) = split /:/, $title, 2;
		if ( defined $b ) {
		    $b =~ s/^\s+//;
		    if ( $b =~ s/^(and|or),{0,1} /$1, / ) {
			$title = "$a ;|b$b";
		    } elsif ($b) {
			$title = "$a :|b$b";
		    }
		}
	    }
	    $title =~ s/\s+/ /g;
	    $resp = resp_stmt();
	    if ($resp) {
		push @trec, sprintf
		"245 1%1d|a%s|h[electronic resource] /|c%s", $ind2, $title, $resp;
	    } else {
		push @trec, sprintf
		"245 1%1d|a%s|h[electronic resource]", $ind2, $title;
	    }
	}
    }

    push @trec, "260   |b$publisher,|c$pubyear";
    #push @trec, "500    |a Project Gutenberg";

    # Description
    foreach (@description) {
	push @trec, sprintf "500   |a%s", $_;
    }

    # Contents note
    if (@contents) {
	if ($#contents > 0) { # more than one element in contents!
	    push @trec, sprintf "505 0 |a%s", (join '--', @contents);
	} else {
	    push @trec, sprintf "505 0 |a%s", $contents[0];
	}
    }

    # Rights management / copyright statement
    if ($rights) {
	push @trec, "506   |a$rights";
    } else {
	push @trec, "506   |aFreely available.";
    }
    push @trec, "516   |a$type";

    # Subject headings
    # Note: we're using the 653 "uncontrolled terms" field, not LCSH
    foreach (@subjects) {
        push @trec, sprintf "653   |a%s", $_;
    }

    foreach (@authors) {
        my ($tag, $name, $d, $q, $c, $role) = munge_author( $_ );
	$tag += 600;
	$temp = "$tag 1 |a$name";
	$temp .= "|c$c" if $c;
	$temp .= "|q$q" if $q;
	$temp .= ",|d$d" if $d;
	$temp .= ",|e$role" if $role;
	push @trec, $temp;
    }

    foreach (@contribs) {
        my ($tag, $name, $d, $q, $c, $role) = munge_author( $_ );
	$tag += 600;
	$temp = "$tag 1 |a$name";
	$temp .= "|c$c" if $c;
	$temp .= "|q$q" if $q;
	$temp .= ",|d$d" if $d;
	$temp .= ",|e$role" if $role;
	push @trec, $temp;
    }

    foreach (@alternative) {
        push @trec, sprintf "740 0 |a%s", $_;
    }

    push @trec, sprintf "830  0|aProject Gutenberg|v%d", $id;
    push @trec, sprintf "856 40|uhttp://www.gutenberg.org/ebooks/%d", $id;

    push @trec, "856 42|uhttp://www.gutenberg.org/license|3Rights"
	unless $rights;

    return @trec;
}

sub nonfilingIndicator {
	# set non-filing indicator for title.
	my ($title, $language) = @_;

	my $ind2 = 0;
	ARTICLE_CASE: {
	    if ($language eq 'en') { # English
		$ind2 = 4 if $title =~ /^The /;
		$ind2 = 3 if $title =~ /^An /;
		$ind2 = 2 if $title =~ /^A /;
		last;
	    }
	    if ($language eq 'fr') { # French
		$ind2 = 4 if $title =~ /^(Les|Une) /;
		$ind2 = 3 if $title =~ /^(Un|Le|La) /;
		$ind2 = 2 if $title =~ /^L'/;
		last;
	    }
	    if ($language eq 'de') { # German
		$ind2 = 5 if $title =~ /^Eine /;
		$ind2 = 4 if $title =~ /^(Ein|Der|Das|Die) /;
		last;
	    }
	    if ($language eq 'du') { # Dutch
		$ind2 = 4 if $title =~ /^(Een|Ene|Het) /;
		$ind2 = 3 if $title =~ /^De /;
		last;
	    }
	    if ($language eq 'es') { # Spanish
		$ind2 = 4 if $title =~ /^(Las|Los) /;
		$ind2 = 3 if $title =~ /^El /;
		last;
	    }
	    if ($language eq 'it') { # Italian
		$ind2 = 3 if $title =~ /^Il /;
		last;
	    }
	    if ($language eq 'pt') { # Portuguese
		$ind2 = 4 if $title =~ /^(Uma) /;
		$ind2 = 3 if $title =~ /^(As|Os|Um) /;
		$ind2 = 2 if $title =~ /^(A|O) /;
		last;
	    }
	}
	return $ind2;
}

sub munge_author {
    my $name = shift;
    my ($d, $q, $c, $role);
    my $tag = '100';
    if ( $name =~ /(agency|assembly|association|bureau|coalition|committee|commune|community|company|corporation|council|department|league|library|ministry|national|office|society|state board|federal board|board of trade|england and wales|episcopal church|america|united states|great britain)/i )
    {
	$tag = '110';
    }
    else
    {
	# extract and discard role -- between []
	if ($name =~ s/ \[([^\]]+)\]//) { $role = "\L$1\E"; }

	# extract the dates (if any) and discard from name
	# dates are assumed as anything starting with a digit
	if ($name =~ s/, ([1-9-].+)//) { $d = $1; }

	# extract and discard any expanded forenames -- these will be in ()
	if ($name =~ s/ (\(.+\))//) { $q = $1; }

	# extract and discard title
	if ($name =~ s/ (Sir|Lord|Mrs|Rev|Saint|Dr|Jr)\b\.{0,1}//) { $c = $1; }
    }
    return ($tag, $name, $d, $q, $c, $role);
}

sub resp_stmt {
    # generate a statement of responsibility from the author fields
    my ($author, $tag, $name, $role, $resp);
    my @authors	 = @{ $cat{author} } if $cat{author};
    my @contribs = @{ $cat{contributor} } if $cat{contributor};
    $resp = '';

    # first author ...
    $author = shift @authors; 
    if ($author) {
        ($tag, $name, undef) = munge_author( $author );
        if ($name =~ /(.*?), (.*)/) { $name = "$2 $1"; }
        $resp = "$name";
    }
    # followed by any additional authors ...
    while ($author = shift @authors) {
        ($tag, $name, undef) = munge_author( $author );
        if ($name =~ /(.*?), (.*)/) { $name = "$2 $1"; }
	if (@authors) {
	    $resp .= ", $name";
	} else {
	    $resp .= " and $name";
	}
    }
    # followed by contributors ...
    foreach $author (@contribs) {
        ($tag, $name, undef, undef, undef, $role) = munge_author( $author );
	next unless $role;
        if ($name =~ /(.*?), (.*)/) { $name = "$2 $1"; }
	while (defined $role) {
	    if ($role =~ /edit/i) { $resp .= "; edited by $name"; last; }
	    if ($role =~ /Trans/i) { $resp .= "; translated by $name"; last; }
	    if ($role =~ /Illus/i) { $resp .= "; illustrated by $name"; last; }
	    #$resp .= "; $name";
	    #if ($role) { $resp .= " ($role)"; }
	    last; # only one pass thru required!
	}
    }
    $resp =~ s/\s+/ /g;
    return $resp;
}

#-----------------------------------------------------------------------

sub today {
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    return sprintf "%4d-%02d-%02d.%02d%02d", $year+1900, $mon+1, $mday, $hour, $min;
}

sub timestamp {
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    return sprintf "%4d%02d%02d%02d%02d%02d.0", $year+1900, $mon+1, $mday, $hour, $min, $sec;
}

#-----------------------------------------------------------------------

sub array2marc {
    my @trec = @_;

    # initialise stuff
    my $offset = 0;
    my $dir = '';
    my $data = '';

    # default pattern for leader
    my $ldrpat = "%05dnas  22%05duu 4500";

    my ($line, $field, $tag, $fldlen, $base);

    # if a leader is included, build the pattern from that ...
    if ( $trec[0] =~ /^000/ ) { # leader codes
	$line = shift(@trec);
	# use the leader to create a pattern for building the leader later on
	# only the RS, MC, BLC, EL, DCC and Linked are used
	$ldrpat = '%05d'.substr($line,9,5).'22%05d'.substr($line,21,3).'4500';
    }

    # process all the tags in sequence
    foreach $line ( @trec ) {

	# build the directory and data portions
	$tag = substr($line, 0, 3);
	$field = substr($line, 4);		# get the data for the tag
	unless ($tag lt '010') {
	    $field =~ tr/\|/\037/s;	# change subfield delimiter(s)
	}
	$field =~ s/$/\036/;	# append a field terminator
	$fldlen = length($field);
	$dir .= sprintf("%3s%04d%05d",$tag,$fldlen,$offset);
	$offset += $fldlen;
	$data .= $field;
    }

    # append a field terminator to the directory
    $dir =~ s/$/\036/;

    # append the record terminator
    $data =~ s/$/\035/;

    # compute lengths
    $base = length($dir) + 24;	# base address of data
    my $lrl = $base + length($data);	# logical record length

    # return the complete MARC record
    return (sprintf $ldrpat,$lrl,$base)			# leader
	    . $dir					# directory
	    . $data;					# data

}

__END__

=head1 NAME

pgrdf2marc.pl

=head1 DESCRIPTION

pgrdf2marc.pl converts one or more items from the Project Gutenberg RDF
catalog into MARC format record(s).

The RDF is read from STDIN, and the MARC output to STDOUT.

Dublin Core tags used in the RDF are:

    dcterms:title
    dcterms:alternative
    dcterms:creator
    dcterms:contributor -- NOT USED
    dcterms:tableOfContents
    dcterms:publisher
    dcterms:rights
    dcterms:language
    dcterms:created
    dcterms:type
    dcterms:LCSH
    dcterms:LCC


A MARC record is simply an ASCII string of arbitrary length.

=head2 MARC record structure

    Leader: start: 0 length: 24
	Base Address (start of data): start: 12 length: 5
    Directory: start: 24, length: (base - 24)
	Tag number: 3 bytes
	data length: 4 bytes
	data offset: 5 bytes

    Subfields begin with 0x1f
    Fields end with 0x1e
    Records end with 0x1d

=head2 Array element structure

The conversion process makes use of a simple array structure,
where each array element contains the tag and data for a single MARC
field, separated by a single space.

	cols. 0-2 : tag number
	col.  3   : blank
	cols. 4-5 : indicators
	cols. 6-  : tag data

e.g.

	245 10|aSome title|h[GMD]

The '|' character is used to represent MARC subfield separators (0x1f).

=head1 REFERENCES

MARC Standards, http://www.loc.gov/marc/

Dublin Core/MARC/GILS Crosswalk, http://www.loc.gov/marc/dccross.html

=head1 VERSION

Version 2015-01-31

=head1 AUTHOR

Steve Thomas <stephen.thomas@adelaide.edu.au>

=head1 LICENCE

Copyright (c) 2004-2015 Steve Thomas <stephen.thomas@adelaide.edu.au>

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut

__END__
