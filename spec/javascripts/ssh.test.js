const SshModule = require("../../app/assets/javascripts/ssh.js");

describe("labelFromPubKey()", () => {
  test("given empty key, should return empty string", () => {
    expect(SshModule.labelFromPubKey("")).toBe("");
  });
});

describe("labelFromPubKey()", () => {
  test("given undefined key, should return empty string", () => {
    expect(SshModule.labelFromPubKey()).toBe("");
  });
});

describe("usernameFromPubKey()", () => {
  test("given empty key, should return empty string", () => {
    expect(SshModule.usernameFromPubKey("")).toBe("");
  });
});

describe("usernameFromPubKey()", () => {
  test("given undefined key, should return empty string", () => {
    expect(SshModule.usernameFromPubKey()).toBe("");
  });
});

describe("sanitizeKey()", () => {
  test("given undefined key, should return empty string", () => {
    expect(SshModule.sanitizeKey()).toBe("");
  });
  test("given empty key, should return empty string", () => {
    expect(SshModule.sanitizeKey("")).toBe("");
  });
});
