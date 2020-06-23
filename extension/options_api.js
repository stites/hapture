//type Options = {
//    endpoint: string;
//    default_tags: string;
//    notification: boolean;
//}

function default_options() {
    return {
        endpoint: "http://localhost:10046/capture",
        default_tags: ["web"],
        notification: true,
    };
}

function get_options(cb){ //}: (Options) => void) {
    chrome.storage.local.get(null, res => {
        res = {...default_options(), ...res};
        cb(res);
    });
}

function set_options(opts, cb){//}: Options, cb: () => void) {
    console.log('Saving %s', JSON.stringify(opts));
    chrome.storage.local.set(opts, cb);
}

function getOptions() {
    return new Promise((resolve) => get_options(resolve))
}
