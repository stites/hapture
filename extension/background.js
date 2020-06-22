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

// type Params = {
//     url: string,
//     title: ?string,
//     selection: ?string,
//     comment: ?string,
//     tag_str: ?string,
// }

function makeCaptureRequest(
    params, // : Params,
    options,
) {
    if (params.tags == null) {
        params.tags = options.default_tags;
    }

    const data = JSON.stringify(params);
    console.log(`[background] capturing ${data}`);

    var request = new XMLHttpRequest();
    const curl = options.endpoint;

    request.timeout = 10 * 1000; // TODO should it be configurable?
    request.open('POST', curl, true);
    request.onreadystatechange = () => {
        const XHR_DONE = 4;
        if (request.readyState != XHR_DONE) {
            return;
        }
        const status = request.status;
        const rtext = request.responseText;
        var had_error = false;
        var error_message = `status ${status}, response ${rtext}`;
        console.log(`[background] status: ${status}, response: ${rtext}`);
        if (status >= 200 && status < 400) { // success
            try {
                // TODO handle json parsing defensively here
                const response = JSON.parse(rtext);
                const path = response.path;
                console.log(`[background] success: ${rtext}`);
                if (options.notification) {
                    showNotification(`OK: captured to ${path}`);
                }
            } catch (err) {
                had_error = true;
                error_message = error_message.concat(String(err));
                console.error(err);
            }
        } else {
            had_error = true;
            if (status == 0) {
                error_message = error_message.concat(` ${curl} must be unavailable `);
            }
        }

        if (had_error) {
            console.error(`[background] ERROR: ${error_message}`);
            showNotification(`ERROR: ${error_message}`, 1);
            // TODO crap, doesn't really seem to respect urgency...
        }
    };
    request.onerror = () => {
        console.error(request);
    };

    request.setRequestHeader("Content-Type", "application/json;charset=UTF-8");
    request.send(data);
}


// TODO FIXME ugh. need defensive error handling on the very top...
// function capture(comment: ?string = null, tag_str: ?string = null) {
function capture(comment, tags) {
    browser.tabs.query({currentWindow: true, active: true }, tabs => {
        const tab = tabs[0];
        if (tab.url == null) {
            showNotification('ERROR: trying to capture null');
            return;
        }
        const url = tab.url;
        // const url: string = tab.url;
        const title = tab.title;
        // const title: ?string = tab.title;

        get_options(opts => {
            // console.log('action!');
            // ugh.. https://stackoverflow.com/a/19165930/706389
            browser.tabs.executeScript( {
                code: "window.getSelection().toString();"
            }, selections => {
                const selection = selections == null ? null : selections[0];
                //postOrgCapture(opts.endpoint, {
                //    url: url,
                //    title: title,
                //    selection: selection,
                //    comment: comment,
                //    tags: tags,
                //}, () => {
                //  console.log(`[background] status: ${status}, response: ${rtext}`);
                //  try {
                //    // TODO handle json parsing defensively here
                //    const response = JSON.parse(rtext);
                //    const path = response.path;
                //    console.log(`[background] success: ${rtext}`);
                //    if (options.notification) {
                //        showNotification(`OK: captured to ${path}`);
                //    }
                //  } catch (err) {
                //    had_error = true;
                //    error_message = error_message.concat(String(err));
                //    console.error(err);
                //  }
                //}, (res) => {
                //  status = res.status;
                //  rtext = res.rtext;
                //  console.log(`[background] status: ${status}, response: ${rtext}`);
                //  var error_message = `status ${status}, response ${rtext}`;
                //  if (status == 0) {
                //      error_message = error_message.concat(` ${opts.endpoint} must be unavailable `);
                //  }
                //  console.error(`[background] ERROR: ${error_message}`);
                //  showNotification(`ERROR: ${error_message}`, 1);
                //})
                makeCaptureRequest({
                    url: url,
                    title: title,
                    selection: selection,
                    comment: comment,
                    tags: tags,
                }, opts);
            });
        });
    });
}

console.log("postOrgCapture", postOrgCapture);
// browser.commands.onCommand.addListener(function (command) {
//     if (command === COMMAND_CAPTURE_SIMPLE) {
//         capture(null, null);
//     }
// });

// browser.runtime.onMessage.addListener((message: any, sender: browser$MessageSender, sendResponse) => {  // eslint-disable-line no-unused-vars
browser.runtime.onMessage.addListener((message, sender, sendResponse) => {  // eslint-disable-line no-unused-vars
    if (message.method === METHOD_CAPTURE_WITH_EXTRAS) {
        const comment = message.comment;
        const tags = message.tags;
        console.log("got", METHOD_CAPTURE_WITH_EXTRAS, "message");
        get_options(console.log)
        capture(comment, tags);
    }
});

// TODO handle cannot access chrome:// url??

console.log("loaded background.js");
