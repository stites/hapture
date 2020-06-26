//type Options = {
//    endpoint: string;
//    default_tags: string;
//    notification: boolean;
//}

// function default_options(): Options {
function default_options() {
    return {
        endpoint: "http://localhost:10046/capture",
        default_tags: [ "web" ],
        notification: true,
    };
}

// export function get_options(cb: (Options) => void) {
function get_options(cb) {
    browser.storage.local.get(null, res => {
        res = {...default_options(), ...res};
        cb(res);
    });
}

// function set_options(opts: Options, cb: () => void) {
function set_options(opts, cb) {
    console.log('Saving %s', JSON.stringify(opts));
    browser.storage.local.set(opts, cb);
}

function getOptions() {
    return new Promise((resolve) => browser.storage.local.get(null, res => {
      resolve({...default_options(), ...res});
    }))
}

function ensurePermissions(endpoint) {
    // shouldn't prompt if we already have the permission
    return browser.permissions.request({origins: [endpoint,],});
}

const ENDPOINT_ID       = 'endpoint_id';
const HAS_PERMISSION_ID = 'has_permission_id';
const NOTIFICATION_ID   = 'notification_id';
const DEFAULT_TAGS_ID   = 'default_tags_id';
// TODO specify capture path here?

const SAVE_ID = 'save_id';

function getEndpoint() { //: HTMLInputElement {
    // return ((document.getElementById(ENDPOINT_ID): any): HTMLInputElement);
    return document.getElementById(ENDPOINT_ID);
}

//function getDefaultTags(): HTMLInputElement {
//    return ((document.getElementById(DEFAULT_TAGS_ID): any): HTMLInputElement);
function getDefaultTags() {
    return document.getElementById(DEFAULT_TAGS_ID);
    //  TODO if empty, return null?
}

//function getEnableNotification(): HTMLInputElement {
//    return ((document.getElementById(NOTIFICATION_ID): any): HTMLInputElement);
function getEnableNotification() {
    return document.getElementById(NOTIFICATION_ID);
}

function getSaveButton() {// : HTMLInputElement {
    // return ((document.getElementById(SAVE_ID): any): HTMLInputElement);
    return document.getElementById(SAVE_ID);
}

function getHasPermission() {//: HTMLElement {
    return document.getElementById(HAS_PERMISSION_ID) // : any): HTMLElement);
}

// ugh. needs a better name..
function refreshPermissionValidation(endpoint) { // : string) {
  browser.permissions.contains({origins: [urlForPermissionsCheck(endpoint),]}, function(result) {
    const pstyle = getHasPermission().style;
    if (result) {
      // The extension has the permissions.
      console.debug('Got permisssions, nothing to worry about.');
      pstyle.display = 'none';
    } else {
      // The extension doesn't have the permissions.
      console.debug('Whoops, no permissions to access %s', endpoint);
      // TODO maybe just show button? but then it would need to be reactive..
      pstyle.display = 'block';
    }
  });
}

function restoreOptions() {
    getSaveButton().addEventListener('click', saveOptions);
    //get_options(opts => {
    //    const ep = opts.endpoint;
    //    getEndpoint().value = ep;
    //    getDefaultTags().value = opts.default_tags;
    //    getEnableNotification().checked = opts.notification;
    //    refreshPermissionValidation(ep);
    //});
    browser.storage.local.get(null, res => {
        res = {...default_options(), ...res};
        const ep = res.endpoint;
        getEndpoint().value = ep;
        getDefaultTags().value = res.default_tags.join(",");
        getEnableNotification().checked = res.notification;
        refreshPermissionValidation(ep);
    })
}

function saveOptions() {
  // TODO could also check for permissions and display message?
  const endpoint = getEndpoint().value;
  ensurePermissions(endpoint).finally(() => {
    refreshPermissionValidation(endpoint);
  });

  const opts = {
      endpoint: endpoint,
      default_tags: getDefaultTags().value === "" ? [] : getDefaultTags().value.split(",").map(x => x.trim()),
      notification: getEnableNotification().checked,
  };
  set_options(opts, () => { alert('Saved!'); });
  get_options(console.log);
}


document.addEventListener('DOMContentLoaded', restoreOptions);
