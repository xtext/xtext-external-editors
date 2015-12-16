module.exports =
  class XtextLinter
    provider =
      grammarScopes: ['*']
      scope: 'file'
      lintOnFly: true
      lint: (textEditor) ->
        filePath = textEditor.getPath()
        text = textEditor.getText()
        url = 'http://localhost:8080/xtext-service/validate?resource=text.mydsl1&fullText='+encodeURIComponent(text)
        #console.log(url)
        results = []
        $.when(
          $.ajax url,
            type: 'POST'
            dataType: 'html'
            error: (jqXHR, textStatus, errorThrown) ->
              #console.log "#{textStatus}"
            success: (data, textStatus, jqXHR) ->
              issue = JSON.parse(data).issues[0]
              #console.log(issue)
              if (issue and issue.length>0)
                res = {
                  type: issue.severity
                  text: issue.description,
                  range: [[issue.line-1,issue.column],[issue.line-1,issue.column+issue.length]],
                  filePath: textEditor.getPath()
                }
                results.push(res)
        ).then ->
          return results
