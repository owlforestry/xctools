IosBox
======

IosBox is collection of Rake Tasks that makes developing iOS apps more easy.
It includes rake tasks that take care of updating app Info.plist with proper
version information (e.g. build date, GIT hash, etc).
Further version will integrate deployment options, such as deploy beta versions
to TestFlight.

Current Features
================

Currently IosBox supports following features:

* <b>Build Prepare</b> (`iosbox:build:prepare`)
  Build prepare task generates new build number and bundle version and stores
  it to application Info.plist.
  It also saves some needed path information to .buildCache for other tasks

* <b>Version Mungle</b> (`iosbox:version:*`)
  IosBox offers simple tasks to bump version numbers. Either it is patch, minor or
  major version bump, IosBox automatically handles increasing current version number.

Installation
============

Install `IosBox` gem if you haven't done yet so
	$ gem install ios-box

Create in the root of your project folder `Rakefile` -file with following contents:
	
	require 'ios-box'

	IosBox::Tasks.new do |config|
	  config.target = "iosboxdev"
	end

Integrate toolbox with your XCode project by executing following command:
	
	$ rake iosbox:integrate

Notice! This command will modify your XCode project file and therefore can make your project to stop working.
Make sure you have proper backups done.

If you want to integrate IosBox manually, add following script as build phase, preferably as first phase.

	(cd $PROJECT_DIR; rake iosbox:build:prepare)

Usage
=====

Run `rake -T` in project folder to see available commands.

Copyright
=========

Copyright (c) 2011 Mikko Kokkonen. See LICENSE.txt for
further details.

