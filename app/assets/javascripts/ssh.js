function usernameFromPubKey(key) {
  var key = sanitizeKey(key)

  if(key.length > 0) {


  }

  return "";
}

function labelFromPubKey(key) {
  var key = sanitizeKey(key)

  if(key.length > 0) {
    key.split(' ')[2]
  }

  return "";
}

function sanitizeKey(key) {
  try {
    if (key.length > 32) {
    } else {
      throw "Key length too small";
    }
  } catch (err) {
    return "";
  }
}

module.exports = {
  usernameFromPubKey: usernameFromPubKey,
  labelFromPubKey: labelFromPubKey,
  sanitizeKey: sanitizeKey,
};
