// apply a border highlight to the card, based on the cherrypick action selected
// this is admittedly a gratuitous addition to the user experience, but it's a nice touch

// highlight only the card that corresponds to the provided index
function highlightCard(cardIndex) {
  const borderStyle = "border-primary";

  const cards = document.querySelectorAll(`.card[data-group='cherrypick[action]']`);
  cards.forEach((card) => card.classList.remove(borderStyle));

  cards[cardIndex].classList.add(borderStyle);
}

const radioButtons = document.querySelectorAll('input[name="cherrypick[action]"]');
radioButtons.forEach((radio) => {
  radio.addEventListener("change", function () {
    const action = this.value;
    const actionToIndexMap = {
      nano_grams_per_micro_litre: 0,
      nano_grams: 1,
      micro_litre: 2,
    };
    const cardIndex = actionToIndexMap[action];

    highlightCard(cardIndex);
  });
});
