## xtext-sublime
Generate a sublime plugin for your xtext language
- validation
- code completion
- code formatting
- syntax highlighting(just the keywords)

## Usage
Need to set output directory address by changing configuration of mwe2 file.
Put the address after "sublimePath=

E.g "sublimePath=/Path to Sublime Text 2/Sublime Text 2/Packages/newfoldername"
![alt tag](https://cloud.githubusercontent.com/assets/6274392/11693478/1ec55622-9e73-11e5-9d3c-ece31da66c73.png)

Add the `SublimeFragment.xtend` file from this repo alongside your mwe2 generator file.

Run the mwe2 workflow.
You will have total 6 files in your directory that you set above. 

E.g /Path to Sublime Text 2/Sublime Text 2/Packages/newfoldername

6 Files are:

- newthomas.YAML-tmLanguage : This is sublime syntax file. The name is can be changed in SublimeFragment.xtend file. Open this file with sublime and build. Build is in "Tools" tab.
- xtext_autocomplete.py : This is the plugin for auto completion.
- xtext_formatter.py : This is the plugin for code formatting.
- xtext_formatter.sublime-commands : This is file that makes formatter plugin appear in the command-pallete. Command-pallete shortcut key is  ctrl+shift+p , Command+shift+p
- xtext_validator.py : This is the plugin for code validation.
- xtext_validator.sublime-commands : his is file that makes validator plugin appear in the command-pallete. Command-pallete shortcut key is  ctrl+shift+p , Command+shift+p

##Formatter and Validator Plugin Usage Example

You can change file extension in mwe2 file.
![alt tag](https://cloud.githubusercontent.com/assets/6274392/11694346/a3d901f2-9e77-11e5-92b4-98fb41060d25.png)

###Autocompletion
![alt tag](https://cloud.githubusercontent.com/assets/6274392/11694489/5647f3f2-9e78-11e5-8796-3e7ab1149299.png)

###Requirement
It requires the xtext web integration server to be running.

./gradlew jettyRun


###To Do
Validator plugin highlights words where the errors are occured and prints the error messages as a comment.Improvement is needed for showing error messages. For example, showing error messages in tooltip boxes. There are tooltip API for sublime text 3 but not for sublime text 2. 





