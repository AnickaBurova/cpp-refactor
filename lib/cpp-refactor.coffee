{Range,Point} = require 'atom'
CppRefactorView = require './cpp-refactor-view'
CppRefactorClassInfoView = require './cpp-refactor-class-info-view'
{CompositeDisposable} = require 'atom'

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

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @cppRefactorView.destroy()

  serialize: ->
    cppRefactorViewState: @cppRefactorView.serialize()
    cppRefactorClassInfoViewState: @cppRefactorView.serialize()


  classPattern: /(class[\s]+)(\w+)/g
  fieldsPattern: /((?:\w+|::)*(?:<(?:\w*|,|\s*)*>)*)\s+(\w+)\s*(?:\[\s*(\w+)\s*\])*;/g

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

      pat = /// # find opening brace
          (\s*\/\/.*\n)| # starting one line comment, at this point, just skip it
          (\s*\/\*.*\*\/\s*)| # any block comment
          (})|
          ({)
      ///g

      level = 0
      found = false
      editor.backwardsScanInBufferRange pat, @get_range_begin2cursor(editor), (obj) ->
        # console.log "found '#{obj.matchText}' at #{obj.range}: #{obj.match[1]}, #{obj.match[2]}, #{obj.match[3]}, #{obj.match[4]}"
        if obj.match[3]?
          level++
        if obj.match[4]?
          if level > 0
            level--
          else
            found = true
            editor.setCursorBufferPosition [obj.range.end.row, obj.range.end.column - 1]
            obj.stop()

      if not found
        return

      endBrace = @find_brace_range(editor)
      console.log endBrace
      if endBrace?
        editor.setSelectedBufferRange [editor.getCursorBufferPosition(), endBrace]
  #
  # # cursor needs to be on opening brace {
  find_brace_range: (editor) ->
    if editor or editor = atom.workspace.getActiveTextEditor()
      if editor.hasMultipleCursors()
        console.log "There are multiple cursors."
        return undefined
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
          if level > 1
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
