== What is this? ==
I plan on rewriting the frontend of MAL Updater OS X in the future to work on later OS X systems while adding some new features. Apparently, someone is continuing development of the Unofficial MAL API, but it's not currently up yet. Since the code is old, I plan on throwing it out, but put the main functionality in this framework for retrieving lists, updating and detecting playing files.

I plan on separating the main functions to a framework and possibly rewrite the front end application in Swift to function more like the Last.fm scribbler showing information about the anime one is currently watching. This means that the new rewritten version will only work under Mavericks and Yosemite. The new version will be 3.0.

Crunchyroll support might be added, but I have to figure out how that would work (probably through a browser extension)

This will not build as I have to find a replacement for ASIRequest and fix the JSON framework functionality as it changed within the past 2 years. 

Documentation will come soon, once I have the time to rework some stuff, probably in January of next year.

== To Build ==
The framework won’t build yet, but to build it, type `xcodebuild`.

10.9 SDK is required, but all required frameworks are included.