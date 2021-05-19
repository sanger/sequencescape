function say(sentence) {
  const utterance = new SpeechSynthesisUtterance(sentence);
  window.speechSynthesis.speak(utterance);
}

export { say };
