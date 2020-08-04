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
var SUBTREE_ID = 'subtree_id';
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
function ensure_string(s) {
    return s === "" ? null : s;
}
function element_string(el) {
    return ensure_string(el.value);
}
function element_by_id(id) {
    return document.getElementById(id);
}
function string_by_id(id) {
    return element_string(element_by_id(id));
}

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
    return element_string(getCommentEl());
}
function getSubtreeEl() {
    return document.getElementById(SUBTREE_ID);
}
function getSubtree() {
    return element_string(getSubtreeEl());
}
function getTagsEl(){ // () -> HTMLInputElement
    return document.getElementById(TAGS_ID);
}

function getTags(){ // () -> HTMLInputElement
    const tag_str = getTagsEl().value;
    return tag_str === "" ? [] : tag_str.split(",").map(x => x.trim());
}

function getButtonEl() { // : HTMLElement {
    return document.getElementById(BUTTON_ID);
}

function getState() { // () -> State
    return {
        'comment': getComment(),
        'tags': getTags(),
        'subtree': getSubtree(),
    };
}

function restoreState(state) { // Maybe State -> IO ()
    if (state === null) {
        // comment just relies on default
        get_options(opts => {getTagsEl().value = opts.default_tags.join(", ");});
    } else {
        getCommentEl().value = state.comment;
        getTagsEl().value    = state.tags.join(", ");
        getSubtreeEl().value = state.subtree;
    }
}

function submitComment () {
    // TODO focus
    browser.runtime.sendMessage({
        'method': METHOD_CAPTURE_WITH_EXTRAS,
        'state': getState(),
    }).then(() => {
       console.log("[popup] captured!");
    }, () => {
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

    const tagsEl = getTagsEl();
    tagsEl.addEventListener('keydown', ctrlEnterSubmit);
    tagsEl.addEventListener('focus', () => moveCaretToEnd(tagsEl)); // to put cursor to the end of tags when tabbed

    const subtreeEl = getSubtreeEl();
    subtreeEl.addEventListener('keydown', ctrlEnterSubmit);

    getButtonEl().addEventListener('click', submitComment);

    window.submitted = false;
    restoreState(load_state());
    save_state(null); // clean
}

document.addEventListener('DOMContentLoaded', setupPage);

window.addEventListener('unload', () => {
    if (!window.submitted) {
        save_state(getState());
    }
}, true);
