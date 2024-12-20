# Plugin for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# Copyright (C) 2008-2024 MichaelDaum http://michaeldaumconsulting.com
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

=begin TML

---+ package Foswiki::Plugins::DigestPlugin

base class to hook into the foswiki core

=cut

use strict;
use warnings;

use Foswiki::Func ();
use Digest ();
use MIME::Base64 ();
use Encode ();

our $VERSION = '2.11';
our $RELEASE = '%$RELEASE%';
our $SHORTDESCRIPTION = 'Calculate a message digest, i.e. MD5 or BASE64';
our $LICENSECODE = '%$LICENSECODE%';
our $NO_PREFS_IN_TOPIC = 1;

use constant TRACE => 0; # toggle me

=begin TML

---++ initPlugin($topic, $web, $user) -> $boolean

initialize the plugin, automatically called during the core initialization process

=cut

sub initPlugin {

  Foswiki::Func::registerTagHandler('DIGEST', \&handleDIGEST);
  Foswiki::Func::registerTagHandler('BASE64', \&handleBASE64);

  return 1;
}

=begin TML

---++ handleDIGEST($session, $params, $topic, $web) -> $result

handles the =%DIGEST= macro

=cut

sub handleDIGEST {
  my ($session, $params, $topic, $web) = @_;

  my $data = $params->{_DEFAULT} || '';
  my $type = $params->{type} || 'MD5';
  my $output = $params->{output} || 'hex';

  my $digest;
  my $factory = Digest->new($type);

  $data = Foswiki::Func::expandCommonVariables($data, $topic, $web)
    if _expandVariables(\$data, $web, $topic);

  $data = Encode::encode($Foswiki::cfg{Site}{CharSet}, $data);
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

  #_writeDebug("digest of '$data' is '$digest'");

  return $digest;
}

=begin TML

---++ handleBASE64($session, $params, $topic, $web) -> $result

handles the =%BASE64= macro

=cut

sub handleBASE64 {
  my ($session, $params, $topic, $web) = @_;

  my $data = $params->{_DEFAULT} || '';

  $data = Foswiki::Func::expandCommonVariables($data, $topic, $web)
    if _expandVariables(\$data, $web, $topic);

  $data = Encode::encode($Foswiki::cfg{Site}{CharSet}, $data);
  $data = MIME::Base64::encode($data);
  $data =~ s/\n//g;

  return $data;
}

### static helpers ####
sub _expandVariables {
  my ($text, $web, $topic, %params) = @_;

  my $found = 0;
  
  foreach my $key (keys %params) {
    if($$text =~ s/\$$key\b/$params{$key}/g) {
      $found = 1;
      #_writeDebug("expanding $key->$params{$key}");
    }
  }
  $found = 1 if $$text =~ s/\$perce?nt/\%/go;
  $found = 1 if $$text =~ s/\$nop//g;
  $found = 1 if $$text =~ s/\$n/\n/go;
  $found = 1 if $$text =~ s/\$t\b/\t/go;
  $found = 1 if $$text =~ s/\$dollar/\$/go;

  return $found;
}

sub _writeDebug {
  return unless TRACE;
  print STDERR "- DigestPlugin - " . $_[0] . "\n";
}

1;
