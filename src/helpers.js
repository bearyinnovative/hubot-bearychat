function decodeMention (text, userId, replaceName) {
  return text.replace(
    /(@)<=(.*?)=\>/g,
    function(_, mentionMark, mentionedUserId) {
      if (mentionedUserId === userId) { return replaceName; }
      return mentionedUserId;
  })
}

module.exports = {
  decodeMention
};
