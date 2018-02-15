#!/usr/bin/perl
# Note: before first use of this script, you may need:
# $ sudo cpan XML::Simple

use strict;
use XML::Simple;
use Data::Dumper;

sub find_package_name($) {
  my $android_manifest_xml = shift;
  my $manifest = XMLin($android_manifest_xml);
  return $manifest->{'package'};
}

# Output CSV
print "app,cert,package\n";
for my $line (<>) {
  chomp $line;
  if ($line =~ m|^build/make/core/package_internal.mk:(\d+): warning: (.*)$|) {
    my $package_internal_warning = $2;
    $package_internal_warning =~ m|^No LOCAL_SDK_VERSION: (.*) cert: (.*) path: (.*)$|
      || die "Couldn't parse: $package_internal_warning";
    my ($app, $cert, $path) = ($1, $2, $3);
    my $package;
    #print "APP: $app CERT: $cert PATH: $path\n";
    my $manifest = "$path/AndroidManifest.xml";
    if (-f $manifest) {
      $package = find_package_name($manifest);
      print "$app,$cert,$package\n";
    } else {
      warn "No manifest for $app at $manifest\n";
    }
  }
}
