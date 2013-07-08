Download following files:--
xsd2xml.pl
XMLValidator.py
Schema.xsd

Use command:-

perl xsd2xml.pl -schema Schema.xsd -csv SampleTest.csv
# CSV file is generated, fill the data in the file as shown in the existing.

perl xsd2xml.pl -csv SampleTest.csv -xml SampleTest.xml -schema Schema.xsd
# XML file based on the csv generated

Result :--> XML file SampleTest.xml is generated which is validated against Schema.xsd.
