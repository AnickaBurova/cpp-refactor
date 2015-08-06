module.exports =
class CppRefactorClassInfoView
    constructor: (serializedState) ->
        # Create root element
        @element = document.createElement('div')
        @element.classList.add('cpp-refactor')

        # Create message element
        message = document.createElement('div')
        message.textContent = "This is class info"
        message.classList.add('message')
        @element.appendChild(message)

    serialize: ->


    destroy: ->
        @element.remove()

    getElement: ->
        @element
