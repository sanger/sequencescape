// apply a border highlight to the card, based on the cherrypick strategy selected
// this is admittedly a gratuitous addition to the user experience, but it's a nice touch

// highlight only the card that corresponds to the provided index
function highlightCard(cardIndex) {
  const borderStyle = "border-primary";

  const cards = document.querySelectorAll(`.card[data-group='cherrypick_strategy']`);
  cards.forEach((card) => card.classList.remove(borderStyle));

  cards[cardIndex].classList.add(borderStyle);
}

const radioButtons = document.querySelectorAll('input[name="cherrypick[strategy]"]');
radioButtons.forEach((radio) => {
  radio.addEventListener("change", function () {
    const strategy = this.value;
    const strategyToIndexMap = {
      nano_grams_per_micro_litre: 0,
      nano_grams: 1,
      micro_litre: 2,
    };
    const cardIndex = strategyToIndexMap[strategy];

    highlightCard(cardIndex);
  });
});
