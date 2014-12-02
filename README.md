iOS Command-line Deploy
=======================

This Bash script will compile your iOS app, and copy (SCP) it to a configured server.

Please note, this script suits a very subjective build/release process that might not suit your project / organisation.

Assumptions
-----------
The following assumptions are made. Other scenarios may well be supported, but they have not been tested.

* Project name is a single word, lower-case. E.g. `myproject`
* Workspace name, if using a workspace, rather than a single project, is similarly named
* The target is of the same name as the project/workspace (which is the default in xCode)
* You are using xCode v6.1.x

Requirements
------------
* OS X, with standard developer tools install (xCode, PERL)
* The *Term::Key* perl module. Install with `sudo cpan Term::Key`

Installation
------------
1. Make sure the `deploy.pl` script is copied to the root level of your project/workspace. I.e. the folder that contains your `.xcproject` file (which is really a directory).
1. Edit the script and change the configuration parameters at the top of the file to suit your needs. See the *Configuration* notes below.
1. If using xCode 6.1 see the *ResourceRules.plist* common problem section below, and add the build parameter.
1. Set up Keychain access for your signing key (so this command line script can access the signing key).
	* Open the `Keychain Access` app (use Sherlock to search for it)
	* Under the *login* keychain (top-left), search for the signing private key. It can be quite tricky to find. Also, note you can not use the search box, you have to navigate to the key. Searching for it, and selecting it won't allow you to change it (a *Keychain Access* bug). The signing key will be named like "iOS Distribution: My Company Inc." and it will have a *kind* of `private key` not `public key`)
	* Double-click the matching private key to reveal its properties.
	* Click the *Access Control* tab, select the option `Allow all applications access this item`, and save.

Configuration
-------------
Use the following configuration parameters (at the top of the script) to suit your project:

* **projectSlug** The xCode project name (try and keep it lower-case and without spacing/punctuation). I.e. if this is a value of `mypoject`, then the folder `myproject.xcodeprj` should exist in the same folder as this build script. The generated `.ipa` file will be called after this slug as well.
* **isWorkspace** If set to 1, the entire workspace will be built (not just an individual project). The workspace needs to be called the same as *projectSlug* above.
* **identity** The name of the signing identity. This is the official name on the iTunes Connect / developer account. You'll see it under xCode's Preferences > Accounts. For individual accounts, it's normally just the developer's name (e.g. "Joe Soap"). For company accounts, it's normally the full legal name "My Company Inc."
* **config** The build configuration to use. Normally, this will be `Release` (the xCode default)
* **scpDestWithChangelog** If this is set, the final application (and optional changelog) will be copied here (using `scp`). The string should be of the form `user@host:/path/to/distrib`. E.g. `myuser@/var/www/mysite/iosapp/`. If you don't want to copy the changelog, use *scpDestWithoutChangelog*; both are optional.
* **scpDestWithoutChangelog** If this is set, the final application will be copied here (using `scp`). The string should be of the form `user@host:/path/to/distrib`. E.g. `myuser@/var/www/mysite/iosapp/`.
* **bundleID** The Bundle Identifier name for this app (you can get that from iTunes Connect, or from xCode under your targets > General tab)
* **displayName** The user-friendly name to call the app (used in the Ad-hoc download confirmation prompt)
* **sslURLBase** The URL to use (SSL is now a requirement for Ad-hoc distribution) where the user will be directed to when downloading. The generated app name will be appended to this URL, so make sure it has a trailing slash!

Common Problems
---------------
ResourceRules.plist: cannot read resources
__________________________________________
This happens in xCode 6.1 (looks like a bug) and affects all command-line building (such as servers / continuous integration). To resolve, in xCode, navigate to your project > *Targets*. Select your target and go to the *Build Settings* tab. Search for *Code Signing Resource Rules Path* and add the following value (for all, or just for *Release* configuration):

	$(SDKROOT)/ResourceRules.plist

User interaction is not allowed
_______________________________
You need to follow the Keychain Access step in the installation steps above.
