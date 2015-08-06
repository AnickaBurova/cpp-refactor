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
        @modalPanel = atom.workspace.addModalPanel(item: @cppRefactorView.getElement(), visible: false)

        @cppRefactorClassInfoView = new CppRefactorClassInfoView(state.cppRefactorClassInfoViewState)
        @classInfoPanel = atom.workspace.addModalPanel(item: @cppRefactorClassInfoView.getElement(),visible: false)

        # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
        @subscriptions = new CompositeDisposable

        # Register command that toggles this view
        @subscriptions.add atom.commands.add 'atom-workspace', 'cpp-refactor:toggle': => @toggle()

        @subscriptions.add atom.commands.add 'atom-workspace', 'cpp-refactor:showclassinfo': => @classinfo()

    deactivate: ->
        @modalPanel.destroy()
        @subscriptions.dispose()
        @cppRefactorView.destroy()

    serialize: ->
        cppRefactorViewState: @cppRefactorView.serialize()
        cppRefactorClassInfoViewState: @cppRefactorView.serialize()

    toggle: ->
        console.log 'CppRefactor was toggled!'

        if @modalPanel.isVisible()
            @modalPanel.hide()
        else
            @modalPanel.show()

    classinfo: ->
        console.log 'CppRefactor class info is toggled!'

        if @classInfoPanel.isVisible()
            @classInfoPanel.hide()
        else
            @classInfoPanel.show()
