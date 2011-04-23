IosBox
======

IosBox is collection of Rake Tasks that makes developing iOS apps more easy.
It includes rake tasks that take care of updating app Info.plist with proper
version information (e.g. build date, GIT hash, etc).
Further version will integrate deployment options, such as deploy beta versions
to TestFlight.

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

Usage
=====

Run `rake -T` in project folder to see available commands.

Copyright
=========

Copyright (c) 2011 Mikko Kokkonen. See LICENSE.txt for
further details.

