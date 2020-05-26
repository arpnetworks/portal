function usernameFromPubKey(key) {
  var label = labelFromPubKey(key);
  var username = label.split("@")[0];

  return username;
}

function labelFromPubKey(key) {
  var key = sanitizeKey(key);

  if (key.length > 0) {
    return key.split(" ")[2];
  }

  return "";
}

function sanitizeKey(key) {
  try {
    if (key.length < 32) {
      throw "Key length too small";
    }

    if (key.split(" ").length != 3) {
      throw "Key has bad format";
    }
  } catch (err) {
    return "";
  }

  return key;
}

module.exports = {
  usernameFromPubKey: usernameFromPubKey,
  labelFromPubKey: labelFromPubKey,
  sanitizeKey: sanitizeKey,
};
