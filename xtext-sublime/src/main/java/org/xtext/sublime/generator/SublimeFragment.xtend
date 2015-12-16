package org.xtext.sublime.generator

import com.google.inject.Injector
import java.util.UUID
import org.eclipse.emf.mwe2.runtime.Mandatory
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtext.GrammarUtil
import org.eclipse.xtext.xtext.generator.AbstractXtextGeneratorFragment
import org.eclipse.xtext.xtext.generator.model.IXtextGeneratorFileSystemAccess
import org.eclipse.xtext.xtext.generator.model.XtextGeneratorFileSystemAccess

class SublimeFragment extends AbstractXtextGeneratorFragment {
	String absolutePath
	@Accessors(PROTECTED_GETTER, PUBLIC_SETTER)
	boolean ^override = false
	
	IXtextGeneratorFileSystemAccess outputLocation
	
	override generate() {
                val configFile = '''
                        # [PackageDev] target_format: plist, ext: tmLanguage
                        name: thomas «language.fileExtensions.head»
                        scopeName: source.«language.fileExtensions.head»
                        fileTypes: [«language.fileExtensions.head»]
                        uuid: «UUID.randomUUID»
                        
                        patterns:
                        «collectKeywordsAsRegex»
                        
                '''
                
                outputLocation.generateFile(
                        "newthomas.YAML-tmLanguage", configFile)
                
                
                val auto_complete_plugin='''
                import sublime, sublime_plugin, urllib2, urllib, json
                
                class GoogleAutocomplete(sublime_plugin.EventListener):
                    def on_query_completions(self, view, prefix, locations):
                        region = sublime.Region(0,view.size())
                        content = view.substr(sublime.Region(0,view.size()))
                        row = view.rowcol(locations[0])[0]
                        col = view.rowcol(locations[0])[1]
                        offset = view.text_point(row,col)
                        data = {'caretOffset': offset ,'fullText': content }
                        data = urllib.urlencode(data)
                        filename = str(view.file_name()).split("/")[-1]
                        url='http://localhost:8081/xtext-service/assist?resource='+filename
                        response = urllib2.urlopen(url,data)
                        response = json.loads(response.read())['entries']
                        output = []
                        for key, value in enumerate(response):
                            output.append(self.create_completion(value["proposal"],"xtext"))
                        #output = [x['proposal'] for x in response ]
                        #output = [ "hi" ,"hello ","hoho"]
                        print output
                        return output
                
                    def create_completion(self, var, location):
                        return (var + '\t' + location, var)
                '''
                outputLocation.generateFile(
                        "xtext_autocomplete.py", auto_complete_plugin)
                
                val formatter_plugin = '''
                import sublime, sublime_plugin,subprocess,urllib2,urllib,json
                
                class FormatterCommand(sublime_plugin.TextCommand):
                	def run(self, edit):
                		region = sublime.Region(0,self.view.size())
                		content = self.view.substr(sublime.Region(0,self.view.size()))
                		data = {'fullText': content }
                		data = urllib.urlencode(data)
                		filename = str(self.view.file_name()).split("/")[-1]
                		url='http://localhost:8081/xtext-service/format?resource='+filename
                		response = urllib2.urlopen(url,data)
                		text = json.loads(response.read())['formattedText']
                		self.view.replace(edit,region,text)
                '''
                outputLocation.generateFile(
                        "xtext_formatter.py", formatter_plugin)
                
                val formatter_commands= '''
                [
                    { "caption": "xtext_formatter", "command": "formatter" }
                ]
                '''
                outputLocation.generateFile(
                        "xtext_formatter.sublime-commands", formatter_commands)
                
                
                val validator_plugin='''
                import sublime, sublime_plugin, urllib2, urllib, json
                
                
                class ValidatorCommand(sublime_plugin.TextCommand):
                	def run(self, edit):
                		region = sublime.Region(0,self.view.size())
                		self.view.add_regions("text",[region],"")
                		content = self.view.substr(sublime.Region(0,self.view.size()))
                		data = {'fullText': content }
                		data = urllib.urlencode(data)
                		filename = str(self.view.file_name()).split("/")[-1]
                		url='http://localhost:8081/xtext-service/validate?resource='+filename
                		response = urllib2.urlopen(url,data)
                		self.view.insert(edit,self.view.size(),"\n")
                		response = json.loads(response.read())['issues']
                		for key, value in enumerate(response):
                			for index,title in enumerate(value):
                				self.view.insert(edit,self.view.size(),"# "+str(title)+" : "+str(value[title])+"\n")
                				if(title=="offset"):
                					print(value[title])
                					self.view.add_regions(str(key),[self.view.word(value[title])],"invalid")
                			self.view.insert(edit,self.view.size(),"\n")
                '''
                outputLocation.generateFile(
                        "xtext_validator.py", validator_plugin)
                
               
                val validator_commands= '''
                [
                    { "caption": "xtext_validator", "command": "validator" }
                ]
                '''
                outputLocation.generateFile(
                        "xtext_validator.sublime-commands", validator_commands)
        }
        protected def getOutputLocation() {
		return outputLocation
	}
	override initialize(Injector injector) {
		super.initialize(injector)
		this.outputLocation = new XtextGeneratorFileSystemAccess(absolutePath, override)
		injector.injectMembers(outputLocation)
	}
	protected def getAbsolutePath() {
		return absolutePath
	}
	
	@Mandatory
	def void setAbsolutePath(String absolutePath) {
		this.absolutePath = absolutePath
	}
        
        def collectKeywordsAsRegex() {
                val g = getGrammar
                val keywords = GrammarUtil.getAllKeywords(g)
                val test = '''
                	- name: keyword.other.«language.fileExtensions.head»
                	  match: '''
                
                test.concat(keywords.filter[ matches('\\b\\w+\\b') ].join(
                        '\\b(', //before
                        '|', //separator
                        ')\\b' //after
                ) [it].toString)
                
                
                
        }

	
}