import "isomorphic-fetch";
import * as gh from "../src/github.js";

test("GitHub scanner works as expected", async () => {
    let token = ("GITHUB_TOKEN" in process.env ? process.env.GITHUB_TOKEN : null);
    let deets = await gh.findCMakeListsOnGitHub("LTLA", "libscran", "master", { token: token });
    expect(deets.length).toBeGreaterThan(0);
    for (const p of deets) {
        expect(p).toMatch(/CMakeLists\.txt$/);
    }
})
