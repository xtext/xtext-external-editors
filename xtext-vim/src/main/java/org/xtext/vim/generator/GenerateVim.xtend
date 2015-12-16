package org.xtext.vim.generator

import com.google.inject.Injector
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.mwe2.runtime.Mandatory
import org.eclipse.xtend.lib.annotations.Accessors
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
import org.eclipse.xtext.xtext.generator.AbstractXtextGeneratorFragment
import org.eclipse.xtext.xtext.generator.model.IXtextGeneratorFileSystemAccess
import org.eclipse.xtext.xtext.generator.model.XtextGeneratorFileSystemAccess
import org.eclipse.xtext.xtext.generator.parser.antlr.AntlrGrammarGenUtil
import java.util.HashSet

class GenerateVim extends AbstractXtextGeneratorFragment {

  String absolutePath

  @Accessors(#[PROTECTED_GETTER, PUBLIC_SETTER])
  boolean ^override = false

  IXtextGeneratorFileSystemAccess outputLocation

  override generate() {
      // content is produced here
      // Currently processed Grammar is obtained via getGrammar

      val grammarName = GrammarUtil.getSimpleName(grammar)

      val resourceName = language.fileExtensions.get(0)

    val ftAccess = language.fileExtensions.map[ ext |
      '''au BufNewFile,BufRead *.«ext» set filetype=«grammarName»'''
    ].join("\n")
    outputLocation.generateFile('ftdetect/ftaccess.vim', ftAccess)

    val autoload = '''
    function! «grammarName»#Errorformat()
      return '%f: %l: %m'
    endfunction

    function! «grammarName»#GetValidatorExePath()
      " http://superuser.com/questions/119991/how-do-i-get-vim-home-directory
      let $VIMHOME=expand('<sfile>:p:h')
      return escape('./' . findfile('validator.rb', $VIMHOME.';'), ' \')
    endfunction

    function! «grammarName»#GetCompleterExePath()
      let $VIMHOME=expand('<sfile>:p:h')
      return escape('./' . findfile('completer.rb', $VIMHOME.';'), ' \')
    endfunction

    function! «grammarName»#GetFormatterExePath()
      let $VIMHOME=expand('<sfile>:p:h')
      return escape('./' . findfile('formatter.rb', $VIMHOME.';'), ' \')
    endfunction

    function! «grammarName»#GetCurrBuffContents()
      return join(getline(1, "$"), "\n")
    endfunction

    function! «grammarName»#Complete(findstart, base)
      if a:findstart
        return getline('.') =~# '\v^\s*$' ? -1 : 0
      else
        if empty(a:base)
          return []
        endif
        let l:results = []

        let l:file_contents = «grammarName»#GetCurrBuffContents()

        " line2byte(line('.')) gives the number of bytes in the buffer up until
        " this point. This is the place that the base needs to be inserted at
        let l:byte_index = line2byte(line('.')) - 1
        let l:completion_point = l:byte_index + len(a:base)
        let l:full_file_contents = strpart(l:file_contents, 0, l:byte_index).a:base.(strpart(l:file_contents, l:byte_index))

        let l:completions =
                    \ system(«grammarName»#GetCompleterExePath().' '.l:completion_point, l:full_file_contents)
        let l:cmd = substitute(a:base, '\v\S+$', '', '')
        for l:line in split(l:completions, '\n')
          let l:tokens = split(l:line, '\t')
          call add(l:results, {'word': l:cmd.l:tokens[0],
                              \'abbr': l:tokens[0],
                              \'menu': get(l:tokens, 1, '')})
        endfor
        return l:results
      endif
    endfunction
    '''

    outputLocation.generateFile("autoload/" + grammarName + ".vim", autoload)

    var compiler = '''
    if exists('current_compiler')
      finish
    endif

    " Essentially a polyfill for old versions of vim
    if exists(":CompilerSet") != 2
      command -nargs=* CompilerSet setlocal <args>
    endif


    let current_compiler = «grammarName»#GetValidatorExePath()

    execute 'CompilerSet makeprg=' . «grammarName»#GetValidatorExePath() . '\ %'
    execute 'CompilerSet errorformat='.escape(«grammarName»#Errorformat(), ' ')
    '''

    outputLocation.generateFile("compiler/" + grammarName + ".vim", compiler)

    var ftplugin = '''
    setlocal omnifunc=«grammarName»#Complete
    setlocal equalprg=./formatter.rb
    setlocal formatprg=./formatter.rb

    compiler «grammarName»
    '''

    outputLocation.generateFile("ftplugin/" + grammarName + ".vim", ftplugin)


    var keywords = GrammarUtil.getAllKeywords(grammar).join(" ")


    // TODO
    var extra = '''
    «/*collectTerminalsAsVimRules(grammarName)*/»
    '''

    var syntax = '''
    syntax keyword «grammarName»Keyword «keywords»

    «extra»

    highlight link «grammarName»Keyword Keyword

    '''


    outputLocation.generateFile("syntax/" + grammarName + ".vim", syntax)


    var syntastic = '''
    if exists('g:loaded_syntastic_«grammarName»_«grammarName»_checker')
      finish
    endif
    let g:loaded_syntastic_«grammarName»_«grammarName»_checker = 1

    let s:save_cpo = &cpo
    set cpo&vim


    function! SyntaxCheckers_«grammarName»_«grammarName»_GetLocList() dict
      " TODO switch the 'exe' here to 'exec'
      let l:makeprg = self.makeprgBuild({'exe': «grammarName»#GetValidatorExePath() })
      return SyntasticMake({'makeprg': l:makeprg,
                           \ 'errorformat': «grammarName»#Errorformat() })
    endfunction

    function! SyntaxCheckers_«grammarName»_«grammarName»_IsAvailable() dict
      " TODO make this actually check whether or not its available
      return 1
    endfunction


    call g:SyntasticRegistry.CreateAndRegisterChecker({'filetype': '«grammarName»',
                                                      \'name': '«grammarName»'})

    if exists('g:syntastic_extra_filetypes')
      call add(g:syntastic_extra_filetypes, '«grammarName»')
    else
      let g:syntastic_extra_filetypes = ['«grammarName»']
    endif

    let &cpo = s:save_cpo
    unlet s:save_cpo
    '''

    outputLocation.generateFile('''syntax_checkers/«grammarName»/«grammarName».vim''', syntastic)

    var completer = '''
      #!/usr/bin/ruby
      require 'JSON'
      require 'stringio'
      require 'uri'
      require 'net/http'


      file_contents = ''
      stdin_present = false
      if STDIN.tty?
        file_contents = IO.read ARGF.argv[0]
      else
        file_contents = $stdin.read
        stdin_present = true
      end

      file_offset = 0

      num_args = ARGF.argv.length
      arg_offset = stdin_present ? -1 : 0

      if ARGF.argv.length == 3 || (stdin_present && num_args == 2)
        target_line = ARGF.argv[1 + arg_offset].to_i
        target_offset = ARGF.argv[2 + arg_offset].to_i

        # $/ is a ruby builtin that gets you the current system's line separator
        file_contents.split($/).each.with_index do |line, num|
          if (num + 1) == target_line
            file_offset += target_offset
            break
          end
          file_offset += line.length + $/.length
        end
      elsif ARGF.argv.length == 2 || (stdin_present && num_args == 1)
        file_offset = ARGF.argv[1 + arg_offset].to_i
      else
        puts "Usage:\n ./complete.rb <filepath> (<char offset>)|(<line> <column>)"
        puts "OR\n cat <filepath> | ./complete.rb (<char offset>)|(<line> <column>)"
        exit
      end

      params_str = "?resource=text.«resourceName»"
      params_str += "&fullText=#{URI.escape(file_contents)}"
      params_str += "&caretOffset=#{file_offset}"

      uri = URI.parse "http://localhost:8080/xtext-service/assist#{params_str}"
      res = Net::HTTP.post_form uri, {}

      json = JSON.parse res.body

      s = StringIO.new
      json['entries'].each do |entry|
        s << entry['proposal']
        s << "\n"
      end
      puts s.string
    '''

    outputLocation.generateFile("completer.rb", completer)

    var validator = '''
      #!/usr/bin/ruby
      require 'JSON'
      require 'stringio'
      require 'uri'
      require 'net/http'

      file_contents = IO.read ARGF.argv[0]

      params_str = "?resource=text.«resourceName»&fullText=#{URI.escape(file_contents)}"
      uri = URI.parse "http://localhost:8080/xtext-service/validate#{params_str}"
      res = Net::HTTP.post_form uri, {}

      json = JSON.parse res.body


      s = StringIO.new
      json['issues'].each do |issue|
        s<< ARGF.argv[0]
        s << ': '
        s << issue['line']
        s << ': '
        s << issue['description']
        s << "\n"
      end
      puts s.string
    '''

    outputLocation.generateFile("validator.rb", validator)

    var formatter = '''
      #!/usr/bin/ruby
      require 'JSON'
      require 'stringio'
      require 'uri'
      require 'net/http'

      file_contents = $stdin.read

      params_str = "?resource=text.«resourceName»&fullText=#{URI.escape(file_contents)}"
      uri = URI.parse "http://localhost:8080/xtext-service/format#{params_str}"
      res = Net::HTTP.post_form uri, {}

      json = JSON.parse res.body

      puts json['formattedText']
    '''

    outputLocation.generateFile("formatter.rb", formatter)

  }


  def String collectTerminalsAsVimRules(String grammarName) {
    var terminals = GrammarUtil.allTerminalRules(grammar)
    var result = new StringBuilder()
    var mappingsNeeded = new HashSet()

    for (TerminalRule rule: terminals){
      val regex = "\"\\v" + TerminalRuleToRegEx.toRegEx(rule) + "\""

      if (rule.name.toLowerCase().contains("ID")){
        result.append('''syntax match «grammarName»Identifier «regex»''').append("\n")
        mappingsNeeded.add("identifier")
      } else if (rule.name.toLowerCase().contains("comment")){
        result.append('''syntax match «grammarName»Comment «regex»''').append("\n")
        mappingsNeeded.add("comment");
      } else if (rule.name.toLowerCase().contains("boolean")){
        result.append('''syntax match «grammarName»Boolean «regex»''').append("\n")
        mappingsNeeded.add("boolean");
      } else if (rule.name.toLowerCase().contains("constant")){
        result.append('''syntax match «grammarName»Constant «regex»''').append("\n")
        mappingsNeeded.add("constant");
      }

    }

    for (String mapping: mappingsNeeded){
      if (mapping.equals("identifier")){
        result.append('''highlight link «grammarName»Identifier Identifier''').append("\n")
      } else if (mapping.equals("comment")){
        result.append('''highlight link «grammarName»Comment Comment''').append("\n")
      } else if (mapping.equals("boolean")){
        result.append('''highlight link «grammarName»Boolean Boolean''').append("\n")
      } else if (mapping.equals("comment")){
        result.append('''highlight link «grammarName»Boolean Boolean''').append("\n")
      }
    }

    return result.toString()
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

// vim regex reference:
// http://vimregex.com/
// TODO
// need to correlate the XText types of terminal rules with vim's character classes
// then link each character class used to the master vim one
// eg
//    syntax keyword smKeyword input signal
//    highlight link smKeyword Keyword
// possible vim character classes are
/*
  Comment
  Constant
  Identifier
  Statement
  Operator
  PreProc
  Type
  Special
  Underlined
  Ignore
  Error
  Todo
  */

  // Oh and make sure that the regexes produced are all prefixed with verymagic
class TerminalRuleToRegEx extends XtextSwitch<String> {
  final StringBuilder result

  private new(){
    this.result = new StringBuilder()
  }

  def static String toRegEx(TerminalRule rule) {
    return new TerminalRuleToRegEx().print(rule)
  }

  def String print(TerminalRule rule) {
    doSwitch(rule.getAlternatives())
    return result.toString()
  }

  // see vim's help docs for details on what very magic is
  // basically very magic (\v) is as close as vim gets to perl regex
  // :help magic
  def static private String veryMagicEscape(String str){
    return str
      .replaceAll("\\n", "\\\\n") //replaces a newline with \n
      .replaceAll("\\r\\n", "\\\\r\\\\n") // replaces newline carriage return with \r\n
      .replaceAll(".", "\\.") // the only sane one here
      .replaceAll("\\{", "\\\\{") // replaces a left curly with backslash left curly
      .replaceAll("\\\\", "\\\\\\\\") // replaces single backslash with double backslash

  }


  override String caseAlternatives(Alternatives object) {
    result.append(Character.valueOf('(').charValue)
    var boolean first=true
    for (AbstractElement elem : object.getElements()) {
      if (!first) result.append(Character.valueOf('|').charValue)
      first=false
      doSwitch(elem)
    }
    result.append(Character.valueOf(')').charValue).append(Strings.emptyIfNull(object.getCardinality()))
    return ""
  }
  override String caseCharacterRange(CharacterRange object) {
    if (!Strings.isEmpty(object.getCardinality())) result.append(Character.valueOf('(').charValue)
    doSwitch(object.getLeft())
    result.append("..")
    doSwitch(object.getRight())
    if (!Strings.isEmpty(object.getCardinality())) {
      result.append(Character.valueOf(')').charValue)
      result.append(Strings.emptyIfNull(object.getCardinality()))
    }
    return ""
  }
  override String defaultCase(EObject object) {
    throw new IllegalArgumentException('''«object.eClass().getName()» is not a valid argument.''')
  }
  override String caseGroup(Group object) {
    if (!Strings.isEmpty(object.getCardinality())) result.append(Character.valueOf('(').charValue)
    var boolean first=true
    for (AbstractElement elem : object.getElements()) {
      if (!first) result.append(Character.valueOf('|').charValue)
      first=false
      doSwitch(elem)
    }
    if (!Strings.isEmpty(object.getCardinality())) result.append(Character.valueOf(')').charValue)
    result.append(Strings.emptyIfNull(object.getCardinality()))
    return ""
  }
  override String caseKeyword(Keyword object) {
    var String value = veryMagicEscape(object.value)
    result.append(value)
    result.append(Strings.emptyIfNull(object.getCardinality()))
    return ""
  }
  override String caseWildcard(Wildcard object) {
    result.append(Character.valueOf('.').charValue)
    result.append(Strings.emptyIfNull(object.getCardinality()))
    return ""
  }
  override String caseEOF(EOF object) {
    result.append("EOF")
    result.append(Strings.emptyIfNull(object.getCardinality()))
    return ""
  }
  override String caseTerminalRule(TerminalRule object) {
    result.append(AntlrGrammarGenUtil.getRuleName(object))
    return ""
  }
  override String caseParserRule(ParserRule object) {
    throw new IllegalStateException("Cannot call parser rules that are not terminal rules.")
  }
  override String caseRuleCall(RuleCall object) {
    doSwitch(object.getRule())
    result.append(Strings.emptyIfNull(object.getCardinality()))
    return ""
  }
  override String caseNegatedToken(NegatedToken object) {
    result.append("[^")
    doSwitch(object.getTerminal())
    result.append("]").append(Strings.emptyIfNull(object.getCardinality()))
    return ""
  }
  override String caseUntilToken(UntilToken object) {
    result.append(".\\{-}")
    doSwitch(object.getTerminal())
    return ""
  }
}
