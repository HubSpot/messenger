$ = jQuery

spinner_template = '''
    <div class="messenger-spinner">
        <span class="messenger-spinner-side messenger-spinner-side-left">
            <span class="messenger-spinner-fill"></span>
        </span>
        <span class="messenger-spinner-side messenger-spinner-side-right">
            <span class="messenger-spinner-fill"></span>
        </span>
    </div>
'''

class FlatMessage extends window.Messenger.Message
    template: (opts) ->
        $message = super

        $message.append $ spinner_template

        $message

window.Messenger.themes.flat =
    Message: FlatMessage
