OS X Control Patch for Spotify
==============================

Overview
--------
This patch changes the default behavior of the Play/Pause, Back and Next keys in
OS X to control Spotify rather than iTunes.  It also adds support for inline-mic
control buttons to manage Spotify playback.  Presumably this also works with IR
remote controls, although I no longer have one of those for my laptop.

Apple's _Remote Control Daemon_ (`rcd`) is responsible for trapping and
dispatching these events.  This patch stops `rcd`, creates a backup, modifies its
binary, and then relaunches the daemon.

Behavior changes are as follows:
* When no apps are open, pressing Play/Pause launches Spotify.
  * Same behavior for single-click of inline-mic button on supported headphones
* When Spotify is open, pressing Play/Pause toggles music playback.
* Same behavior for single-click of inline-mic button
* When Spotify is open, pressing Next Track on the keyboard skips to the next
  track in Spotify.
  * Same behavior for double-tap of inline-mic button
* When Spotify is open, pressing Previous Track on the keyboard rewinds to the
  beginning track in Spotify.
  * Same behavior for triple-tap of inline-mic button
* If another application that uses the media keys is open, the keys continue to
  control that open application rather than Spotify.  (For example, this patch
  does not hijack the play/pause button when VLC is open and is the front app,
  or the most-recently-used application.)

Side effects:
* Keyboard buttons no longer work for controlling iTunes, even when Spotify is
  closed.
* Keyboard buttons no longer work for controlling QuickTime Player, even when
  Spotify is closed.

Thanks to Farhan Ahmad, who inspired this patch and provided a starting point.


Disclaimer
----------

This patch modifies a core part of your operating system.  Use at your own risk.
This program comes with ABSOLUTELY NO WARRANTY; please see the included license
file for details.

Currently known to work under:

* OS X Yosemite (10.10.1)


General Information
-------------------

Author: Elliott Wood (<https://github.com/ewoodh2o>)

Original: Farhan Ahmad (<http://www.thebitguru.com/projects/iTunesPatch>)


Change Log
----------
    2015-01-06, ew: Elliott Wood
     * Altered patch for Spotify
     * Version changed to 0.8.3.1

    2014-01-19, fa: Farhan Ahmad
     * Added the '-KILL' to killall command because rcd doesn't seem to respect SIGTERM
       anymore.  Thanks for @quicksnap (https://github.com/quicksnap) for helping
       troubleshoot.
     * Version changed to 0.8.3

    2013-05-11, fa: Farhan Ahmad
     * Added step to self-sign the modified binary. This should
       prevent rcd from crashing on Mountain Lion.  Thanks to user48986 at
       http://apple.stackexchange.com/questions/64408/can-you-disable-a-code-signature-check
     * Version changed to 0.8.2

    2011-09-03	Farhan Ahmad
     * Added Michael Winestock's info.
	     http://www.linkedin.com/pub/michael-winestock/18/579/972

    2011-08-18	Farhan Ahmad
     * Added a fix to account for spaces in the directory where the patch is
       uncompressed. Patch submitted by Michael Winestock.
     * Version changed to 0.8.

    2010-11-28	Farhan Ahmad
     * Wrote a new python based patching script that dynamically patches the files
    	 instead of using bspatch and relying on a pre-supplied patch file. This
    	 should make the patch work with pretty much all versions of rcd.

    2010-11-23	Farhan Ahmad
     * Packaged and released the first version.


