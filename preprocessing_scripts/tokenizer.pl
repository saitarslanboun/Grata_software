#!/usr/bin/perl -w

# $Id: tokenizer.perl 915 2009-08-10 08:15:49Z philipp $
# Sample Tokenizer
# written by Josh Schroeder, based on code by Philipp Koehn

binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");

use FindBin qw($Bin);
use strict;
use utf8;
#use Time::HiRes;

my $mydir = "$Bin/nonbreaking_prefixes";

#global variables, flags and paths
my %NONBREAKING_PREFIX = ();
my $language = "en";
my $QUIET = 0;
my $HELP = 0;
my $AGGRESSIVE = 0;
my $SKIP_XML = 0;
my $MASK_FILE_PATH = "masked-classified-regexp.dat";
my $FORCE_FILE_PATH = "forced-translations.dat";
my $MASK_FACTORS = 0;
our $QUEST_MODE = 0;
our $LOWER_CASING = 0;
#our $DEBUG = 0;

#print STDERR "ARGS: @ARGV;\n";

while (@ARGV) {
	$_ = shift;
	#print STDERR "processing `$_'\n";
	/^-b$/ && ($| = 1, next);
	/^-l$/ && ($language = shift, next);
	/^-q$/ && ($QUIET = 1, next);
	/^-h$/ && ($HELP = 1, next);
	/^-x$/ && ($SKIP_XML = 1, next);
	/^-a$/ && ($AGGRESSIVE = 1, next);
	/^-m$/ && ($MASK_FILE_PATH = shift, next);
	/^-f$/ && ($FORCE_FILE_PATH = shift, next);
	/^-t$/ && ($QUEST_MODE = 1, next);
	/^-f$/ && ($MASK_FACTORS = 1, next);
	/^-c$/ && ($LOWER_CASING = 1, next);
	#/^-d$/ && ($DEBUG = 1, next);
}

#print STDERR "Quest mode: `$QUEST_MODE', aggressive: `$AGGRESSIVE'\n";

#if asked to, display help message and exit
if ($HELP) {
	print "Usage ./tokenizer.perl (-l [en|de|...]) < textfile > tokenizedfile\n";
        print "Options:\n";
        print "  -q  ... quiet.\n";
        print "  -a  ... aggressive hyphen splitting.\n";
        print "  -b  ... disable Perl buffering.\n";
        print "  -m path ... set the path of the masking regular expression file.\n";
        print "  -f path ... set the path of the forced translation file.\n";
	exit;
}
if (!$QUIET) {
	print STDERR "Tokenizer Version 1.0\n";
	print STDERR "Language: $language\n";
}

#load the mask regular expressions
our ($maskHash, $maskKeyList) = loadMasks($MASK_FILE_PATH);
our $maskRe = join("|", @$maskKeyList);

#load the forced translation entries
our ($forceHash, $forceKeyList) = loadMasks($FORCE_FILE_PATH, 1);

#load list of prefixes for the specified language
load_prefixes($language,\%NONBREAKING_PREFIX);

if (!$QUIET and scalar(%NONBREAKING_PREFIX) eq 0){
	print STDERR "Warning: No known abbreviations for language '$language'\n";
}

my $symb = "[A-Za-z0-9_]";

my $alnumNandRe = getNandLookRe($symb, $symb);
my $numStartNandRe = getNandLookRe($symb . '\.', $symb);
my $numEndNandRe = getNandLookRe($symb, '\.' . $symb);

#process input line by line
while(<STDIN>) {
	if (($SKIP_XML && /^<.+>$/) || /^\s*$/) {
		#don't try to tokenize XML/HTML tag lines
		print $_;
	}
	else {
		s/[\n\r]//g;
		
		#replace the utf8 quots:
		s/[«»„„“”]/"/g;
		s/[‚’‘]/'/g;
		
		my @tokens = ();
		
		my $fullstr = $_;
		
		#separate every maskable entry and tokenize everything else iteratively
		#while ($maskRe and $fullstr =~ /^(.*?)(?<![^ ([{"'])($maskRe)(?=[[:punct:]]*(?:\s|$))(.*)$/) {
		#while ($maskRe and $fullstr =~ /^(.*?)$wordBoundary($maskRe)$wordBoundary(.*)$/) {
		while ($maskRe and $fullstr =~ /^(.*?)(?:$alnumNandRe)(?:$numStartNandRe)($maskRe)(?:$alnumNandRe)(?:$numEndNandRe)(.*)$/) {
			my ($prefix, $rawExpression, $postfix) = ($1, $2, $3);
			
			#print "DEBUG $prefix / $rawExpression / $postfix;\n";
			
			my $type = "generic_something";
			
			for my $singleMaskRe (@$maskKeyList) {
				if ($rawExpression =~ /^$singleMaskRe$/) {
					$type = $maskHash->{$singleMaskRe}->[0];
					last;
				}
			}
			
			#remove dash after something masked
			if ($postfix =~ /^-(.*)$/) {
				$postfix = $1;
			}
			
			my $expression = escapeXml($rawExpression);
			
			#add tokenized and split prefix to the output list
			push @tokens, tokenizeLcSplit($prefix);
			
			#add the masked recognized expression to the output list
			#my $maskTagContent = ($QUEST_MODE? "": " type=\"$type\" translation=\"$expression\"");
			#push @tokens,  "<mask$maskTagContent>$expression</mask>";
			push @tokens, "__" . $type . "__";
			
			#print "DEBUG $prefix /// $rawExpression /// $postfix /// $type;\n";
			
			#continue with the postfix
			$fullstr = $postfix;
		}
		
		#print "DEBUG $fullstr;\n";
		
		#finish by tokenizing the (remaining) string
		push @tokens, tokenizeLcSplit($fullstr);
		
		#filter out empty tokens
		my @fltTokens = grep(!/^\s*$/, @tokens);
		
		#add forced translation tags
		unless ($QUEST_MODE) {
			for my $tok (@fltTokens) {
				if ($forceHash->{$tok}) {
					#the token has been escaped, so we only need to escape its forced translation
					my ($translation,$prob) = @{$forceHash->{$tok}};
					#default probability if none given: is divided equally among translation model features, 
					#so a value of 4 should make sure that it is always picked (dunno about phrase penalty though).
					if (!$prob) {
						$prob = 4;
						}
					$tok = "<force translation=\"" . escapeXml($translation) . "\" prob=\"" . $prob. "\">" . $tok . "</force>";
				}
			}
		}
		
		#print the output
		print join(" ", @fltTokens) . "\n";
	}
}

#####
# tokenize, lower-case the input string and return it as list of tokens
#####
sub tokenizeLcSplit {
	my($text) = @_;

	#chomp($text);
	$text = " $text ";
	
	# remove ASCII junk
	$text =~ s/\s+/ /g;
	$text =~ s/[\000-\037]//g;

	# seperate out all "other" special characters
	$text =~ s/([^\p{IsAlnum}\s\.\'\`\,\-])/ $1 /g;
	
	# aggressive hyphen splitting
	if ($AGGRESSIVE) {
		$text =~ s/([\p{IsAlnum}])\-([\p{IsAlnum}])/$1 \@-\@ $2/g;
	}

	#multi-dots stay together
	$text =~ s/\.([\.]+)/ DOTMULTI$1/g;
	while($text =~ /DOTMULTI\./) {
		$text =~ s/DOTMULTI\.([^\.])/DOTDOTMULTI $1/g;
		$text =~ s/DOTMULTI\./DOTDOTMULTI/g;
	}

	# seperate out "," except if within numbers (5,300)
	$text =~ s/([^\p{IsN}])[,]([^\p{IsN}])/$1 , $2/g;
	# separate , pre and post number
	$text =~ s/([\p{IsN}])[,]([^\p{IsN}])/$1 , $2/g;
	$text =~ s/([^\p{IsN}])[,]([\p{IsN}])/$1 , $2/g;
	      
	# turn `into '
	$text =~ s/\`/\'/g;
	
	#turn '' into "
	$text =~ s/\'\'/ \" /g;

	if ($language eq "en") {
		#split contractions right
		$text =~ s/([^\p{IsAlpha}])[']([^\p{IsAlpha}])/$1 ' $2/g;
		$text =~ s/([^\p{IsAlpha}\p{IsN}])[']([\p{IsAlpha}])/$1 ' $2/g;
		$text =~ s/([\p{IsAlpha}])[']([^\p{IsAlpha}])/$1 ' $2/g;
		$text =~ s/([\p{IsAlpha}])[']([\p{IsAlpha}])/$1 '$2/g;
		#special case for "1990's"
		$text =~ s/([\p{IsN}])[']([s])/$1 '$2/g;
	} elsif (($language eq "fr") or ($language eq "it")) {
		#split contractions left	
		$text =~ s/([^\p{IsAlpha}])[']([^\p{IsAlpha}])/$1 ' $2/g;
		$text =~ s/([^\p{IsAlpha}])[']([\p{IsAlpha}])/$1 ' $2/g;
		$text =~ s/([\p{IsAlpha}])[']([^\p{IsAlpha}])/$1 ' $2/g;
		$text =~ s/([\p{IsAlpha}])[']([\p{IsAlpha}])/$1' $2/g;
	} else {
		$text =~ s/\'/ \' /g;
	}
	
	#word token method
	my @words = split(/\s/,$text);
	$text = "";
	for (my $i=0;$i<(scalar(@words));$i++) {
		my $word = $words[$i];
		if ( $word =~ /^(\S+)\.$/) {
			my $pre = $1;
			if (($pre =~ /\./ && $pre =~ /\p{IsAlpha}/) || ($NONBREAKING_PREFIX{$pre} && $NONBREAKING_PREFIX{$pre}==1) || ($i<scalar(@words)-1 && ($words[$i+1] =~ /^[\p{IsLower}]/))) {
				#no change
			} elsif (($NONBREAKING_PREFIX{$pre} && $NONBREAKING_PREFIX{$pre}==2) && ($i<scalar(@words)-1 && ($words[$i+1] =~ /^[0-9]+/))) {
				#no change
			} else {
				$word = $pre." .";
			}
		}
		$text .= $word." ";
	}		

	# clean up extraneous spaces
	$text =~ s/ +/ /g;
	$text =~ s/^ //g;
	$text =~ s/ $//g;

	#restore multi-dots
	while($text =~ /DOTDOTMULTI/) {
		$text =~ s/DOTDOTMULTI/DOTMULTI./g;
	}
	$text =~ s/DOTMULTI/./g;
	
	$text = escapeXml($text);

	#return $text;
	if (!$QUEST_MODE and $LOWER_CASING) {
		$text = lc($text);
	}
	
	return split(/ /, $text);
}

#####
# replace XML-unsafe characters with pseudo-entities
#####
sub escapeXml {
	my ($txt) = @_;
	
	#escape special chars
	$txt =~ s/\&/\&amp;/g;    # escape escape
	$txt =~ s/\|/\&bar;/g;    # factor separator
	$txt =~ s/\</\&lt;/g;     # xml
	$txt =~ s/\>/\&gt;/g;     # xml
	$txt =~ s/\'/\&apos;/g;  # xml
	$txt =~ s/\"/\&quot;/g;  # xml
	$txt =~ s/\[/\&#91;/g;   # syntax non-terminal
	$txt =~ s/\]/\&#93;/g;   # syntax non-terminal
	
	return $txt;
}

#####
# load the prefix list for a given language
#####
sub load_prefixes {
	my ($language, $PREFIX_REF) = @_;
	
	my $prefixfile = "$mydir/nonbreaking_prefix.$language";
	
	#default back to English if we don't have a language-specific prefix file
	if (!(-e $prefixfile)) {
		$prefixfile = "$mydir/nonbreaking_prefix.en";
		print STDERR "WARNING: No known abbreviations for language '$language', attempting fall-back to English version...\n";
		die ("ERROR: No abbreviations files found in $mydir\n") unless (-e $prefixfile);
	}
	
	if (-e "$prefixfile") {
		open(PREFIX, "<:utf8", "$prefixfile");
		while (<PREFIX>) {
			my $item = $_;
			chomp($item);
			if (($item) && (substr($item,0,1) ne "#")) {
				if ($item =~ /(.*)[\s]+(\#NUMERIC_ONLY\#)/) {
					$PREFIX_REF->{$1} = 2;
				} else {
					$PREFIX_REF->{$item} = 1;
				}
			}
		}
		close(PREFIX);
	}
	
}

#####
# load mask or forced translation lists
#####
sub loadMasks {
	my ($filename, $lcase) = @_;
	
	my $hash = {};
	my $orderedKeyList = [];

	#my $symb = "[A-Za-z0-9_-]";
	#my $numBound = "[A-Za-z0-9_.]";
	#my $flexStringBoundary = "(?:(?<!$symb)(?=$symb)|(?<=$symb)(?!$symb)|(?<!$symb)(?!$symb))";
	#my $flexWordStart = "(?<!$symb)";
	#my $flexWordEnd = "(?!$symb)";
	#my $flexNumStart = "(?<!$numBound)";
	#my $flexNumEnd = "(?!$numBound)";
	
	open(FH, "<:utf8", $filename) or die("Failed to open `$filename' for reading");
	
	while (<FH>) {
		my $item = $_;
		chomp($item);
		if (($item) && (substr($item,0,1) ne "#")) {
			my ($from, $to, $prob) = split(/\t/,$item);
			
			#$from =~ s/__FSB__/$flexStringBoundary/g;
			#$from =~ s/__FWS__/$flexWordStart/g;
			#$from =~ s/__FWE__/$flexWordEnd/g;
			#$from =~ s/__FNS__/$flexNumStart/g;
			#$from =~ s/__FNE__/$flexNumEnd/g;
			
			if ($lcase) {
				$from = lc($from);
			}
			push @$orderedKeyList, $from;
			my @val = ($to,$prob);
			$hash->{$from} = \@val;
		}
	};
	
	close(FH);
	
	return $hash, $orderedKeyList;
}

#####
#
#####
sub getNandLookRe {
	my ($re1, $re2) = @_;
	return "(?<!$re1)(?=$re2)|(?<=$re1)(?!$re2)|(?<!$re1)(?!$re2)";
}
