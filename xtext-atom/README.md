# atom-xtext-package package


A package with autocomplete and error message linter

![works](sample.gif)


## How to use it

- Clone XText
- Download Atom
- In one terminal, cd to your xtext directory and run `./gradlew jettyRun`
- Test that your example webserver is running by going to http://localhost:8080
- Run  `apm install atom-xtext-package` in the terminal
- Click on Packages -> atom-xtext-package -> toggle
- GL; HF


## Install Syntax Highlighting (optional)

- Copy AtomFragment.xtend into the directory right next to the .mwe2 file
- Add the following code
 ` fragment = WriteToExternalFolderFragment {
absolutePath = atomPath
}`
in language = StandardLanguage { }
- Run the wme2 file with the argument `-atomPath /Users/"Your Username"/.atom/packages/atom-xtext-package/grammars `
- Refresh the atom, you shall see syntax Highlighting
