const SshModule = require("../../app/assets/javascripts/ssh.js");

describe("labelFromPubKey()", () => {
  test("given empty key, should return empty string", () => {
    expect(SshModule.labelFromPubKey("")).toBe("");
  });
  test("given undefined key, should return empty string", () => {
    expect(SshModule.labelFromPubKey()).toBe("");
  });
  test("given proper key, should return label", () => {
    var label = "john@example.com";
    var key =
      "ssh-rsa AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA... " +
      label;

    expect(SshModule.labelFromPubKey(key)).toBe(label);
  });
});

describe("usernameFromPubKey()", () => {
  test("given empty key, should return empty string", () => {
    expect(SshModule.usernameFromPubKey("")).toBe("");
  });
  test("given undefined key, should return empty string", () => {
    expect(SshModule.usernameFromPubKey()).toBe("");
  });
  test("given proper key, should return username", () => {
    var username = "john";
    var label = username + "@example.com";
    var key =
      "ssh-rsa AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA... " +
      label;

    expect(SshModule.usernameFromPubKey(key)).toBe(username);
  });
});

describe("sanitizeKey()", () => {
  test("given undefined key, should return empty string", () => {
    expect(SshModule.sanitizeKey()).toBe("");
  });
  test("given empty key, should return empty string", () => {
    expect(SshModule.sanitizeKey("")).toBe("");
  });
  test("given malformed key, should return empty string", () => {
    var key =
      "ssh-rsa AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"; // No label
    expect(SshModule.sanitizeKey(key)).toBe("");
  });
  test("given good key, should return key", () => {
    var key =
      "ssh-rsa AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA foo@example.com";
    expect(SshModule.sanitizeKey(key)).toBe(key);
  });
});
