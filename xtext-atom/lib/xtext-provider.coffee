
module.exports =
  class XtextProvider
    provider =
  # This will work on JavaScript and CoffeeScript files, but not in js comments.
      selector: '.source.mydsl1, .source.coffee'
      disableForSelector: '.source.js .comment'

      # This will take priority over the default provider, which has a priority of 0.
      # `excludeLowerPriority` will suppress any providers with a lower priority
      # i.e. The default provider will be suppressed
      inclusionPriority: 1
      excludeLowerPriority: true

      # Required: Return a promise, an array of suggestions, or null.
      getSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix, activatedManually}) ->
        console.log(bufferPosition)
        new Promise (resolve) ->
          suggestion =
            text: ['someText','someShit','someothershitfsd'] # OR
            displayText: 'someText' # (optional)
            replacementPrefix: 'so' # (optional)
            type: 'function' # (optional)
            leftLabel: 'xtext' # (optional)
            leftLabelHTML: 'try' # (optional)
            rightLabel: 'fff' # (optional)
            rightLabelHTML: 'dfd' # (optional)
            className: 'asdf' # (optional)
            iconHTML: 'sdaf' # (optional)
            description: 'sadf' # (optional)
            descriptionMoreURL: 'sdf' # (optional)
          resolve([suggestion])

      # (optional): called _after_ the suggestion `replacementPrefix` is replaced
      # by the suggestion `text` in the buffer
      onDidInsertSuggestion: ({editor, triggerPosition, suggestion}) ->

      # (optional): called when your provider needs to be cleaned up. Unsubscribe
      # from things, kill any processes, etc.
      dispose: ->
