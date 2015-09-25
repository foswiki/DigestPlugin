# Plugin for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# Copyright (C) 2008-2015 MichaelDaum http://michaeldaumconsulting.com
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details, published at
# http://www.gnu.org/copyleft/gpl.html

package Foswiki::Plugins::DigestPlugin;

use strict;
use warnings;

use Foswiki::Func ();
use Digest ();

our $VERSION = '1.01';
our $RELEASE = '23 Apr 2015';
our $SHORTDESCRIPTION = 'Calculate a message digest, i.e. MD5';
our $NO_PREFS_IN_TOPIC = 1;

use constant TRACE => 0; # toggle me

###############################################################################
sub writeDebug {
  return unless TRACE;
  print STDERR "- DigestPlugin - " . $_[0] . "\n";
  #Foswiki::Func::writeDebug("- DigestPlugin - $_[0]");
}


###############################################################################
sub initPlugin {

  Foswiki::Func::registerTagHandler('DIGEST', \&handleDIGEST);

  return 1;
}

###############################################################################
sub handleDIGEST {
  my ($session, $params, $topic, $web) = @_;

  my $data = $params->{_DEFAULT} || '';
  my $type = $params->{type} || 'MD5';
  my $output = $params->{output} || 'hex';

  my $digest;
  my $factory = Digest->new($type);

  $data = Foswiki::Func::expandCommonVariables($data, $topic, $web)
    if expandVariables(\$data, $web, $topic);

  $factory->add($data);

  if ($output eq 'hex') {
    $digest = $factory->hexdigest;
  } elsif ($output eq 'b64') {
    $digest = $factory->b64digest;
  } elsif ($output eq 'binary') {
    $digest = $factory->digest;
  } else {
    $digest = $factory->hexdigest;
  }

  #writeDebug("digest of '$data' is '$digest'");

  return $digest;
}

###############################################################################
sub expandVariables {
  my ($text, $web, $topic, %params) = @_;

  my $found = 0;
  
  foreach my $key (keys %params) {
    if($$text =~ s/\$$key\b/$params{$key}/g) {
      $found = 1;
      #writeDebug("expanding $key->$params{$key}");
    }
  }
  $found = 1 if $$text =~ s/\$perce?nt/\%/go;
  $found = 1 if $$text =~ s/\$nop//g;
  $found = 1 if $$text =~ s/\$n/\n/go;
  $found = 1 if $$text =~ s/\$t\b/\t/go;
  $found = 1 if $$text =~ s/\$dollar/\$/go;

  return $found;
}

1;
