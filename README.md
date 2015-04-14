# StoryboardCaptureHelper
XCode6 plugin helps making image capture of whole Storyboard

I made this experimental tool to help making documents for my other projects.
Develop & test on XCode 6.2.

I got XCode 6 plugin template at:
https://github.com/kattrali/Xcode-Plugin-Template

### Installation

Clone this project. Build then restart XCode.

### Usage

Zoom Storyboard as you want. Also scroll around the Storyboard to make sure that XCode loads all view controllers interface.
Right click in Storyboard editor, on context menu you will find the submenu with items:

* **Storyboard capture:** Capture whole storyboard to image.
* **Export all frames:** make capture of each view controller of storyboard. It has options:
   - HTML: Make an HTML page which fakes the storyboard.
   - Multi color segue classes: in HTML page, each storyboard segue class has own color (segues same class have same color).
   - JSON: Save information about view controllers frame, segues into JSON file.
   - PLIST: Save information about view controllers frame, segues into PLIST file.
