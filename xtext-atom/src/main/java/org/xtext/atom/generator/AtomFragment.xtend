package org.xtext.atom.generator

import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.AbstractElement
import org.eclipse.xtext.Alternatives
import org.eclipse.xtext.CharacterRange
import org.eclipse.xtext.EOF
import org.eclipse.xtext.GrammarUtil
import org.eclipse.xtext.Group
import org.eclipse.xtext.Keyword
import org.eclipse.xtext.NegatedToken
import org.eclipse.xtext.ParserRule
import org.eclipse.xtext.RuleCall
import org.eclipse.xtext.TerminalRule
import org.eclipse.xtext.UntilToken
import org.eclipse.xtext.Wildcard
import org.eclipse.xtext.util.Strings
import org.eclipse.xtext.util.XtextSwitch
import org.eclipse.xtext.xtext.generator.parser.antlr.AntlrGrammarGenUtil

import com.google.inject.Injector
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtext.xtext.generator.AbstractXtextGeneratorFragment
import org.eclipse.xtext.xtext.generator.model.IXtextGeneratorFileSystemAccess
import org.eclipse.xtext.xtext.generator.model.XtextGeneratorFileSystemAccess
import org.eclipse.emf.mwe2.runtime.Mandatory

class WriteToExternalFolderFragment extends AbstractXtextGeneratorFragment {

	String absolutePath

	@Accessors(#[PROTECTED_GETTER, PUBLIC_SETTER])
	boolean ^override = false

	IXtextGeneratorFileSystemAccess outputLocation

	override generate() {
		val configFile = '''
		'scopeName': 'source.mydsl1'
		'name': 'xtext'
		'fileTypes': ['«language.fileExtensions.join(',')»']
		'patterns': [
		  {
		    # this line means "look for the xtextkeywords in the repository object below"
		    'include': '#xtextkeywords'
		  }
		  {
		    'include': 'source.js'
		  }
		]
		'repository':
		  'xtextkeywords':
		    'patterns': [
		      {
		        'match': «collectKeywordsAsRegex()»
		        'name': 'keyword.control'
		      }
		    ]

		'''

	  // content is produced here
	  // Currently processed Grammar is obtained via getGrammar
		outputLocation.generateFile('xtext.cson', configFile)
	}

	def collectKeywordsAsRegex() {
		val g = grammar
		val keywords = GrammarUtil.getAllKeywords(g)

		return keywords.filter[ matches('\\w+') ].join(
			'"', // before
			'|', // seperator
			'"' // after
		) [ it ] // how to represent the keyword as a regex (1:1 in this case)
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

}
