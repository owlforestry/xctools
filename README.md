IosBox
======

IosBox is tool that integrates with XCode to automate some of the tasks.

Current Features
----------------

Currently IosBox supports following features:

* <b>Build Prepare</b> (`build prepare`)
  Build prepare task generates new build and bundle version  and stores
  it to application Info.plist.
  It also prepares buildcache for further tasks.

* <b>Version Management</b> (`version`)
  IosBox offers simple 
  IosBox offers simple tasks to bump version numbers. Either it is patch, minor or
  major version bump, IosBox automatically handles increasing current version number.

### Planned Features

In the roadmap are following features (but not yet planned)

* Library adding, such as analytics, Hoptoad, adwhirl, etc.
* Asset management, slicing assets according to receipt etc.
* More to come, open for suggestions...

# Installation

Install `IosBox` gem if you haven't done yet so

	$ gem install ios-box

Integrate toolbox with your XCode project by executing following command:
	
	$ ios-box integrate

Notice! This command will modify your XCode project file and therefore can make your project to stop working.
Make sure you have proper backups done.

# Usage

Run `ios-box help` in project folder to see available commands.

# Commands

## ios-box integrate

Integrates ios-box to current project. During integration process you can
choose which targets build preparation task is ran.

## ios-box build prepare

This task prepares build process and can be only ran during XCode build phase.

## ios-box version show

Displays current version information of the project.

## ios-box version build

Increments build number.

## ios-box version bump [major|minor]

Bumps marketing version by one step. By default it increases patch level
but if ptional argument is given, either major or minor version is increased.

# Copyright

Copyright &copy; 2011 Mikko Kokkonen. See LICENSE.txt for
further details.

