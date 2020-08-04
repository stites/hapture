const COMMAND_CAPTURE_SIMPLE = 'capture-simple';

const METHOD_CAPTURE_WITH_EXTRAS = 'captureWithExtras';
// function default_options(): Options {
function default_options() {
    return {
        endpoint: "http://localhost:10046/capture",
        default_tags: [ "web" ],
        notification: true,
    };
}

// export function showNotification(text: string, priority: number=0) {
function showNotification(text, priority) {
    if (priority === null) {
        priority = 0
    }
    browser.notifications.create({
        'type': "basic",
        'title': "hapture",
        'message': text,
        'priority': priority,
        'iconUrl': 'icons/hurricane-160.png',
    });
}

//// export function get_options(cb: (Options) => void) {
function get_options(cb) {
    browser.storage.local.get(null, res => {
        res = {...default_options(), ...res};
        cb(res);
    });
}

function handleCaptureSuccess(notify, res) {
  if (!res) {
    console.log("[background] success");
  } else {
    console.log("[background] success:", res);
    if (notify) {
        showNotification(`OK: captured to ${res.path}`);
    }
  }
}

function handleCaptureError(err){
  console.error("[background] ERROR:", err);
  showNotification(`ERROR: ${err}`, 1);
  // TODO crap, doesn't really seem to respect urgency...
}

// TODO FIXME ugh. need defensive error handling on the very top...
// function capture(comment: ?string = null, tag_str: ?string = null) {
function capture(comment, tags, subtree) {
    browser.tabs.query({currentWindow: true, active: true }, tabs => {
        const tab = tabs[0];
        if (!tab.url) {
            showNotification('ERROR: trying to capture null');
            return;
        } else {
            get_options(opts => {
                // console.log('action!');
                // ugh.. https://stackoverflow.com/a/19165930/706389
                browser.tabs.executeScript( {
                    code: "window.getSelection().toString();"
                }, selections => {
                    const selection = selections === null ||  selections[0] === "" ? null : selections[0];

                    postCapture({
                        url: tab.url,
                        title: tab.title,
                        selection: selection,
                        comment: comment,
                        tags: tags,
                        subtree: subtree,
                    }, handleCaptureSuccess.bind(this, opts.notification), handleCaptureError);
                });
            });
        }
    });
}

browser.commands.onCommand.addListener(function (command) {
    if (command === COMMAND_CAPTURE_SIMPLE) {
        capture(null, null, null);
    }
});

// browser.runtime.onMessage.addListener((message: any, sender: browser$MessageSender, sendResponse) => {  // eslint-disable-line no-unused-vars
browser.runtime.onMessage.addListener((message, sender, sendResponse) => {  // eslint-disable-line no-unused-vars
    if (message.method === METHOD_CAPTURE_WITH_EXTRAS) {
        capture(message.state.comment, message.state.tags, message.state.subtree);
    }
});

// TODO handle cannot access chrome:// url??

