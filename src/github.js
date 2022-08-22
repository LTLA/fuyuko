const restUrl = "https://api.github.com";

async function recursiveListing(owner, name, path, ref, of_interest, token) {
    let target = restUrl + "/repos/" + owner + "/" + name + "/contents";
    if (path !== null) {
        target += "/" + encodeURIComponent(path);
    }
    target += "?ref=" + ref;

    let options = {};
    if (token !== null) {
        options.headers = {
            "Authorization": "token " + token
        };
    }

    let resp = await fetch(target, options);
    if (!resp.ok) {
        let place = (path == null ? "root" : "'" + path + "'");
        throw new Error("failed to inspect contents at " + place + " for '" + owner + "/" + name + "@" + ref + "' (HTTP " + String(resp.status) + ")");
    }

    let manifest = await resp.json();
    let collected = [];
    for (const x of manifest) {
        if (x.type == "dir") {
            collected.push(recursiveListing(owner, name, x.path, ref, of_interest, token));
        } else if (x.type == "file") {
            if (x.name == "CMakeLists.txt") {
                of_interest.push(x.path);
            }
        }
    }

    await Promise.all(collected);
    return;
}

/**
 * Find all `CMakeLists.txt` files in a GitHub repository.
 *
 * @param {string} owner - Name of the repository owner.
 * @param {string} name - Name of the repository.
 * @param {string} ref - Name of the commit, branch or tag of interest.
 * @param {Object} [options={}] - Optional parameters.
 * @param {?string} [options.token=null] - Access token.
 * It is often helpful to set this to avoid rate limits on the GitHub API.
 *
 * @return {Array} Array of paths to `CMakeLists.txt` files in the repository.
 */
export async function findCMakeListsOnGitHub(owner, name, ref, { token = null } = {}) {
    let of_interest = [];
    await recursiveListing(owner, name, null, ref, of_interest, token);
    return of_interest;
}
