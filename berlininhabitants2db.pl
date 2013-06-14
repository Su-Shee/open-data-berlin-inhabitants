#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use open qw(:utf8);

use DBI;
use DBD::Pg;
use Text::CSV;

my $database = 'berlindata';
my $hostname = 'YOURHOSTNAME';
my $username = 'YOURUSER';
my $password = 'YOURPASSWORD';

my $file = 'berlininhabitants-2011.csv';
open my $fh, "<", $file or die "$file: $!";

my $csv     = Text::CSV->new( { binary => 1, sep_char => ';' } );
my $csvrows = $csv->getline_all($fh, 1);

my $dsn = "DBI:Pg:dbname=$database; host=$hostname;";
my $dbh = DBI->connect($dsn, $username, $password, { AutoCommit => 1 });

my $sth = $dbh->prepare(
  "INSERT INTO inhabitants
  (official_district, district, gender, nationality, age_low, age_high, count) 
  VALUES (?, ?, ?, ?, ?, ?, ?);"
);

for my $row (@{ $csvrows }) {

  $row->[4] =~ s/ und älter/_125/g;  

  my ($age_low)  = ($row->[4] =~ m/\A(\d\d)/); 
  my ($age_high) = ($row->[4] =~ m/(\d\d\d?)\Z/);

  sleep 1;
  $sth->execute( @{ $row }[0 .. 3], $age_low, $age_high, $row->[5] );
}

$dbh->disconnect;



