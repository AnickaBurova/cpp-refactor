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
    if editor = atom.workspace.getActiveTextEditor()
      if editor.hasMultipleCursors()
        console.log "There are multiple cursors."
        return
      pat = /// # find opening brace
          (\/\/.*\n)* # starting one line comment, at this point, just skip it
          (\/\*.*\*\/)* # any block comment
          ({)
      ///

      editor.backwardsScanInBufferRange pat, editor.getCursorBufferPosition(), (obj) ->
        if obj.match[3].length > 0
          editor.setCursorBufferPosition obj.range.end
          obj.stop()
      # endBrace = find_brace_range(editor)
      # if endBrace is not undefined
      #   editor.setSelectedBufferRange [editor.getCursorBufferPosition(), endBrace]
  #
  # # cursor needs to be on opening brace {
  # find_brace_range: (editor : undefined) ->
  #   if editor or editor = atom.workspace.getActiveTextEditor()
  #     if editor.hasMultipleCursors()
  #       console.log "There are multiple cursors."
  #       return undefined
  #     pat = ///
  #         (\/\/.*\n)* # starting one line comment, at this point, just skip it
  #         (\/\*.*\*\/)* # any block comment
  #         ({) # opening brace
  #         (}) # closing brace
  #         ///
  #     level = 0
  #     endBrace = undefined
  #     editor.scanInBufferRange pat, editor.getCursorBufferPosition(), (obj) ->
  #       # ignore comments and just focus on braces
  #       # on opening brace, increase level and continue finding
  #       if obj.match[3].length > 0
  #         level++
  #       if obj.match[4].length > 0
  #         if level > 0
  #           level--
  #         else
  #           endBrace = obj.range.end # closing brace is the last match, so it will be the end of match range
  #           obj.stop()
  #     return endBrace
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
