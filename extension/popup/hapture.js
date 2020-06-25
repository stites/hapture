///* @flow */
//
//import {METHOD_CAPTURE_WITH_EXTRAS} from './common';
//import {get_options} from './options';
//
//

// TODO template it in html too?
var BUTTON_ID = 'button_id';
var COMMENT_ID = 'comment_id';
var TAGS_ID = 'tags_id';
// from common.js
var METHOD_CAPTURE_WITH_EXTRAS = 'captureWithExtras';

function default_options() {
    return {
        endpoint: "http://localhost:10046/capture",
        default_tags: ["web"],
        notification: true,
    };
}

function get_options(cb) {
    browser.storage.local.get(null, res => {
        res = {...default_options(), ...res};
        cb(res);
    });
}

//type State = {
//    comment: string,
//    tag_str: string,
//};

function save_state(state) { // Maybe State -> IO ()
    localStorage.setItem('state', JSON.stringify(state));
}

function load_state() { // () -> State
    return JSON.parse(localStorage.getItem('state') || null);
}

function getCommentEl() {
    return document.getElementById(COMMENT_ID);
}
function getComment() {
    const comment_str = getCommentEl().value;
    return comment_str === "" ? null : comment_str;
}

function getTagsEl(){ // () -> HTMLInputElement
    return document.getElementById(TAGS_ID);
}

function getTags(){ // () -> HTMLInputElement
    const tag_str = getTagsEl().value
    return tag_str === "" ? [] : tag_str.split(",").map(x => x.trim())
}


function getButton() { // : HTMLElement {
    return document.getElementById(BUTTON_ID);
}

function getState() { // () -> State
    return {
        'comment': getComment(),
        'tags': getTags(),
    };
}

function restoreState(state) { // Maybe State -> IO ()
    console.log(state);
    if (state === null) {
        // comment just relies on default
        get_options(opts => {
            getTagsEl().value = opts.default_tags.join(", ");
            console.log(opts);
        });
    } else {
        getCommentEl().value = state.comment;
        getTagsEl().value    = state.tags.join(", ");
    }
}

function submitComment () {
    // TODO focus
    const state = getState();

    var sending = browser.runtime.sendMessage(null,
        METHOD_CAPTURE_WITH_EXTRAS,
      { 'comment': state.comment,
        'tags': state.tags,
      })
    sending.then(() => {
       console.log("[popup] captured!");
    });
    sending.catch( () => {
       console.log("[popup] failed to capture!");
    });
    window.submitted = true;
    window.close();
}

// $FlowFixMe
function ctrlEnterSubmit(e) {
    if (e.ctrlKey && e.key === 'Enter') {
        submitComment();
    }
}


// https://stackoverflow.com/a/6003829/706389
function moveCaretToEnd(el) {
    if (typeof el.selectionStart == "number") {
        el.selectionStart = el.selectionEnd = el.value.length;
    } else if (typeof el.createTextRange != "undefined") {
        el.focus();
        var range = el.createTextRange();
        range.collapse(false);
        range.select();
    }
}

function setupPage () {
    const comment = getCommentEl();
    comment.focus();
    comment.addEventListener('keydown', ctrlEnterSubmit);

    const tags = getTagsEl();
    tags.addEventListener('keydown', ctrlEnterSubmit);
    tags.addEventListener('focus', () => moveCaretToEnd(tags)); // to put cursor to the end of tags when tabbed

    getButton().addEventListener('click', submitComment);

    window.submitted = false;

    const state = load_state();
    restoreState(state);
    save_state(null); // clean

    get_options(console.log)
}

document.addEventListener('DOMContentLoaded', setupPage);


window.addEventListener('unload', () => {
    if (!window.submitted) {
        save_state(getState());
    }
}, true);
