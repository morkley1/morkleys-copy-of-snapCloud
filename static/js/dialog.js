function dialog (title, body, onSuccess, onCancel, onOpen) {
    // I reuse CustomAlert's dialogs
    var dialogBox = onCancel
            ? document.querySelector('#customconfirm')
            : document.querySelector('#customalert'),
        bodyDiv = dialogBox.querySelector('.body');

    if (typeof body == 'string') {
        bodyDiv.innerHTML = body.replaceAll('\n', '<br>');
    } else {
        bodyDiv.innerHTML = '';
        bodyDiv.appendChild(body);
    }

    dialogBox.querySelector('.header').innerHTML = localizer.localize(title);
    dialogBox.querySelector('.button-done').innerHTML = localizer.localize('Ok');

    if (onCancel) {
        dialogBox.querySelector('.button-cancel').innerHTML = localizer.localize('Cancel');
    }

    document.querySelector('#customalert-overlay').style.display = 'block';
    dialogBox.style.display = 'block';

    function close () {
        dialogBox.style.display = null;
        document.querySelector('#customalert-overlay').style.display = null;
        document.querySelector('html').style.overflow = 'auto';
    };

    dialogBox.done = function () {
        close();
        if (onSuccess) { onSuccess.call(this); }
    };

    dialogBox.cancel = function () {
        close();
        if (onCancel) { onCancel.call(this); }
    };

    if (onOpen) {
        onOpen.call(dialogBox);
    }
};

window.prompt = function (title, onSuccess, onCancel) {
    var input = document.createElement('input'),
        dialogBox = onCancel
            ? document.querySelector('#customconfirm')
            : document.querySelector('#customalert');

    // Kind of a hack to have Enter trigger the onSuccess action and close the dialog
    input.addEventListener('keypress', function(event) {
        if (event.keyCode === 13) {
            dialogBox.style.display = null;
            document.querySelector('#customalert-overlay').style.display = null;
            document.querySelector('html').style.overflow = 'auto';
            onSuccess.call(this, input.value);
        }
    });

    dialog(
        title,
        input,
        function () { onSuccess.call(this, input.value); },
        onCancel
    );

    input.focus();
};

// CustomAlert helpers

function confirmTitle (title) {
    // there's a bug in customalert.js preventing us from
    // using a custom title unless we also specify text for
    // the ok and cancel buttons
    return {
        title: localizer.localize(title),
        done: localizer.localize('Ok'),
        cancel: localizer.localize('Cancel')
    };
};

function confirmAction(text, controller, selector, params) {
    confirm(
        text,
        ok => { if (ok) { run_selector(controller, selector, params); }}
    );
};

function confirmComponentAction(text, componentId, controller, selector, params) {
    confirm(
        text,
        ok => {
            if (ok) {
                window['update_' + componentId](
                    controller,
                    selector,
                    params
                );
            }
        }
    );
};

// Additions

document.onkeyup = function (event) {
    var alert_dialog = document.querySelector('#customalert'),
        confirm_dialog = document.querySelector('#customconfirm'),
        dialog;

    if (alert_dialog &&
            (alert_dialog.style.display == 'block')) {
        dialog = alert_dialog;
    } else if (confirm_dialog &&
            (confirm_dialog.style.display == 'block')) {
        dialog = confirm_dialog;
    }

    if (event.keyCode == 13) {
        // enter accepts
        dialog.querySelector('.button-done').click();
    } if (event.keyCode == 27) {
        // esc cancels
        // on inform dialogs, we don't have a cancel button
        var button = dialog.querySelector('.button-cancel') ||
                dialog.querySelector('.button-done');
        button.click();
    }
};
