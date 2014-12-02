#! /usr/bin/perl

use strict;
use Term::ReadKey;

# The MIT License (MIT)
#
# Copyright (c) 2014, Cathal Garvey, ALL RIGHTS RESERVED.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.


#### CONFIG START
# See README.md for help with these configuration options
my( $projectSlug ) = "myproject"; # e.g. 'myapp' for myapp.xcodeproj
my( $isWorkspace ) = 0; # 0 for a regular xCode project, 1 for a workspace
my( $identity ) = "My Company Name"; # e.g. "My Company Name" or "Joe Soap"
my( $config ) = "Release"; # the build configuration ("Release" is a good default)
my( $scpDestWithChangelog ) = ""; # Optional, e.g. myuser@somehost.company.com:/var/www/myapp/
my( $scpDestWithoutChangelog ) = "";
my( $bundleID ) = "com.company.appname";
my( $displayName ) = "My Nice App";
my( $sslURLBase ) = "https://secure.company.com/apps/"; # with trailing slash!
my( $changelogPath ) = ""; # e.g. changelog.txt
#### CONFIG END


#### Noe need to modify below this line
if( $#ARGV >= 0 ) {
	# 1) Check for valid config
	# Check for required config options
	if( $ARGV[0] eq "" ) { die "A version number must be specified in the command-line arguments.\n\n"; }
	if( $ARGV[0] =~ /[^0-9\.]/ ) { die "The version number is not valid (it should only contains numbers and '.'.\n\n"; }
	if( $projectSlug eq "" ) { die "projectSlug is a required configuration option.\n\n"; }
	if( $identity eq "" ) { die "identity is a required configuration option.\n\n"; }
	if( $config eq "" ) { die "config is a required configuration option.\n\n"; }
	if( $bundleID eq "" ) { die "bundleID is a required configuration option.\n\n"; }
	if( $displayName eq "" ) { die "displayName is a required configuration option.\n\n"; }
	if( $sslURLBase eq "" ) { die "sslURLBase is a required configuration option.\n\n"; }
	# Check for valid xCode path
	if( !-d( $projectSlug . ".xcodeproj" ) ) { die "Could not find the " . $projectSlug . ".xcodeproj, is this script in the right directory?\n\n"; }
	if( !-d( $projectSlug . ".xcworkspace" ) && $isWorkspace > 0 ) { die "Could not find the " . $projectSlug . ".xcworkspace, is this script in the right directory?\n\n"; }

	my( $pwd ) = `pwd`;
	$pwd =~ s/[\r\n]//g;

	# 2) Build and sign the app (unless directed not to)
	if( $ARGV[1] ne "nobuild" ) {
		#system( "security unlock-keychain -u ~/Library/Keychains/login.keychain" );
		system( "security unlock-keychain" );
		if( $? != 0 ) { die "Unlocking keychain failed (bad password?)\n\n"; }

		system( "xcodebuild clean" );
		if( $? != 0 ) { die "Running 'clean' failed (so you have bigger problems)\n\n"; }

		if( $isWorkspace ) {
			system( "xcodebuild -derivedDataPath build -workspace " . $projectSlug . ".xcworkspace -scheme " . $projectSlug . " -config " . $config );
		}
		else {
			system( "xcodebuild -derivedDataPath build -project " . $projectSlug . ".xcodeproj -target " . $projectSlug . " -config " . $config );
		}
		if( $? != 0 ) { die "Running 'build' failed (does the project/space build in xCode?)\n\n"; }

		system( "xcrun -sdk iphoneos PackageApplication -v build/Build/Products/Release-iphoneos/" . $projectSlug. ".app -o " . $pwd . "/" . $projectSlug . "_v" . $ARGV[0] . ".ipa --sign \"" . $identity . "\" --embed *.mobileprovision" );
		if( $? != 0 ) { die "Running 'clean' failed (so you have bigger problems)\n\n"; }
	}

	# 3) Generate a .plist file
	my( $s ) = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n<plist version=\"1.0\">\n" .
	"<dict>\n\t<key>items</key>\n\t<array>\n\t\t<dict>\n\t\t\t<key>assets</key>\n\t\t\t<array>\n\t\t\t\t<dict>\n\t\t\t\t\t<key>kind</key>\n\t\t\t\t\t<string>software-package</string>\n\t\t\t\t\t<key>url</key>\n" .
	"\t\t\t\t\t<string>" . $sslURLBase . $projectSlug . "_v" . $ARGV[0] . ".ipa</string>\n" .
	"\t\t\t\t</dict>\n\t\t\t</array>\n\t\t\t<key>metadata</key>\n\t\t\t<dict>\n" .
	"\t\t\t\t<key>bundle-identifier</key>\n\t\t\t\t<string>" . $bundleID . "</string>\n" .
	"\t\t\t\t<key>bundle-version</key>\n\t\t\t\t<string>" . $ARGV[0] . "</string>\n" .
	"\t\t\t\t<key>kind</key>\n\t\t\t\t<string>software</string>\n" .
	"\t\t\t\t<key>title</key>\n\t\t\t\t<string>" . $displayName . "</string>\n" .
	"\t\t\t</dict>\n\t\t</dict>\n\t</array>\n</dict>\n</plist>\n";
	open( F, "> " . $projectSlug . "_v" . $ARGV[0] . ".plist" ) or die( "Couldn't open .plist file for writing" );
	print F $s;
	close( F );

	print "\nProceed with deploy [y/N]?";
	ReadMode 'cbreak';
	my( $key ) = ReadKey(0);
	ReadMode 'normal';
	print "\n";
	if( lc( $key ) eq "y" ) {
		print "Deploying ...\n";
		if( $scpDestWithChangelog ne "" ) {
			print( "scp " . $projectSlug . "_v" . $ARGV[0] . ".ipa " . $projectSlug . "_v" . $ARGV[0] . ".plist " . $scpDestWithChangelog );
			system( "scp " . $projectSlug . "_v" . $ARGV[0] . ".ipa " . $projectSlug . "_v" . $ARGV[0] . ".plist " . $scpDestWithChangelog );
			if( -r( $changelogPath ) ) {
				print( "scp \"" . $changelogPath . "\" " . $scpDestWithChangelog . $projectSlug . "_changelog.txt" );
				system( "scp \"" . $changelogPath . "\" " . $scpDestWithChangelog . $projectSlug . "_changelog.txt" );
			}
		}

		if( $scpDestWithoutChangelog ne "" ) {
			print( "scp " . $projectSlug . "_v" . $ARGV[0] . ".ipa " . $projectSlug . "_v" . $ARGV[0] . ".plist " . $scpDestWithoutChangelog );
			system( "scp " . $projectSlug . "_v" . $ARGV[0] . ".ipa " . $projectSlug . "_v" . $ARGV[0] . ".plist " . $scpDestWithoutChangelog );
		}
	}
}
else {
	print "Call with a build number (e.g. '1.10') as the only argument\nto generate a signed IPA file.\n\nThis script relies on one (and only one) .mobileprovison file to be present\nin this directry (which gets used to bundle with app).\n\n";
}
