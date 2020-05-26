const SshModule = require("../../app/assets/javascripts/ssh.js");

describe("labelFromPubKey()", () => {
  test("given empty key, should return empty string", () => {
    expect(SshModule.labelFromPubKey("")).toBe("");
  });
});

describe("usernameFromPubKey()", () => {
  test("given empty key, should return empty string", () => {
    expect(SshModule.usernameFromPubKey("")).toBe("");
  });
});
