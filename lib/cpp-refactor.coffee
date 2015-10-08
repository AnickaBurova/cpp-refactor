{Range,Point} = require 'atom'
CppRefactorView = require './cpp-refactor-view'
CppRefactorClassInfoView = require './cpp-refactor-class-info-view'
{CompositeDisposable} = require 'atom'

path = require('path')

print = (x...) ->
  console.log x.reduce (a,b) ->
    a + if b? then ", " + b else ""

fs = require('fs')

for_each_line = (filepath, func) ->
  lineindex = 0
  for line in fs.readFileSync(filepath).toString().split '\n'
    func line, lineindex++

module.exports = CppRefactor =
  cppRefactorView: null
  modalPanel: null
  subscriptions: null

  cppRefactorClassInfoView: null
  classInfoPanel: null

  activate: (state) ->
    @cppRefactorView = new CppRefactorView(state.cppRefactorViewState)
    @modalPanel = atom.workspace.addModalPanel( item: @cppRefactorView.getElement(), visible: false)

    @cppRefactorClassInfoView = new CppRefactorClassInfoView(state.cppRefactorClassInfoViewState)
    @classInfoPanel = atom.workspace.addModalPanel(item: @cppRefactorClassInfoView.getElement(),visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # @subscriptions.add atom.commands.add 'atom-workspace', 'cpp-refactor:showclassinfo': => @classinfo()

    @subscriptions.add atom.commands.add 'atom-workspace', 'cpp-refactor:find-next-class': => @find_next_class()
    @subscriptions.add atom.commands.add 'atom-workspace', 'cpp-refactor:find-prev-class': => @find_previous_class()


    # @subscriptions.add atom.commands.add 'atom-workspace', 'cpp-refactor:add-getsize-fields': => @add_getsize_fields()

    @subscriptions.add atom.commands.add 'atom-workspace', 'cpp-refactor:select-brace-range': => @select_brace_range()
    # "atom-workspace": "cpp-refactor:select-brace-range"

    @subscriptions.add atom.commands.add 'atom-workspace', 'cpp-refactor:create-method-fields-size': => @create_method_fields_size()

    @subscriptions.add atom.commands.add 'atom-workspace', 'cpp-refactor:find-class': => @find_class()


  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @cppRefactorView.destroy()

  serialize: ->
    cppRefactorViewState: @cppRefactorView.serialize()
    cppRefactorClassInfoViewState: @cppRefactorView.serialize()


  classPattern: /(class[\s]+)(\w+)/g
  fieldsPattern: ///
          ((?:\w+|::)*(?:<(?:\w*|,|\s*)*>)*) # field type g1
          (\**)* # pointer type   g2
          (\&)* # reference type g3
          \s+ # space between type and name
          (\w+) # field name g4
          \s* # empty space if any
          (?:\[\s*(\w+)\s*\])* # field array g5
          ; # ending ;
          (?:\/\/.*$)* # any comment if any
          ///g

  create_method_fields_size: ->
    if editor = atom.workspace.getActiveTextEditor()
      if editor.hasMultipleCursors()
        console.log "There are multiple cursors."
        return
    fields = @get_all_fields(editor)
    if fields.length is 0
      return
    # find some place where to put the method, best to the end of the class

    endBrace = @find_brace_end(editor)

    editor.setCursorBufferPosition [endBrace.row, 0]

    isvec = /vector<.*>/
    is32 = /u*int32_t/
    is24 = /u*int24_t/
    is16 = /u*int16_t/
    is8 = /u*int8_t/

    constSize = 0
    dynamicSize = ""

    for field in fields
      console.log "#{field.name} : #{field.type}"
      switch
        when is32.test(field.type) then constSize  += 4
        when is24.test(field.type) then constSize  += 3
        when is16.test(field.type) then constSize  += 2
        when is8.test(field.type) then constSize  += 1
        when isvec.test(field.type) then dynamicSize += "+#{field.name}.size()+1"
        else console.log "not supported type of field: #{field.name}"

    tab = ""
    tab += "\t" for i in [1...endBrace.column]
    editor.insertText("#{tab}size_t GetFieldsSize()const\n#{tab}{\n\t#{tab}return #{constSize}#{dynamicSize};\n#{tab}}\n")



  get_all_fields: (editor) ->
    console.log "CppRefactor: get all fields"
    # find the class range first
    startBrace = @find_brace_start(editor)
    if not startBrace?
      return
    endBrace = @find_brace_end(editor)
    if not endBrace?
      return
    console.log "looking for fields in range #{startBrace} to #{endBrace}"
    fields = []
    editor.scanInBufferRange @fieldsPattern, new Range(startBrace,endBrace), (obj) ->
      console.log "field '#{obj.match[4]}' of type '#{obj.match[1]}'"
      fields.push (name : obj.match[4], type: obj.match[1])
    console.log "found all"
    fields


  get_range_begin2cursor: (editor) ->
    new Range(new Point(0,0), editor.getCursorBufferPosition())

  get_range_cursor2end: (editor) ->
    new Range(editor.getCursorBufferPosition(), new Point(editor.getLineCount(),0))
    # new Range(editor.getCursorBufferPosition(), new Point(editor.getCursorBufferPosition().row + 15,0))

  # find_current_class: (editor : undefined) ->
  #   if editor or editor = atom.workspace.getActiveTextEditor()
  #     if editor.hasMultipleCursors()
  #       console.log "There are multiple cursors."
  #       return
  #     editor.backwardsScanInBufferRange @classPattern, [[0,0],editor.getCursorBufferPosition()], (obj) ->
  #       editor.setCursorBufferPosition [obj.range.start.row, obj.range.start.column + obj.match[1].length]
  #       obj.stop()
  #
  #
  select_brace_range: ->
    console.log "CppRefactor: select brace range"
    if editor = atom.workspace.getActiveTextEditor()
      if editor.hasMultipleCursors()
        console.log "There are multiple cursors."
        return

      startBrace = @find_brace_start(editor)
      if not startBrace?
        return
      endBrace = @find_brace_end(editor)
      if not endBrace?
        return

      editor.setSelectedBufferRange [startBrace, endBrace]

  find_brace_start: (editor) ->
    pat = /// # find opening brace
        (\s*\/\/.*\n)| # starting one line comment, at this point, just skip it
        (\s*\/\*.*\*\/\s*)| # any block comment
        (})|
        ({)
    ///g

    level = 0
    startBrace = undefined
    editor.backwardsScanInBufferRange pat, @get_range_begin2cursor(editor), (obj) ->
      # console.log "found '#{obj.matchText}' at #{obj.range}: #{obj.match[1]}, #{obj.match[2]}, #{obj.match[3]}, #{obj.match[4]}"
      if obj.match[3]?
        level++
      if obj.match[4]?
        if level > 0
          level--
        else
          startBrace = obj.range.start
          obj.stop()
    startBrace
  #
  # cursor cannot to be on opening brace {
  find_brace_end: (editor) ->
    # console.log "start is :#{@get_range_cursor2end(editor).start}"
    # console.log @get_range_cursor2end(editor).end
    pat = ///
        (\s*\/\/.*\n)| # starting one line comment, at this point, just skip it
        (\s*\/\*.*\*\/)| # any block comment
        ({)|
        (};*)
        ///g
    level = 0
    endBrace = undefined
    editor.scanInBufferRange pat, @get_range_cursor2end(editor), (obj) ->
      # ignore comments and just focus on braces
      # on opening brace, increase level and continue finding
      # console.log "found '#{obj.matchText}' at #{obj.range}: #{obj.match[1]}, #{obj.match[2]}, #{obj.match[3]}, #{obj.match[4]}"
      if obj.match[3]?
        level++
        # console.log "opening new brace: #{level}"
      if obj.match[4]?
        if level > 0
          level--
          # console.log "closing prev brace: #{level}"
        else
          # console.log "found the closing brace"
          endBrace = obj.range.end # closing brace is the last match, so it will be the end of match range
          obj.stop()
    endBrace




  #
  #
  # # Cursor needs to be at the begining of the class for this to work fine.
  # get_class_range:(editor : undefined) ->
  #   if editor or editor = atom.workspace.getActiveTextEditor()
  #     if editor.hasMultipleCursors()
  #       console.log "There are multiple cursors."
  #       return
  #
  #
  #
  # add_getsize_fields: (editor : undefined) ->
  #   if editor or editor = atom.workspace.getActiveTextEditor()
  #     if editor.hasMultipleCursors()
  #       console.log "There are multiple cursors."
  #       return
  #     find_current_class(editor)
  #     # list all found fields

  find_previous_class: ->
    console.log "CppRefactor: finding previous class"
    if editor = atom.workspace.getActiveTextEditor()
      if editor.hasMultipleCursors()
        console.log "There are multiple cursors, cannot determine where to look for the class."
        return
      currentPosition = editor.getCursorBufferPosition()
      editor.backwardsScanInBufferRange @classPattern, [[0,0],editor.getCursorBufferPosition()], (obj) ->
        console.log "Class name is: " + obj.match[2]
        # console.log "Class decla is: " + obj.match[1].length
        if obj.range.start.column <= currentPosition <= obj.narge.start.column + obj.matchText.length
          # this is the same class as we have been befor, search for next one
          return
        editor.setCursorBufferPosition [obj.range.start.row, obj.range.start.column + obj.match[1].length]
        obj.stop()


  find_next_class: ->
    console.log "CppRefactor: finding next class"
    if editor = atom.workspace.getActiveTextEditor()
      if editor.hasMultipleCursors()
        console.log "There are multiple cursors, cannot determine where to look for the class."
        return
      currentPosition = editor.getCursorBufferPosition()
      editor.scanInBufferRange @classPattern, [editor.getCursorBufferPosition(), [editor.getLineCount(),0]], (obj) ->
        console.log "Class name is: " + obj.match[2]
        # console.log "Class decla is: " + obj.match[1].length
        if obj.range.start.column <= currentPosition <= obj.narge.start.column + obj.matchText.length
          # this is the same class as we have been befor, search for next one
          return
        editor.setCursorBufferPosition [obj.range.start.row, obj.range.start.column + obj.match[1].length]
        obj.stop()


  # add_def_ctr: ->
  #     console.log 'CppRefactor adding default ctr!'
  #     if editor = atom.workspace.getActiveTextEditor()
  #         if editor.hasMultipleCursors()
  #             console.log "There are multiple cursors, cannot determine where to look for the class."
  #             return

  classinfo: ->
    console.log 'CppRefactor class info is executed!'
    if editor = atom.workspace.getActiveTextEditor()
      if editor.hasMultipleCursors()
        console.log "There are multiple cursors, cannot determine where to look for the class."
        return
      range: null
      # findFields = () ->
      #     editor.
      state = () ->
        editor.scan @classPattern, (obj) ->
          console.log "Class name is: " + obj.match[1]
          console.log obj.range.start, obj.range.end
          obj.stop()

      state()

        # editor.scan fieldsPattern, (obj) ->
        # # editor.scan classPattern, (obj) ->
        #     # console.log "Class name is: " + obj.match[1]
        #     console.log obj.matchText
        # text = editor.getSelectedText()
        # if !text
        #     text = editor.getText()
        # console.log text
        # # start looking for class name, go up from current position
        #
        # editor.

            # selection = "replaced"
            # editor.insertText(selection)


    # if @classInfoPanel.isVisible()
    #     @classInfoPanel.hide()
    # else
    #     @classInfoPanel.show()
  search_include: ///
    \#include\s*
    (?:<|")
    ([\w\-\/\\\.]+) # the file to include
    (?:<|")
  ///g


  search_in_files: (search_dir, exclude_folder, go_up, search_pattern) ->

    search_file = (filepath) ->
      if not fs.existsSync(filepath)
        return []
      stat = fs.statSync(filepath)
      found = []
      if stat && not stat.isDirectory()
        for_each_line filepath, (line,linei) ->
          if m = search_pattern.exec(line)
            found.push [filepath,linei,m.index]
            print "found in",filepath,"at",linei,m.index
            print m
      if found.length > 0
        print found
      found

    found = []

    any_files = false
    fs.readdirSync(search_dir).forEach (file) =>
      if file == "daemon.h"
        print "Searching in daemon.h"
      filepath = path.join(search_dir,file)
      if filepath != exclude_folder
        try
          stat = fs.statSync(filepath)
          if stat
            if not stat.isDirectory()
              any_files = true
              if path.extname(file) == ".h"
                found = found.concat (search_file filepath)
                if f.length > 0
                  print f[0]
                  print found[0]
            else
              f = @search_in_files(filepath, "", false, search_pattern)
              found = found.concat f
        catch error


    if go_up && any_files && search_dir != "/"
      f = @search_in_files(path.dirname(search_dir), search_dir,true,search_pattern)
      found = found.concat f

    found





  find_class: ->
    if editor = atom.workspace.getActiveTextEditor()
      ident_to_find = editor.getWordUnderCursor()
      print ident_to_find
      editor.moveToEndOfWord()
      end = editor.getCursorBufferPosition()
      full_iden_scope = ///
        ((?:\w+\s*::\s*)*)#{ident_to_find}
      ///

      search_range = new Range(new Point(0,0),end)
      ident_scope = ""
      editor.backwardsScanInBufferRange full_iden_scope, search_range, (match) ->
        ident_scope = match.match[1]
        match.stop()
      print ident_scope

      #the problem is, it can be anything: class, identifier, function, ...
      ident_search = ///
        (?:
        (class|struct)\s+                       #class or struct
        (\w+\s*(?:\([\w\(\),\-\+\*\/]*\))*\s+)*  #any definition like some macro befor class name
        (#{ident_to_find})\s*(?::|\n|$)
        )
      ///

      found_any = false

      # first very simple go backwards in this file to find first match
      editor.backwardsScanInBufferRange ident_search, search_range, (m)->
        editor.setCursorBufferPosition(new Point(m.range.end.row, m.range.end.column - ident_to_find.length))
        found_any = true
        m.stop


      if not found_any
        curdirectory = path.dirname(editor.getPath())
        exclude_folder = "" # for now dont exclude any dir
        go_up = true # go up, but only if search a folder, if there are any files
        found = @search_in_files curdirectory, exclude_folder, go_up, ident_search
        print found

        for [f,i,j] in found
          print f,i,j
        if found.length > 0
          atom.workspace.open(found[0][0],{initialLine:found[0][1]})
