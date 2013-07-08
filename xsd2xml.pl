#!/usr/bin/perl
###############################################################################################
# Author : Nipun Gupta                                                                        #
# Date   : 08-July-2013                                                                       #
# Description :                                                                               #
#   1. Given the XSD schema first create the XML header as a cvs file                         #
#   > perl xsd2csv.pl -schema Schema.xsd -csv SampleTest.csv                                  #
#   2. Once the csv is generated write the test cases manually in the same format.            #
#   3. Write the XML file based on the csv generated                                          #
#   > perl xsd2csv.pl -csv SampleTestlink.csv -xml SampleTest.xml -schema Schema.xsd          #
#                                                                                             # 
#   Result :--> XML file SampleTest.xml is generated which is validated against Schema.xsd.   #                      
###############################################################################################

use strict;

our $noOfSchema      = 0;
our $noOfAttributes  = 0;
our $noOfElements    = 0;
our $noOfComplexType = 0;
our $lineToProcess   = 0;
our $selfClose       = 0;
our $row             = 0;
our $addComma        = "";
our @csvHeader       = ();
our @xmlHeader       = ();
our @XMLClosers      = ();

sub xsd2csvHeader {
    my $line = shift;
    chop($line);

    #   print $line;

    # Find the schema
    if ( $line =~ /<xs:schema/ ) {
        if ( $line = !m/\/>/ ) {
            $selfClose = 1;
        }
        else {
            $selfClose = 0;
        }
        if ( $selfClose == 1 ) {
            $noOfSchema += 1;
        }
    }
    elsif ( $line =~ m/<\/xs:schema/ ) {
        $noOfSchema -= 1;
    }

    # Find the element
    if ( $line =~ /<xs:element/ ) {

        if ( $line =~ m/name="(.*?)"/ ) {

            # print $row . " $1 \n";
            $csvHeader[$row] .= $1 . ",";
        }

        if ( $line = !m/\/>/ ) {
            $selfClose = 1;
        }
        else {
            $selfClose = 0;
        }
        if ( $selfClose == 1 ) {
            $noOfElements += 1;
        }
    }
    elsif ( $line =~ m/<\/xs:element/ ) {
        $noOfElements -= 1;
    }

    # Find the complexType
    if ( $line =~ /<xs:complexType/ ) {
        $csvHeader[$row] =~ s/\,+$//g;
        $csvHeader[$row] .= ":CT,";    #print ":CT\n";
        $csvHeader[$row] = "," . $csvHeader[$row]
          if ( $csvHeader[$row] =~ m/^\w*\:CT,/ && $row > 0 );

        #        print "\n &&&&& " . $csvHeader[$row];
        $row++;
        if ( $line = !m/\/>/ ) {
            $selfClose = 1;
        }
        else {
            $selfClose = 0;
        }
        if ( $selfClose == 1 ) {
            $noOfComplexType += 1;
        }
    }
    elsif ( $line =~ m/<\/xs:complexType/ ) {
        $noOfComplexType -= 1;
    }

    # Find the attribute
    if ( $line =~ /<xs:attribute/ ) {

        if ( $line =~ m/name="(.*?)"/ ) {

            # print $1 . ":A";
            $csvHeader[$noOfComplexType] =
              $1 . ":A," . $csvHeader[$noOfComplexType];
        }

        if ( $line = !m/\/>/ ) {
            $selfClose = 1;
        }
        else {
            $selfClose = 0;
        }
        if ( $selfClose == 1 ) {
            $noOfAttributes += 1;
        }
    }
    elsif ( $line =~ m/<\/xs:attribute/ ) {
        $noOfAttributes -= 1;
    }

#    print "\n noOfSchema : noOfElements  : noOfComplexType : noOfAttributes";
#    print "\n S : E : C : A";
#    print "\n " . $noOfSchema . " : " . $noOfElements . " : " . $noOfComplexType . " : " . $noOfAttributes . "\n";
}

sub initialXMLHeader {
    my @tokens = split( /,/, shift );
    my $i = 0;
    foreach (@tokens) {
        $xmlHeader[$i] .= $_ . ",";
        $i++;
    }
}

sub finalXMLHeader {
    my $num = 0;
    foreach (@xmlHeader) {
        $lineToProcess = $_;
        $lineToProcess =~ s/,+$//g;
        $xmlHeader[$num] = $lineToProcess;
        $num++;
    }
}

sub closePreviousXMLToken {
    my $checkToken = shift;

    #    print "\n!! $checkToken !!!!\n";

    if ( $checkToken ~~ @XMLClosers ) {
        my $closeToken = pop(@XMLClosers);
        $closeToken =~ s/\:.*//g;
        print XMLFILE "\n </" . $closeToken . ">";

        #foreach(@XMLClosers){print "\n ^^^ $closeToken ^^^ " . $_;}
        closePreviousXMLToken($checkToken);
    }
}

sub writeXML {
    my @tokens    = split( /,/, shift );
    my @XMLTokens = ();
    my $i         = 0;
    my $line;
    my $XMLToken;
    my $tokenType = 0;

    foreach (@tokens) {
        $line = $_;
        if (   $line ne ""
            || $xmlHeader[ $i + $#xmlHeader - $#tokens ] =~ m/\:CT/ )
        {
            @XMLTokens =
              split( /,/, $xmlHeader[ $i + $#xmlHeader - $#tokens ] );
            foreach (@XMLTokens) {
                $XMLToken = $_;
                if ( $XMLToken =~ m/(.*):A/ ) {
                    print  XMLFILE " " . $1 . "=\"" . $line . "\"";
                    $tokenType = 1;
                }
                else {
                    if ( $XMLToken =~ m/(.*):CT/ ) {
                        closePreviousXMLToken($XMLToken);
                        push( @XMLClosers, ($XMLToken) );
                        print  XMLFILE "\n <" . $1 . ">";
                        $tokenType = 2;
                    }
                    else {
                        print XMLFILE "\n <"
                          . $XMLToken . ">"
                          . $line . "</"
                          . $XMLToken . ">";
                        $tokenType = 3;
                    }
                }
            }

#             print "\n" . ($#xmlHeader - $#tokens) . "  :::  <" . $xmlHeader[$i + $#xmlHeader - $#tokens] . ">" . $line . "</" . $xmlHeader[$i + $#xmlHeader - $#tokens] . ">";
#            print "</" . pop(@XMLClosers) . ">" if($XMLToken !~ "\:");
            $i++;
        }
    }
}

if($ARGV[0] eq "-schema"){
open( FILE, $ARGV[1] );
while (<FILE>) {
    $lineToProcess = $_;
    xsd2csvHeader($lineToProcess);
}
close(FILE);

#print "\n\n=======================\n";
if($ARGV[2] eq "-csv"){
open(FILE,">" . $ARGV[3]);
foreach (@csvHeader) {
    $lineToProcess = $_;
    my ($number) = ( $lineToProcess =~ tr/,// );
    for ( ; $number > 1 ; $number-- ) {
        $addComma .= ",";
    }
    print $lineToProcess . "\n" . $addComma;
    print FILE $lineToProcess . "\n" . $addComma;
}
$addComma =~ s/,/\*,/g;
print FILE "\n" . $addComma . "*";
close(FILE);
}
}

# Part two start here.
if($ARGV[0] eq "-csv"){
open( FILE, $ARGV[1] );
while (<FILE>) {
    $lineToProcess = $_;
    chop($lineToProcess);
    if ( $lineToProcess =~ m/^\*/ ) { last; }

    #  print $lineToProcess;
    initialXMLHeader($lineToProcess);
}
close(FILE);

finalXMLHeader();

my $num = 0;
foreach (@xmlHeader) {
    print "\n $num : " . $_;
    $num++;
}

# Part three creating the XML file with the data here.
my $flag = 0;
if($ARGV[2] eq "-xml"){
open( FILE, $ARGV[1] );
open(XMLFILE,">" . $ARGV[3]);
while (<FILE>) {
    $lineToProcess = $_;
    chop($lineToProcess);
    if ( $flag == 1 ) {
        #   print "\n" . $lineToProcess;
        $lineToProcess =~ s/^,+//g;
        writeXML($lineToProcess);
    }

    #print "\n\n\n";
    if ( $lineToProcess =~ m/\*/ ) { $flag = 1; }
}
close(FILE);

while ( $#XMLClosers >= 0 ) {
    my $closeToken = pop(@XMLClosers);
    $closeToken =~ s/\:.*//g;
  #  print "\n </" . $closeToken . ">";
    print XMLFILE "\n </" . $closeToken . ">";
}
close(XMLFILE);

open(XMLFILE, $ARGV[3]);
open(XMLFILE1, ">myxml.xml");
print XMLFILE1 '<?xml version="1.0" encoding="UTF-8"?>';
print XMLFILE1 "\n<testcases>";
while(<XMLFILE>){
    $lineToProcess = $_;
    chomp($lineToProcess);
    if($lineToProcess =~ m/\"$/){
        $lineToProcess =~ s/>//g;
        $lineToProcess .= ">";
    }
    print XMLFILE1 $lineToProcess . "\n";
}
print XMLFILE1 "</testcases>";
close(XMLFILE);
unlink($ARGV[3]);
rename("myxml.xml",$ARGV[3])
}
system("python XMLValidator.py " . $ARGV[3] . " " . $ARGV[5] . "");
}

