CppRefactorView = require './cpp-refactor-view'
{CompositeDisposable} = require 'atom'

module.exports = CppRefactor =
  cppRefactorView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    @cppRefactorView = new CppRefactorView(state.cppRefactorViewState)
    @modalPanel = atom.workspace.addModalPanel(item: @cppRefactorView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'cpp-refactor:toggle': => @toggle()

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @cppRefactorView.destroy()

  serialize: ->
    cppRefactorViewState: @cppRefactorView.serialize()

  toggle: ->
    console.log 'CppRefactor was toggled!'

    if @modalPanel.isVisible()
      @modalPanel.hide()
    else
      @modalPanel.show()
