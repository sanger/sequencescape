"use strict";

import $ from "jquery";
import CodeMirror from "codemirror";

/**
 * Defines a custom CodeMirror mode called "barcode_reader".
 * This mode is used to highlight duplicate barcodes in the input.
 */
CodeMirror.defineMode("barcode_reader", function (_) {
  /**
   * Processes the input stream and determines the style for each token.
   *
   * @param {Object} stream - The CodeMirror stream object for reading input.
   * @param {Object} state - The state object that tracks barcodes.
   * @returns {string|null} - The style to apply to the token, or null if no style.
   */
  function tokenBase(stream, state) {
    let ch = stream.next(); // Read the next character
    if (/[\w-]/.test(ch)) {
      // Check if the character is alphanumeric or a hyphen
      stream.eatWhile(/[\w.-]/); // Continue reading alphanumeric characters or hyphens
      let readBarcode = stream.current(); // Get the current token
      let baseBarcode = readBarcode.replace(/[^\d]+$/, ""); // Remove trailing non-digit characters
      if (state.barcodes.indexOf(baseBarcode) >= 0) {
        // If the base barcode is a duplicate, return an error style
        return "strong error";
      } else {
        // Otherwise, add the base barcode to the state and return a tag style
        state.barcodes.push(baseBarcode);
        return "tag";
      }
    }
  }

  return {
    /**
     * Initializes the state for the mode.
     *
     * @returns {Object} - The initial state with an empty barcodes array.
     */
    startState: function () {
      return { barcodes: [] };
    },

    /**
     * Processes each token in the input stream.
     *
     * @param {Object} stream - The CodeMirror stream object for reading input.
     * @param {Object} state - The state object that tracks barcodes.
     * @returns {string|null} - The style to apply to the token, or null if no style.
     */
    token: function (stream, state) {
      if (stream.eatSpace()) return null; // Skip spaces
      let style = tokenBase(stream, state); // Process the token
      return style;
    },
  };
});

$(() => {
  // Select the source tubes input field
  const sourceTubesInput = $("#plates_from_tubes_source_tubes");

  // Initialize the CodeMirror editor with custom settings
  let editor = CodeMirror.fromTextArea(sourceTubesInput[0], {
    lineNumbers: true, // Enable line numbers
    mode: "barcode_reader", // Use the custom "barcode_reader" mode
    theme: "eclipse", // Set the editor theme
  });

  /**
   * Event listener for changes in the CodeMirror editor.
   * Updates the count of source tubes and highlights duplicates.
   */
  editor.on("change", function () {
    let value = editor.getValue(); // Get the current value of the editor
    if (value) {
      // Split the input into lines, trim whitespace, and filter out empty lines
      let lines = value
        .split("\n")
        .map((line) => line.trim())
        .filter((line) => line !== "");

      // Normalize lines by removing trailing non-digit characters
      let normalizedLines = lines.map((line) => line.replace(/[^\d]+$/, ""));

      // Find duplicate lines
      let duplicates = normalizedLines.filter((line, index) => normalizedLines.indexOf(line) !== index);

      // Show or hide the duplicate warning based on the presence of duplicates
      if (duplicates.length > 0) {
        $("#duplicate_warning").show();
        $("#submit_button").prop("disabled", true);
      } else {
        $("#duplicate_warning").hide();
        $("#submit_button").prop("disabled", false);
      }
    }
  });
});
